define (require) ->
  Shape = require './shape'
  Vector = require '../vector'

  class Group extends Shape
    
    initialize: (attrs, {@shapes, @page}) ->
      super
      @set @getBoundingBox @shapes

    getPage: ->
      @page

    remove: ->
      @page.deselectGroup()
      for shape in @shapes
        shape.remove()

    getBoundingBox: (shapes) ->
      top = +Infinity
      left = +Infinity
      bottom = -Infinity
      right = -Infinity
      for shape in shapes
        for [cLeft,cTop] in shape.getAllCornersPosition()
          top = Math.min top, cTop
          bottom = Math.max bottom, cTop
          left = Math.min left, cLeft
          right = Math.max right, cLeft
            
      width = right - left
      height = bottom - top

      return result = 
        size: [width, height]
        position: [left, top]
  
    saveOriginalPosition: ->
      super
      for shape in @shapes
        shape.saveOriginalPosition()

    move: ->
      diffAfterSnap = super
      for shape in @shapes
        shape.set 'position', Vector.add(shape.originalPosition, diffAfterSnap)
      
    doScale: ({scale, zoomDirection}) ->
      super
      for shape in @shapes
        shape.doScale.apply shape, arguments
        @adjustShapePositionInsideGroup {shape, scale, zoomDirection}

    adjustShapePositionInsideGroup: ({shape,scale,zoomDirection}) ->
      zoomDirection = zoomDirection.map (i) -> 1 - i
      leftTopToGroupCorner = Vector.rotate Vector.plainProduct(@originalSize,zoomDirection),
        @originalRotate
      groupCorner = Vector.add leftTopToGroupCorner, @originalPosition
      leftTopToShapeCorner = Vector.rotate Vector.plainProduct(shape.originalSize,zoomDirection),
        shape.originalRotate
      shapeCorner = Vector.add leftTopToShapeCorner, shape.originalPosition

      move = Vector.subtract shapeCorner, groupCorner

      shape.set 'position', Vector.add shape.get('position'), 
        Vector.multiply(move, scale-1)

    doRotate: (angle) ->
      super
      for shape in @shapes
        shape.rotate angle
        @rotateAroundCenter shape, angle

    rotateAroundCenter: (shape, angle) ->
      originalCenterToCenter = Vector.subtract shape.getOriginalCenter(),
        @getOriginalCenter()
      newCenterToCenter = Vector.rotate originalCenterToCenter, angle
      diff = Vector.subtract newCenterToCenter, originalCenterToCenter 
      shape.set 'position', Vector.add shape.get('position'), diff
