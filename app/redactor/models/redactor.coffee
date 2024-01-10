define (require) ->
  Page = require './page'
  History = require './history'
  PagesCollection = require '../collections/pages'
  Constants = require '../constants'
  Theme = require '../theme'



  class Redactor extends Backbone.Model
    initialize: ({@presentationId, @pageId}) ->
      @model = @pages = new PagesCollection [{id: @pageId}], {@presentationId,@pageId}

      @model.redactor = @

      @themeHistory = new History

      @model.on 'all', (event) => @trigger event
      @themeHistory.on 'all', (event) => @trigger "history:#{event}"

    init: ->
      @model.init()
      @themeHistory.saveState @getTheme()
      @themeHistory.setPersisted()

    save: ->
      @finishChanges()
      # TODO check if already saving
      @model.save().then =>
        @themeHistory.setPersisted()

    hasUnsavedChanges: ->
      @model.hasUnsavedChanges() or @themeHistory.hasUnsavedChanges()

    undoOrRedo: (action) ->
      if @getHistoryFor(action) is @getPage().history
        @getPage().undoOrRedo action
      else
        @model.theme = @themeHistory.undoOrRedo action
        @changeTheme()

    isActionAvailable: (action) ->
      @getHistoryFor(action)?

    getHistoryFor: (action) ->
      pageHistory = @getPage().history
      if @themeHistory.isActionAvailable(action)
        if pageHistory.isActionAvailable(action)
          if (
            @themeHistory.getItemNumber(action) > pageHistory.getItemNumber(action)
          ) and (
            action is 'undo'
          ) or (
            @themeHistory.getItemNumber(action) < pageHistory.getItemNumber(action)
          ) and (
            action is 'redo'
          )
            @themeHistory
          else
            pageHistory
        else
          @themeHistory
      else
        if pageHistory.isActionAvailable(action)
          pageHistory
        else
          undefined

    getPage: ->
      if @presentationId? then @pages.currentPage else @page

    isPresentation: ->
      @presentationId?

    startChanges: ({onFinishChanges}={}) ->
      @finishChanges()
      @onFinishChanges = onFinishChanges

    stopChanges: ->
      @onFinishChanges = undefined

    finishChanges: ->
      @onFinishChanges?()
      @stopChanges()

    getTheme: ->
      @model.theme

    changeTheme: ->
      Theme.applyTheme 
        objectId: @getPage().getObjectId()
        theme: @getTheme()
      @trigger 'change:theme'

    setTheme: (type, theme) ->
      @model.theme[type] = theme
      @changeTheme()

    applyTheme: ->
      @themeHistory.saveState @getTheme()
