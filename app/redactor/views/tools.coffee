define (require) ->
  ItemView = require 'base/itemView'


  class ToolsView extends ItemView
    template: 'redactor.tools'

    initialize: ({@controller}) ->
      @buttons = {}

      @listenTo @model, 'history:change', @toggleHistoryButtons

      @initSavingEvents()

    onRender: ->
      ['preview','save','undo','redo','themes','layers','library','pages',
      'closeRedactor'].forEach (action) =>
        (button = @buttons[action] = @$ ".js-#{action}").click =>
          unless button.hasClass 'disabled'
            @[action]()

      unless @model.isPresentation()
        @buttons['pages'].hide()

      @toggleHistoryButtons()

    initSavingEvents: ->
      @listenTo @model, 'request', => @showSaveSpinner()
      @listenTo @model, 'sync'   , => @removeSaveSpinner() 

    toggleHistoryButtons: =>
      @buttons.save.toggleClass 'disabled', not @model.hasUnsavedChanges()
      @buttons.undo.toggleClass 'disabled', not @model.isActionAvailable 'undo'
      @buttons.redo.toggleClass 'disabled', not @model.isActionAvailable 'redo'

    showSaveSpinner: ->
      @buttons.save.addClass 'saving'
      @buttons.save.spinner()

    removeSaveSpinner: ->
      @buttons.save.removeClass 'saving'
      @buttons.save.spinner 'destroy'

    themes: ->
      @controller.showThemes()

    layers: ->
      @controller.showLayers()

    pages: ->
      @controller.showPages()

    undo: ->
      @model.undoOrRedo 'undo'

    redo: ->
      @model.undoOrRedo 'redo'

    save: ->
      @model.save()

    preview: ->
      @controller.preview()
