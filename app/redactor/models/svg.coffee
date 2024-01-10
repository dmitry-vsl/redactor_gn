define (require) ->
  Shape = require './shape'
  Vector = require '../vector'



  RADIUS_CHANGE_STEP = 5

  class Svg extends Shape
    defaults: _.extend {}, Shape::defaults,
      shapeCategory : 'basic'
      shapeType : 'triangle'
      fillColor: null
      radius: 0
      size: [200, 200]

    set: ->
      shapeCategory = @get('shapeCategory')
      newShapeCategory = arguments[0].shapeCategory
      if shapeCategory? and newShapeCategory? and newShapeCategory isnt shapeCategory
        @trigger 'forceRemoveView', @
        super
        @trigger 'forceRenderView', @
      else
        super

    isRectangle: -> 
      @get('shapeType') is 'rectangle'

    incrementRadius: ->
      if @get('radius') < 50
        @changeRadius +1

    decrementRadius: ->
      if @get('radius') > 0
        @changeRadius -1

    changeRadius: (dir) ->
      @set 'radius', @get('radius') + dir * RADIUS_CHANGE_STEP

    scaleSide: ({mouseMoveVector, scaleDirection}) ->
      move = Vector.scalarProduct mouseMoveVector, 
        Vector.rotate(scaleDirection,@originalRotate)

      [dirX,dirY] = scaleDirection

      @set 'size', Vector.add @originalSize,
        Vector.multiply [Math.abs(dirX),Math.abs(dirY)], move

      moveVector = scaleDirection.map (v) ->
        if v is -1 then -1 else 0

      diff = Vector.rotate(
        Vector.multiply(moveVector,move),
        @originalRotate
      )
      @set 'position', Vector.add(@originalPosition, diff)
 
    getSvgSize: (url) ->
      def = $.Deferred()
      img = new Image
      img.src = url
      img.onload = -> 
        def.resolve _.pick img, 'width','height'
      def

    uploadSvg: (file) ->
      @finishChanges()
      uploadedFile = undefined
      @getPage().uploadFile(file,type:'shape').then (file) =>
        uploadedFile = file
        @getSvgSize(file.original)
      .then ({width,height}) =>
        @setSizePreservingWidthAndCenter [width,height]
        @setAndCommit
          shapeCategory: 'uploaded'
          file: uploadedFile
