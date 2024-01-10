define (require) ->
  ItemView = require 'base/itemView'



  # Confirm window with configurable buttons. Usually called via Modal.confirm(options).
  # @param options.message - confirm message
  # @param options.buttons - array of buttons, either strings or objects: ["yes", { id: "no", text: "no, please", class: "btn-no" }]
  #                          Class attribute is optional. To subscribe to click events, listen to ConfirmView events named as button ids.
  class ConfirmView extends ItemView
    template: 'widgets.confirm'
    tagName: 'div'
    className: 'gn-modal-container gn-modal-confirm'

    triggers: {}

    templateHelpers: ->
      message: @message
      buttons: @buttons

    initialize: (options) ->
      @message = options.message

      @buttons = _.map options.buttons, (button) =>
        if _.isString button then button = id: button, text: button

        if not button.text? then button.text = button.id

        if not button.class?
          button.class = switch button.id
            when 'cancel' then 'gn-btn-default'
            when 'delete' then 'gn-btn-danger'
            when 'no' then 'gn-btn-default'
            when 'yes' then 'gn-btn-simple'
            # @todo - more button types
            else 'gn-btn-default'

        @triggers["click ##{button.id}"] = "#{button.id} modal:close"

        button
