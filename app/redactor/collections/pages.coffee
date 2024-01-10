define (require) ->
  Page = require '../models/page'
  Constants = require '../constants'


  
  class PagesCollection extends Backbone.Collection
    
    model: Page

    initialize: (models, {@presentationId, @pageId}) ->

    parse: (resp) ->
      resp.data.pages

    init: ->
      @theme = JSON.parse JSON.stringify Constants.DEFAULT_THEME
      @select @at 0
      
    isSelected: (page) ->
      page is @currentPage

    createPage: (attrs={}) ->
      newPage = new Page attrs, collection: @
      @add newPage
      @select newPage
      newPage.history.setPersisted()

    select: (model) ->
      if model is @currentPage
        return
      oldPage = @currentPage
      @currentPage = model
      oldPage?.trigger 'change:selected'
      @currentPage.trigger 'change:selected'
      @trigger 'change:page'

    removePage: (modelToRemove) ->
      index = @indexOf modelToRemove
      newSelectedIndex = if index is 0 then 0 else index - 1
      @remove modelToRemove
      @select @at newSelectedIndex

    duplicatePage: (model) ->
      @createPage model.duplicate()

    updateOrder: (newOrder) ->
      oldOrder = @pluck 'id'
      i = 0
      found = false
      while not found
        if newOrder[i] isnt oldOrder[i]
          id = newOrder[i]
          found = true
        else
          i++
      models = for id in newOrder
        @findWhere({id})
      @reset models, silent: true

    hasUnsavedChanges: ->
      @some (page) -> page.history.hasUnsavedChanges()

    save: ->
      @trigger 'request'
      $.when(@savePages(), @savePresentationContent()).then => 
        @trigger 'sync'

    savePages: ->
      pages = []
      @each (model) => 
        if model.history.hasUnsavedChanges()
          pages.push model.toJSON()
      @each (model) -> model.history.setPersisted()

    savePresentationContent: ->
      $.Deferred.resolve()
