define (require) ->
  BaseShapePanel = require './baseShapePanel'
  openFile = require 'utils/openFile'
  Vector = require '../../vector'
  loadBasicSvgs = require '../../loadBasicSvgs'
  Constants = require '../../constants'
  ShapeFactory = require '../shape'
  Theme = require '../../theme'


  
  # TODO slider for border radius
  
  class SvgPanel extends BaseShapePanel
    modelEvents: _.extend {}, BaseShapePanel::modelEvents, 
      'change:shapeCategory' : ->
        @showSvgPreview()
        @toggleFillColorBlock()

    serializeData: -> _.extend super, shapes: Constants.STANDART_SVG

    ui: _.extend {}, BaseShapePanel::ui,
      shapesList: '.js-shapesList'
      basicPreview: '.js-basicPreview'
      previewContainer: '.js-previewContainer'
      fillColorBlock: '.js-fillColorBlock'

    events: _.extend {}, BaseShapePanel::events,
      'click .js-upload'     : 'upload'
      'click .js-preview'    : 'showShapesList'

    onRender: ->
      super
      @$el.addClass Theme.getPageClassName @model.getPage().getObjectId()
      @$('.js-shapeItem').click (e) =>
        @selectShape $(e.currentTarget).attr('data-shape')
        e.stopPropagation()
      @ui.shapesList.hide()
      @initBorder()
      @initOpacity()
      @initFillColorPicker()
      @toggleFillColorBlock()

    onDomRefresh: ->
      @showSvgPreview()

    toggleFillColorBlock: ->
      @ui.fillColorBlock.toggle (@model.get('shapeCategory') is 'basic')

    initFillColorPicker: ->
      colorEl = @$('.js-fillColor')
      updateBorderColor = =>
        colorEl.css 'background', @model.get 'fillColor'
      @listenTo @model, 'change:fillColor', updateBorderColor
      updateBorderColor()
      fillColorPicker = @initColorPicker colorEl,
        currentColor: =>
          @model.get 'fillColor'
        onOpen: =>
          @model.startChanges onFinishChanges: =>
            fillColorPicker.closeColorPicker()
            @model.commitChanges()
        onColorChange: (color) => 
          @model.set 'fillColor', color
        onApply: => 
          @model.finishChanges()
        onCancel: => 
          @model.rollbackChanges()
    
    showShapesList: ->
      @model.startChanges onFinishChanges: =>
        @ui.shapesList.hide()
        @model.commitChanges()
      @ui.shapesList.show()

    selectShape: (shapeType) ->
      @model.set {shapeType,shapeCategory:'basic'}

    upload: ->
      openFile(accept: "image/svg").then ([file]) =>
        @model.uploadSvg file

    showSvgPreview: ->
      @preview?.close()
      @preview = new ShapeFactory({
        @model, 
        page: @shapeView.page, 
        layerPreviewMode: true
      }).render()
      @preview.$el.css('position','absolute').appendTo @ui.previewContainer
      @preview.onDomRefresh()

    onClose: ->
      @preview?.close()
