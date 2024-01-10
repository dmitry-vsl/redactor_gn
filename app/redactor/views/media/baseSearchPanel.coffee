define (require) ->
  ItemView = require 'base/itemView'
  CompositeView = require 'base/compositeView'
  Modal = require 'ui/widgets/modal'



  class Item extends ItemView
    tagName: 'li'
    className: 'lib-item'
    template: =>
      preview = @model.toJSON().preview
      """
        <div class='bg-inner' 
        style='background:url(#{preview});background-size:cover'>
        </div>
      """
    initialize: ({@parentView}) ->
    events: 
      click: ->
        @$el.siblings().removeClass 'active'
        @$el.addClass 'active'
        @parentView.onSelect @model
  
  class BaseSearchPanel extends CompositeView
    
    itemView: Item
    itemViewContainer: '.js-items'

    paged: true
    pagingContainer: '.content'

    ui:
      search: '.js-search-field'

    onRender: ->
      @ui.search.on 'keydown', (e) ->
        e.stopPropagation()

    focusSearch: ->
      @ui.search[0].focus()

    setButtonHandlers: ({@onApply,@onCancel,@onSelect}) ->

    events:
      'change @ui.search': 'search'
      'click .js-apply'  :  -> @onApply()
      'click .js-cancel' :  -> @onCancel()

    initialize: ({@redactor,@controller}) ->

    itemViewOptions: -> {parentView: @}

    search: ->
      @collection.search @ui.search.val()
