define (require) ->
  i18n = require 'i18n'
  initNanoscroller = require 'ui/widgets/initNanoscroller' 
  RedactorController = require 'redactor/controller'
  require './commonLibs'

  initNanoscroller()
  i18n.setLang 'en'

  new RedactorController()
