define (require) ->
  CompositeView = require 'base/compositeView'
  KeyHandler = require './keyHandler'
  ShapeView = require './shape'
  GridView = require './grid'
  ColorPicker = require './colorPicker'
  PageBackgroundView = require './pageBackgroundView'
  GroupView = require './groupShape'
  Vector = require '../vector'
  TouchToMouse = require '../touchToMouse'
  Theme = require '../theme'
  Constants = require '../constants'
  Utils = require 'utils/utils'


  
  class PageView extends CompositeView
    className: 'slide-block js-slide-block'

    itemView: ShapeView

    itemViewOptions: ->
      page: @

    template: 'redactor.page'

    serializeData: ->

    events:
      'mousedown .js-canvas' : 'handleMouseDown'
      'click @ui.backgroundColorBtn' : 'showBackgroundColorSelect'
      'click @ui.backgroundImageBtn' : 'showBackgroundImageSelect'

    readonlyEvents: {}

    itemViewContainer: '.js-shapesContainer'

    modelEvents:
      'groupSelected' : 'showGroupSelection'
      'groupDeselected' : 'removeGroupSelection'
      'change:backgroundColor' : 'updateBackgroundColor'
      'change:backgroundImageFile' : 'updateBackgroundImage'

    collectionEvents: 
      'setSort' : 'setSort'
      'forceRemoveView' : 'removeItemView'
      'forceRenderView' : 'addChildView'

    ui:
      stuffContainer: '.js-stuffContainer'
      shapesContainer: '.js-shapesContainer'
      canvas: '.js-canvas'
      wrapper: '.js-wrapper'
      backgroundColorBtn: '.js-backgroundColorBtn'
      backgroundImageBtn: '.js-backgroundImageBtn'
      backgroundImageBlock: '.js-backgroundImageBlock'

    initialize: ({
      @playerMode
      @selectLinkSourceMode
      @previewMode
      @controller
      @backgroundElement
    }) ->
      @zoom = 1
      @collection = @model.shapes
      if @selectLinkSourceMode
        @playerMode = true
      if @playerMode
        @events = @readonlyEvents
      if @previewMode
        @events = {}
      @readonly = @previewMode or @playerMode

      unless @readonly
        @keyHandler = new KeyHandler

    setZoom: (@zoom) ->
      @ui.canvas.css Utils.createVendorCss 'transform', "scale(#{@zoom},#{@zoom})"
      unless @readonly
        @trigger 'change:zoom'

    onRender: ->
      @backgroundElement ?= @$el
      @backgroundElement.addClass Theme.getPageClassName @model.getObjectId()
      Theme.applyTheme theme: @model.getTheme(), objectId: @model.getObjectId()
      @updateBackground()
      if @readonly
        @ui.canvas.css 
          overflow: 'hidden'
          position: 'relative'
      unless @readonly
        @$el.on 'mousedown', (e) =>
          if e.target is @el
            unless @model.focusedShape?
              @controller.showShapePanel()
              @model.deselectAll()
              @model.finishChanges()
            e.preventDefault()
        @showGrid()
        @keyHandler.subscribeTab (e) =>
          @model.selectNextShape()
          e.preventDefault()
    
    updateBackground: ->
      @updateBackgroundColor()
      @updateBackgroundImage()

    updateBackgroundColor: ->
      bgColor = @model.get('backgroundColor')
      if bgColor?
        @backgroundElement.css 'background-color', @model.get('backgroundColor')
      else
        @backgroundElement[0].style.removeProperty 'background-color'

    updateBackgroundImage: ->
      file = @model.get('backgroundImageFile')
      url = file?.original
      @ui.canvas.css 
        backgroundImage: if url? then "url('#{url}')" else "none"
        backgroundSize: 'cover'

    onDomRefresh: ->
      unless @readonly
        @ui.wrapper.addClass 'gn-redactor-canvas-wrapper'
        $(window).on 'resize.redactor', => @positionCanvas()
        @positionCanvas()
      @ui.wrapper.css Vector.toCssSize Vector.multiply(@model.get('size'), @zoom)
      @ui.canvas.css  Vector.toCssSize @model.get('size')
      if @playerMode
        @ui.wrapper.css 'margin', 'auto'

    positionCanvas: ->
      workspaceSize = [@$el.width(),@$el.height()].map (x)->
        x - 2*Constants.CANVAS_PADDING
      zoom = _.min _.zip(@model.get('size'), workspaceSize).map ([s,w]) ->
        if w > s
          1
        else
          w/s
      @setZoom zoom

    showGrid: ->
      @gridView = new GridView Vector.toCssSize @model.get('size')
      @ui.canvas.prepend @gridView.$el
      @gridView.setColor '#000000'

    handleMouseDown: (event) ->
      unless @model.focusedShape?
        @controller.showShapePanel()
        @model.finishChanges()
        @startSelection {event}
      event.preventDefault()

    startSelection: ({event}) ->
      @onMouseEvent 'mousemove.selection', @processSelection
      @onMouseEvent 'mouseup.selection', @stopSelection
      @selectionStartPoint = [event.offsetX, event.offsetY]
      @selectionStartOffset = [event.pageX, event.pageY]
      @selectionEndOffset = @selectionStartOffset
      @drawSelectionRect()
      @updateSelectionRect()
      @stopVideos()

    processSelection: (event) =>
      @selectionEndOffset = [event.pageX, event.pageY]
      @updateSelectionRect()

    stopSelection: =>
      @offMouseEvent 'mousemove.selection'
      @offMouseEvent 'mouseup.selection'
      @selectionRect.remove()
      @model.multiselect @getSelectionCoords()

    stopVideos: ->
      for video in @model.getVideos()
        @children.findByModel(video).showPreview()
    
    showGroupSelection: ->
      @groupView = new GroupView model: @model.group, page: @
      @groupView.render()
      @ui.shapesContainer.append @groupView.$el

    removeGroupSelection: ->
      if @groupView?
        @groupView.$el.remove()
        @groupView.close()
        delete @groupView

    drawSelectionRect: ->
      @selectionRect = $('<div></div>').addClass 'gn-redactor-selection'
      @ui.stuffContainer.append @selectionRect

    getSelectionCoords: ->
      [width,height] = Vector
      .multiply Vector.subtract(@selectionEndOffset,@selectionStartOffset),
        1/@zoom
      left =  
        if width > 0 
          @selectionStartPoint[0]
        else
          @selectionStartPoint[0] + width
      top = 
        if height > 0  
          @selectionStartPoint[1]
        else 
          @selectionStartPoint[1] + height
      bottom = top + Math.abs height
      right = left + Math.abs width
      {top, left, bottom, right, width:Math.abs(width), height: Math.abs(height)}

    updateSelectionRect: ->
      coords = @getSelectionCoords()
      for k,v of coords
        coords[k] = v*@zoom
      {left, top, width, height} = coords
      @selectionRect.width(width).height(height).css {left,top}

    scaleToFitContainer: ->
      parent = @$el.parent()
      cWidth = parent.width()
      cHeight = parent.height()
      scaleX = cWidth / @model.get('size')[0]
      scaleY = cHeight / @model.get('size')[1]
      scale = Math.min scaleX, scaleY
      @$el.css 'position', 'absolute'
      @$el.css Utils.createVendorCss 'transform', "scale(#{scale},#{scale})"
      @$el.css Utils.createVendorCss 'transform-origin', '0% 0%'

    onMouseEvent: (event, handler) ->
      TouchToMouse.on $(document), event, handler

    offMouseEvent: (event) ->
      TouchToMouse.off $(document), event

    showBackgroundColorSelect: (e) ->
      if @backgroundColorPicker?
        return
      btn = $(e.currentTarget)
      btn.addClass 'active'

      closePicker = =>
        btn.removeClass 'active'
        @backgroundColorPicker.close()
        delete @backgroundColorPicker

      @backgroundColorPicker = new ColorPicker
        currentColor: @model.get('backgroundColor')
        onColorChange: (backgroundColor) => @model.set {backgroundColor}
        onApply: => @model.finishChanges()
        onCancel: => 
          @model.rollbackChanges()
          closePicker()
      btn.append @backgroundColorPicker.render().$el

      @model.startChanges onFinishChanges: =>
        @model.commitChanges()
        closePicker()

    showBackgroundImageSelect: (e) ->
      if @pageBackgroundView?
        return
      btn = $(e.currentTarget)
      btn.addClass 'active'
      closeView = =>
        btn.removeClass 'active'
        @pageBackgroundView.close()
        delete @pageBackgroundView
      @pageBackgroundView = new PageBackgroundView(
        {@model,@controller,closeView}).render()
      @ui.backgroundImageBlock.append @pageBackgroundView.$el
      @model.startChanges onFinishChanges: =>
        @controller.showShapePanel()
        switch @pageBackgroundView.selectedImageType 
          when 'google'
            closeView()
            @model.rollbackChanges()
          else
            closeView()
            @model.commitChanges()

    onClose: ->
      $(window).off 'resize.redactor'
      @keyHandler?.close()
