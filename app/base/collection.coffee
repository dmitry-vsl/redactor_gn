define (require) ->
  Marionette = require 'marionette'
  Model = require './model'



  class Collection extends Backbone.Collection

    constructor:(attrs, options) ->
      super

      if @stateful
        @_snapshot = do @toJSON
        @on 'sync reset', =>
          @trigger 'change:totalCount'
          @_snapshot = do @toJSON

    isDirty: ->
      not _.isEqual @toJSON(), @_snapshot

    isNew: -> @_isNew
