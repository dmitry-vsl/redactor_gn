define (require) ->
  Marionette = require 'marionette'
  View = require './view'
  CollectionViewMixin = require './collectionViewMixin'
  Utils = require 'utils/utils'



  Utils.include(CollectionViewMixin, View).to class CompositeView extends Marionette.CompositeView
