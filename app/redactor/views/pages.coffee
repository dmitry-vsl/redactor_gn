define (require) ->
  Layout = require 'base/layout'
  SortableView = require 'base/sortableView'
  PageView = require './page'
  i18n = require 'i18n'
  Modal = require 'ui/widgets/modal'



  redactorBundle = i18n.getBundle().redactor

  class PageItemView extends Layout
    template: "redactor.pages.item"
    className: "list-item"
    tagName:   'li'

    ui:
      name: '.js-name'
    
    regions:
      previewDiv: '.js-preview'

    modelEvents:
      'change:selected' : 'updateSelected'

    bindings: ['name']

    events: 
      'click' : 'select'

    onRender: ->
      @updateSelected()

    onDomRefresh: ->
      @showPreview()

    showPreview: ->
      preview = new PageView {@model, previewMode: true}
      @previewDiv.show preview
      preview.scaleToFitContainer()

    updateSelected: ->
      @$el.toggleClass 'active', @model.collection.isSelected @model

    select: ->
      @model.collection.select @model

  class PagesView extends SortableView
    template: 'redactor.pages.panel'
    itemViewContainer: ".js-pages-list"
    itemView: PageItemView
    className: 'panel pages'

    collectionEvents: 
      'reset add remove': 'toggleRemove'
    
    events: ->
      'click .js-closePanel' : -> @controller.showShapePanel()

    sortable: 
      axis: 'y'

    initialize: ({@controller}) ->
      @on 'sortupdate', (order) =>
        @collection.updateOrder order

    onRender: ->
      @toggleRemove()   
      ['createPage','renamePage','removePage','duplicatePage'].forEach (action) =>
        @$(".js-#{action}").click (e) => 
          @[action] e

    createPage: ->
      @collection.createPage()

    renamePage: ->
      Modal.prompt(label: redactorBundle.pages.rename_page).on 'save',(name)=>
        unless @collection.currentPage.rename name
          Modal.confirm(message: redactorBundle.pages.page_exists, buttons: [
            { id: "ok", class: "gn-btn-simple" }
          ]).on 'ok', => @renamePage()

    removePage: (e) ->
      @collection.removePage @collection.currentPage

    duplicatePage: (e) ->
      @collection.duplicatePage @collection.currentPage

    toggleRemove: ->
      show = @collection.size() isnt 1
      @$('.js-removePage').css 'display', if show then 'inline-block' else 'none'
