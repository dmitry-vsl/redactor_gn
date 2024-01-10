define (require) ->
  Marionette = require 'marionette'
  View = require './view'
  Utils = require 'utils/utils'

  Utils.include(View).to class Layout extends Marionette.Layout
    render: ->
      super
      @on 'dom:refresh', =>
        for regionName, selector of @regions
          @[regionName].currentView?.triggerMethod 'dom:refresh'
