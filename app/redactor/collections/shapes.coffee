define (require) ->
  ShapeFactory = require '../models/shapeFactory'



  class Shapes extends Backbone.Collection
    initialize: (models,{@page}) ->

    model: ShapeFactory

    getNextId: ->
      unless @maxId?
        @maxId = 0
        for model in @models
          if model.id? and model.id > @maxId
            @maxId = model.id
      ++@maxId

    setSort: (models) ->
      @reset models, silent: true
      @trigger 'setSort', (m.id for m in models)
      @page.saveState()

    pushTo: (direction, model) ->
      models = @models.slice 0
      models.splice @indexOf(model), 1
      models[if direction is 'front' then 'push' else 'unshift'] model
      @setSort models
    
    smartReset: (shapes) ->
      oldIds = (m.id for m in @models)
      newIds = (s.id for s in shapes)
      shapeIdsToRemove = _.difference oldIds, newIds
      shapeIdsToCreate = _.difference newIds, oldIds
      shapeIdsToUpdate = _.intersection oldIds, newIds

      for id in shapeIdsToRemove
        @remove @findWhere({id})

      for shape in shapes
        if shape.id in shapeIdsToCreate
          @add shape

      for shape in shapes
        if shape.id in shapeIdsToUpdate
          @findWhere({id: shape.id}).set shape

      models = []
      for shape in shapes
        models.push @findWhere({id:shape.id})
      @reset models, silent: true
      @trigger 'setSort', (m.id for m in models)

      @trigger 'smartReset'

    serialize: ->
      @map (s) -> s.serialize()
