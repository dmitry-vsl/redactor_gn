define (require) ->
  En = require 'i18n/en'

  bundles =
    en: En

  class I18n
    
    getBundle: ->
      bundles[@lang ? 'en']

    setLang: (@lang) ->

    getLangs: -> Object.keys bundles

    format: (string, args...) ->
      i = 0
      string.replace /{}/g, -> args[i++]

  i18n = new I18n
