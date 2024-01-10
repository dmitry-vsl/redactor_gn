define (require) ->
  Backbone = require 'backbone'
  Vector = require '../vector'
  Constants = require '../constants'
  Changeable = require './changeable'
  
  FILE_ATTRS = ['file', 'previewFile']
  PERSISTENT_ATTRS = [
    # common
    'type'
    'id'
    'size'
    'position'
    'rotate'
    'hasBorder'
    'borderWidth'
    'borderColor'
    'borderStyle'
    'opacity'

    #image
    'cropSize'
    'cropPosition'
    'originalSize'

    # video
    'youtubeId'
    'fullscreen'
    'autoplay'
    'startSeconds'
    'endSeconds'
    'videoType'

    # text
    'text'
    'scale'
    'fontSize'

    # shape
    'fillColor'
    'shapeCategory'
    'shapeType'
    'radius'
  ].concat FILE_ATTRS
  TRANSIENT_ATTRS = ['link']

  class Shape extends Backbone.Model
    # include mixin
    _.extend @::, Changeable

    defaults: 
      rotate: 0
      borderColor: null
      borderWidth: 0
      borderStyle: 'solid'
      opacity: 1
      selected: false
      file: null
      hasBorder: false

    initialize: ->
      @on 'change:selected', =>
        unless @get 'selected'
          # selection out
          @finishChanges()

    getPage: ->
      @collection.page

    select: ->
      unless @get 'selected'
        @getPage().deselectAll()
        @set 'selected', true

    remove: ->
      @finishChanges()
      page = @getPage() 
      @collection.remove @
      page.saveState()

    maximize: ->
      scaleX = @getPage().get('size')[0] / @get('size')[0]
      scaleY = @getPage().get('size')[1] / @get('size')[1]
      scale = Math.min scaleX, scaleY
      @set 'size', Vector.multiply @get('size'), scale
      @getPage().setToCenter @
      @saveState()

    pushTo: (direction) ->
      @collection.pushTo direction, @

    scale: ({mouseMoveVector, zoomDirection}) ->
      diagVector = Vector.plainProduct @originalSize, zoomDirection.map (i) ->
        if i is 0 then -1 else 1

      diagVector = Vector.rotate diagVector, @originalRotate

      moveDistance = Vector.scalarProduct Vector.normalize(diagVector), mouseMoveVector
      scale = moveDistance/Vector.norm(diagVector) + 1

      @doScale {scale, zoomDirection}

    getRedactor: ->
      @getPage().getRedactor()

    startChangesIfNotFocused: ->
      unless @isFocused()
        @startChanges.apply @, arguments

    commitChangesIfNotFocused: ->
      unless @isFocused()
        @commitChanges.apply @, arguments

    isFocused: ->
      @getPage().focusedShape is @

    focusOnShape: ->
      @getPage().focusOnShape @

    removeFocusOnShape: ->
      @getPage().removeFocusOnShape()

    doScale: ({scale, zoomDirection}) ->
      @set 'size', Vector.multiply @originalSize, scale


      zoomDirection = zoomDirection.map (i) -> i - 1

      move = Vector.multiply(
        Vector.rotate(
          Vector.plainProduct(@originalSize,zoomDirection),@originalRotate
        ),
        scale-1
      )

      @set 'position', Vector.add @originalPosition, move

    saveOriginalPosition: ->
      @originalSize = @get('size')
      @originalPosition = @get('position')
      @originalRotate = @get 'rotate'

    move: (diff) ->
      newPosition = @roundPosition Vector.add @originalPosition, diff
      @set 'position', newPosition
      diffAfterSnap = Vector.subtract newPosition, @originalPosition
      diffAfterSnap

    moveByUnit: (direction) ->
      unitDiff = [Constants.MOVE_STEP, Constants.MOVE_STEP]
      diff = Vector.plainProduct direction, unitDiff
      @set 'position', Vector.add diff, @get('position')

    roundPosition: ([x,y]) ->
      round = (v) -> Math.round(v/Constants.MOVE_STEP)*Constants.MOVE_STEP
      result = [(round x), (round y)]

    saveState: ->
      @getPage().saveState()

    rotate: (angle) ->
      @doRotate Math.round(angle/Constants.ROTATE_STEP_DEG)*
        Constants.ROTATE_STEP_DEG

    doRotate: (angle) ->
      originalToCenter = Vector.rotate(
        Vector.multiply(@originalSize, 0.5),
        @originalRotate
      )
      newToCenter = Vector.rotate originalToCenter, angle
      diff = Vector.subtract newToCenter, originalToCenter
      @set 
        rotate: angle + @originalRotate
        position: Vector.subtract @originalPosition, diff

    setSizePreservingWidthAndCenter: (size) ->
      aspectRatio = size[1]/ size[0]
      [oldWidth, oldHeight ] = @get 'size'
      newHeight = oldWidth*aspectRatio
      size = [oldWidth, newHeight]
      heightDiff = newHeight - oldHeight
      position = Vector.add @get('position'), [0 , - heightDiff/2]
      @set {size,position}

    getOriginalCenter: ->
      leftTopToCenter = Vector.rotate(
        Vector.multiply(@originalSize,0.5)
        @originalRotate
      )
      Vector.add leftTopToCenter, @originalPosition

    getCornerPosition: (corner) ->
      leftTopToCorner = Vector.rotate Vector.plainProduct(@get('size'),corner),
        @get('rotate')
      Vector.add leftTopToCorner, @get('position')

    getAllCorners: ->
      [
        [0,0]
        [1,0]
        [1,1]
        [0,1]
      ]

    getAllCornersPosition: ->
      (@getCornerPosition(corner) for corner in @getAllCorners())

    getCornerOppositeToTop: ->
      @getTopCorner().map (x) -> 1 - x

    getTopCorner: ->
      (@getAllCorners().sort (c1,c2) =>
        p1 = @getCornerPosition(c1)
        p2 = @getCornerPosition(c2)
        if p1[1] is p2[1]
          p1[0] - p2[0]
        else
          p1[1] - p2[1]
      )[0]

    getCenter: ->
      leftTopToCenter = Vector.rotate(
        Vector.multiply(@get('size'),0.5)
        ,
        @get('rotate')
      )
      Vector.add leftTopToCenter, @get('position')

    duplicate: ->
      @getPage().duplicateShape @

    interactiveLinkSelect: ->
      @collection.page.interactiveLinkSelect 
        pageElementId: @id
        link: @get 'link'

    serialize: ->
      result = JSON.parse JSON.stringify _.pick @attributes, 
        TRANSIENT_ATTRS.concat(PERSISTENT_ATTRS)

    cloneState: ->
      JSON.parse JSON.stringify @pick PERSISTENT_ATTRS...
    
    toJSON: ->
      result = @cloneState()
      for attr in FILE_ATTRS
        result[attr] = @get(attr)?.path ? @get(attr) ? null
      result

    getFilePaths: ->
      for attr in FILE_ATTRS
        @get(attr)?.path ? []

    parse: (shape) ->
      for attr in FILE_ATTRS
        if _.isString shape[attr]
          shape[attr] = _.findWhere @collection.page.get('files'), path: shape[attr]
      shape
