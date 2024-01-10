define (require) ->
  Layout = require 'base/layout'
  AddPanel = require './add'
  TextPanel = require './shapePanels/textPanel'
  ImagePanel = require './shapePanels/imagePanel'
  ShapePanel = require './shapePanels/shapePanel'
  VideoPanel = require './shapePanels/videoPanel'
  SvgPanel = require './shapePanels/svgPanel'


  class ShapePanel extends Layout
    className: 'panel-wrap2'
    template: -> '<div class="panel-wrap2"></div>'
    serializeData: ->
    regions: 
      container: '.panel-wrap2'

    initialize: ({@pageView, @controller}) ->
      @listenTo @model, 'change:selectedShape', =>
        @controller.showShapePanel()
        if @model.get('selectedShape')?
          @showShapePanel @model.getSelectedShape()
        else
          @showAddPanel()
    
    onRender: ->
      @showAddPanel()

    showAddPanel: ->
      @container.show new AddPanel {@model}

    showShapePanel: (shape) ->
      clazz = switch shape.get 'type'
        when 'video' then VideoPanel
        when 'text' then TextPanel
        when 'image' then ImagePanel
        when 'shape' then ShapePanel
        when 'svg' then SvgPanel
      shapePanel = new clazz {model: shape, @pageView, @controller}
      @container.show shapePanel
