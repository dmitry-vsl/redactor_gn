define (require) ->
  Shape = require './shape'
  Group = require './group'
  Changeable = require './changeable'
  ShapeFactory = require './shapeFactory'
  History = require './history'
  Shapes = require '../collections/shapes'
  Vector = require '../vector'
  Constants = require '../constants'
  doPolygonsIntersect = require '../doPolygonsIntersect'
  loadBasicSvgs = require '../loadBasicSvgs'


  
# TODO panel for group
# TODO localize panels
# TODO esc/enter

  PAGE_ATTRS = [
    'backgroundImageFile','backgroundColor','backgroundPlacement','palette','size'
  ]

  class PageModel extends Backbone.Model
    _.extend @::, Changeable

    defaults:
      size: [1280, 720]
      backgroundImageFile: null
      backgroundPlacement: 'cover'
      backgroundColor: null
      backgroundGradient: null
      palette: []

    initialize: (attrs = {}, options={}) ->
      @presentationAttrs = options.presentationAttrs

      @playerMode = options.playerMode
      @previewMode = options.previewMode
      @collection = options.collection

      @history = new History
      @history.on 'all', (event) =>
        @trigger "history:#{event}"

      @shapes = new Shapes [], page: @
      @shapes.on 'add remove reset change:selected smartReset', =>
        selectedShape = undefined
        for shape in @shapes.models
          if shape.get 'selected'
            selectedShape = shape
        @set {selectedShape}

      if @playerMode or @previewMode
        @loadContent()

      if @playerMode
        @loadLinks()

      if @collection?
        @loadState attrs.content

    # TODO refactor
    getObjectId: ->
      if @presentationAttrs?
        'presentation-' + @presentationAttrs.id
      else if @collection?
        'presentation-' + @collection.presentationId
      else
        'page-'   + @id

    deselectAll: ->
      @deselectGroup()
      @shapes.each (s) ->
        s.set 'selected', false

    createShape: (attrs, options) ->
      shape = new ShapeFactory attrs, parse: true
      shape.set 'id', @shapes.getNextId()

    addShape: (shape, options) ->
      @shapes.add shape, options
      shape.select()

    createShapeAndSaveState: (attrs) ->
      shape = @createShape attrs
      @setToCenter shape
      @addShape shape

      if attrs.type is 'text'
        shape.trigger 'updateModelHeight'
        @setToCenter shape

      @saveState()

    duplicateShape: (shape) ->
      attrs = shape.serialize()
      @createShapeAndSaveState attrs

    multiselect: ({left, top, width, height}) ->
      selectedShapes = []

      selectionRect = for [a,b] in [
        [0,0]
        [1,0]
        [1,1]
        [0,1]
      ]
        x: left + a*width
        y: top + b*height

      @shapes.each (s) ->
        shapeRect = s.getAllCornersPosition().map (c) ->
          x: c[0]
          y: c[1]
        if doPolygonsIntersect selectionRect, shapeRect
          selectedShapes.push s

      switch selectedShapes.length
        when 0 then @deselectAll()
        when 1 then selectedShapes[0].select()
        else
          @deselectAll()
          @group = new Group {}, shapes: selectedShapes, page: @
          @group.set 'selected', true
          @trigger 'groupSelected'

    deselectGroup: ->
      delete @group
      @trigger 'groupDeselected'

    removeSelectedShape: ->
      @getSelectedShape().remove()

    getSelectedShape: ->
      @shapes.find (s) -> s.get 'selected'

    saveState: ->
      @history.saveState @serialize()

    undoOrRedo: (action) ->
      @finishChanges()
      state = @history.undoOrRedo action
      shapes = for shape in state.shapes
        Shape::parse shape
      @shapes.smartReset shapes
      @set state.pageAttrs

    hasUnsavedChanges: ->
      @history.hasUnsavedChanges()

    save: ->
      @history.setPersisted()
      #super

    getFilePaths: ->
      paths = _.flatten @shapes.map (s) -> s.getFilePaths()
      if @get('backgroundImageFile')?
        paths.push @get('backgroundImageFile').path
      paths

    getVideos: ->
      @shapes.where type: 'video' 

    selectNextShape: ->
      if @shapes.size() is 0
        return
      selectedShape = @getSelectedShape()
      if selectedShape?
        index = (@shapes.indexOf(selectedShape)- 1 + @shapes.size()) % 
          @shapes.size()
      else
        index = @shapes.size() - 1
      @shapes.at(index).select()

    init: ->
      @loadState()

    duplicate: ->
      _.pick @toJSON(), 'content', 'filePaths'

    interactiveLinkSelect: (options) ->
      @trigger 'interactiveLinkSelect', options

    loadState: ->
      @loadContent()
      @loadLinks()
      @saveState()
      @history.setPersisted()

    loadLinks: ->
      return 

    loadContent: ->
      content = @get 'content'
      if content?
        shapes = content.shapes
        @theme = content.theme
        @shapes.reset shapes, parse: true
        @set @parsePageAttrs content.pageAttrs
      else
        # TODO refactor this condition
        unless @collection? or @presentationAttrs?
          # set default theme
          @theme = JSON.parse JSON.stringify Constants.DEFAULT_THEME

    getRedactor: ->
      @collection?.redactor ? @redactor

    focusOnShape: (@focusedShape) ->

    removeFocusOnShape: ->
      @focusedShape = undefined

    preloadImages: ->
      srcs = []
      for file in @get 'files'
        src = 
          file?.image?.original ?
          file.original
        srcs.push src if src?
      defs = srcs.map (src) ->
        imageLoadDef = $.Deferred()
        img = new window.Image
        img.src = src
        img.onload = -> imageLoadDef.resolve()
        imageLoadDef
      $.when $.when(defs...), loadBasicSvgs()

    getPageCenter: ->
      Vector.multiply @get('size'), 0.5

    setToCenter: (shape) ->
      shape.set 'position', 
        Vector.subtract @getPageCenter(),
          Vector.multiply shape.get('size'), 0.5

    uploadFile: (file,{type}) ->
      original = window.URL.createObjectURL(file)
      def = $.Deferred()
      img = new Image
      img.src = original
      img.onload = -> 
        def.resolve {original, width: img.width, height: img.height}
      def

    uploadBackground: (file) ->
      @uploadFile(file,type:'image').then (file) =>
        @set 'backgroundImageFile', file

    setGoogleBackground: ->
      $.Deferred().resolve()

    # TODO refactor
    getTheme: ->
      if @playerMode or @previewMode
        @theme ? @presentationAttrs?.content?.theme ? Constants.DEFAULT_THEME
      else
        @getRedactor().getTheme()

    rename: (newName) ->
      sameNamePage = @collection.find (page) =>
        (page.get('name') is newName) and (page isnt @)
      if sameNamePage?
        false
      else
        @set 'name', newName
        @save()

    parse: (response) ->
      response.data?.page ? response

    
    serialize: ->
      shapes: @shapes.serialize()
      pageAttrs: @cloneState()

    cloneState: ->
      JSON.parse JSON.stringify @pick PAGE_ATTRS...

    pageAttrsToJSON: ->
      result = @cloneState()
      result.backgroundImageFile = result.backgroundImageFile?.path
      result

    parsePageAttrs: (attrs) ->
      if attrs.backgroundImageFile?
        attrs.backgroundImageFile = _.findWhere @get('files'), 
          path: attrs.backgroundImageFile
      attrs

    toJSON: ->
      data = super
      data.content = 
        shapes: @shapes.toJSON()
        theme: @theme
        pageAttrs: @pageAttrsToJSON()
      data.filePaths = @getFilePaths()
      data.theme = @theme
      data.interactiveLinks = 
        for shape in @shapes.models when shape.get('link')?
          shape.get('link')
      data
