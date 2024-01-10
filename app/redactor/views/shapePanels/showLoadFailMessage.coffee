define (require) ->
  Modal = require 'ui/widgets/modal'
  i18n = require 'i18n'


  bundle = i18n.getBundle().redactor
  ->
    Modal.confirm 
      message: bundle.could_not_add_element
      buttons: [id: 'ok', class: 'gn-btn-simple', text: bundle.ok]
