define (require) ->
  ItemView = require 'base/itemView'


  class AddView extends ItemView
    className: 'panel'
    template: 'redactor.add'
    serializeData: ->
    onRender: ->
      ['text','image','video','svg'].forEach (type) =>
        @$(".js-#{type}").click => @model.createShapeAndSaveState {type}
      
