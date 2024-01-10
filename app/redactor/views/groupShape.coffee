define (require) ->
  BaseShapeView = require './baseShape'



  class GroupView extends BaseShapeView

    initialize: ({@page}) ->
      super
      @template = 'redactor.shapes.border'

    handleMouseDown: (event) ->
      @startMove {event}
      return false

    onRender: ->
      super
      @showSelection()
