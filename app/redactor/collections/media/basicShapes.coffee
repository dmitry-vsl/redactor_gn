define ->

  class BasicShape extends Backbone.Model
    toJSON: ->
      data = super
      data.width =  100
      data.height = 100
      data.type = 'svg'
      data

  class BasicShapes extends Backbone.Collection
    model: BasicShape
    initialize: ->
      shapes = 
        for shapeType in ['rectangle','ellipse','star','hexagon','triangle']
          {shapeType, shapeCategory: 'basic'}
      @reset shapes
