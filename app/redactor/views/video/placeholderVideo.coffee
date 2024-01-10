define (require) ->
  BaseShapeView = require '../baseShape'


  class PlaceholderVideo extends BaseShapeView
    serializeData: ->
      _.extend super,
        typevideo: true
        placeholder: true
    showPreview: ->
      # empty
