define (require) ->
  ItemView = require 'base/itemView'



  # Alert window. Usually called via Modal.alert(options).
  # @param options.message - alert message
  # @param options.title - alert window title (optional)
  # Can be called either as Alert({ message, title }), or Alert(message, title)
  class AlertView extends ItemView
    template: 'widgets.alert'
    tagName: 'div'
    className: 'gn-modal-container gn-modal-alert'
    triggers:
      'click #close': 'modal:close'

    templateHelpers: ->
      @options

    constructor: (message, title) ->
      if typeof message isnt 'object' then super { message, title } else super arguments[0]
