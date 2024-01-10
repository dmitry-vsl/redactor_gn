define (require) ->
  Marionette = require 'marionette'

  class Model extends Backbone.Model

    constructor:(attrs, options) ->
      super
      if @stateful
        @_snapshot = do @toJSON
        @on 'sync', =>
          @_snapshot = do @toJSON

    isDirty: ->
      not _.isEqual @toJSON(), @_snapshot

    # resets the model to its original state, destroys if new
    reset: ->
      if @isNew() then @destroy.apply @, arguments else @fetch.apply @, arguments      
