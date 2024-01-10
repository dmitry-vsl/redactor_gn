define (require) ->
  BaseShapeView = require '../baseShape'


  class BaseSvgView extends BaseShapeView

    serializeData: -> _.extend super, typesvg: true

    ui: _.extend {}, BaseShapeView::ui,
      svgContainer: '.js-svgContainer'
