define (require) ->
  Marionette = require 'marionette'
  View = require './view'
  Utils = require 'utils/utils'

  
  Utils.include(View).to class ItemView extends Marionette.ItemView

    # Added collectionTemplateHelpers to extend serialized collection items with helper methods 
    # (the same way as templateHelpers extend the model)
    mixinTemplateHelpers: (data) ->
      data = super
      helpers = Marionette.getOption @, "collectionTemplateHelpers"
      if data.items? and helpers?
        if _.isFunction helpers 
          helpers = helpers.call @
        data.items = _.map data.items, (item) -> _.extend item, helpers

      data
