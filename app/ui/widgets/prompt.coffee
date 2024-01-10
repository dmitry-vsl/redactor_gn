define (require) ->
  ItemView = require 'base/itemView'



  # Prompt window. Usually called via Modal.prompt(options).
  class PromptView extends ItemView
    template: 'widgets.prompt'
    tagName: 'div'
    className: 'gn-modal-body gn-modal-promt'

    ui:
      label :'#label'
      input: '#prompt'
      btnSave: '#save'

    events:
      'click #save' : 'save'

    triggers:
      'click #cancel, #save' : 'modal:close'

    templateHelpers: ->
      @options

    save: ->
      @trigger 'save', @ui.input.val()

    onRender: ->
      @ui.input.bind 'input change', (ev) =>
        val = ev.target.value
        @ui.btnSave.prop 'disabled', val is @options.prompt or not val.length

    onDomRefresh: ->
      @ui.input.select().focus()
