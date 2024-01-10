define (require) ->
  CompositeView = require 'base/compositeView'
  ItemView = require 'base/itemView'
  Layout = require 'base/layout'
  ShapeView = require './shape'
  Theme = require '../theme'
  i18n = require 'i18n'
  Utils = require 'utils/utils'



  redactorBundle = i18n.getBundle().redactor

  class LayersEmptyView extends ItemView
    template: -> ''

  class LayerView extends Layout
    template: 'redactor.layers.item'
    tagName: 'li'
    className: 'item'


    regions: preview: '.js-preview'

    events:
      'click .js-up' : -> @model.pushTo 'front'
      'click .js-down' : -> @model.pushTo 'back'
      'click .js-remove': -> @model.remove()
      'click .js-select': -> @model.select()

    onRender: ->
      @$el.attr 'data-model', @model.id

    onDomRefresh: ->
      @showPreview()

    showPreview: ->
      shapeView = new ShapeView {
        @model
        previewMode: true
        layerPreviewMode: true
      }
      @preview.show shapeView

  class LayersView extends CompositeView
    template: 'redactor.layers.panel'
    itemView: LayerView
    itemViewContainer: '.js-items'
    emptyView: LayersEmptyView
    className: 'panel layers'

    reverseOrder: true

    ui:
      items: '.js-items'

    initialize: ({@controller}) ->

    events:
      'click .js-closePanel' : -> @controller.showShapePanel()
    
    onRender: ->
      @ui.items.sortable(axis: 'y').on 'sortupdate', @updateSort
      @$el.addClass Theme.getPageClassName @collection.page.getObjectId()

    collectionEvents: 
      'setSort' : 'updateLayersSort'

    updateLayersSort: ->
      @ui.items.children().remove()
      @collection.each (shape) =>
        view = @children.find (view) => view.model is shape
        @ui.items.prepend view.$el
        view.delegateEvents()

    updateSort: =>
      models = []
      @ui.items.children().each (index, el) =>
        models.push @collection.findWhere id: parseInt($(el).attr('data-model'))
      # (reverseOrder: true)
      models.reverse()
      @collection.setSort models
