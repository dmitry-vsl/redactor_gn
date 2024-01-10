define (require) ->
  Shape = require './shape'
  Vector = require '../vector'



  class Text extends Shape
    defaults: _.extend {}, Shape::defaults,
      text: "<h1 style='text-align:center'>Text</h1>"
      size: [600, 100]
      scale: 3

    doScale: ({scale}) ->
      super
      @set 'scale', scale*@originalScale

    saveOriginalPosition: ->
      super
      @originalScale = @get('scale')

    getEffectiveBorderWidth: ->
      @get('borderWidth') / @get('scale')

    resize: (mouseVector) ->
      [width,height] = @originalSize
      dir = Vector.rotate [1,0], @get('rotate')
      widthDiff = Vector.scalarProduct dir, mouseVector
      @set 'size', [width + widthDiff, height]

    # overrides maximize in base shape
    maximize: ->
      scaleX = @getPage().get('size')[0] / @get('size')[0]
      scaleY = @getPage().get('size')[1] / @get('size')[1]
      scale = Math.min scaleX, scaleY
      @set 
        size: Vector.multiply @get('size'), scale
        scale: @get('scale')*scale
      @getPage().setToCenter @
      @saveState()

    fitWidthToPage: ->
      @set size: [ @getPage().get('size')[0], @originalSize[1] ]

    restoreVerticalCenter: ->
      sizeDiff = Vector.subtract(@get('size'), @originalSize)
      newPosition = Vector.subtract @originalPosition, 
        Vector.multiply sizeDiff, 0.5
      @set position: [0, newPosition[1]]

    stretch: ->
      @saveState()
