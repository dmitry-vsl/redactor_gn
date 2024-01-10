define (require) ->
  Marionette = require 'marionette'
  View = require './view'
  Utils = require 'utils/utils'



  # Composite view integrated with jquery.sortable. Currently new elements can
  # be added only to the end of the container el.  Params to $.sortable are
  # passed via 'sortable' attr of the object. By default after sort it
  # rearranges elements in underlying collection (see base/collection) or calls
  # sortupdate callback if passed

  Utils.include(View).to class SortableView extends Marionette.CompositeView

    constructor: ->
      super
      # unbind from sort event to prevent rearraging child view after sorting
      # underlying collection 
      @stopListening @model, 'sort' 

      @on "render", =>
        # @sortable false means that sortable is disabled
        unless _.isBoolean(@sortable) and !@sortable
          $container = @getItemViewContainer @
          sortOptions = @sortable ? {}
          sortableEl = $container.sortable(@sortable)
          sortableEl.on "sortupdate", =>
            @trigger 'sortupdate', @getOrder()

    renderItemView: (view, index) -> 
      super
      view.$el.data "__model_id", view.model.id

    getOrder: ->
      $container = @getItemViewContainer @
      result = []
      $container.children().each (ix, item) -> 
        result.push $(item).data "__model_id"
      result
