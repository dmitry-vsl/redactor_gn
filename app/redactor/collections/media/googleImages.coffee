define (require) ->
  Collection = require 'base/collection'
  Constants = require '../../constants'


  
  ITEMS_PER_PAGE = 10
  
  class GoogleImage extends Backbone.Model
    toJSON: ->
      data = super
      result = 
        width: data.image.width
        height: data.image.height
        original: data.link
        preview: data.image.thumbnailLink
        type: 'image'
        imageType: 'google'

  class GoogleImagesCollection extends Collection
    model: GoogleImage

    search: (@query) ->
      @_hasMore = true
      @reset []
      @loadNextPage()

    loadNextPage: ->
      $.when @doSearch(offset: @size()), @doSearch(offset: @size() + ITEMS_PER_PAGE)

    doSearch: ({offset}) ->
      def = $.Deferred()
      request = gapi.client.search.cse.list
        q: @query
        key: Constants.GOOGLE_API_KEY
        cx: Constants.GOOGLE_CSE_ID
        searchType: 'image'
        imgSize: 'small'
        start: offset + 1
      .execute ({items}) =>
        if items?
          @add items
          length = items.length
        else
          length = 0
        if length < ITEMS_PER_PAGE
          @_hasMore = false
        def.resolve()
      def
    
    hasMore: -> @_hasMore
