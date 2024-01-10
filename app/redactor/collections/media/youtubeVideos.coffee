define (require) ->
  Collection = require 'base/collection'


  
  MAX_RESULTS = 20

  class YoutubeVideo extends Backbone.Model
    toJSON: ->
      data = super
      result =
        youtubeId: data.id
        preview: data.snippet.thumbnails.default.url
        original: data.snippet.thumbnails.high.url
        width: 480
        height: 360
        type: 'video'

  class YoutubeCollection extends Collection
    model: YoutubeVideo

    search: (@query) ->
      @_hasMore = true
      @reset []
      @loadNextPage()

    loadNextPage: ->
      def = $.Deferred()
      request = gapi.client.youtube.search.list
        q: @query
        part: 'snippet'
        maxResults: MAX_RESULTS
        pageToken: @nextPageToken ? ''

      request.execute ({@nextPageToken,items}) =>
        if items?
          length = items.length
        else
          lenght = 0
        @_hasMore = length is MAX_RESULTS
        
        if items?
          for item in items
            item.id = item.id.videoId
          @add items
        
        def.resolve()

      def

    hasMore: -> @_hasMore
