define (require) ->
  Collection = require './collection'



  class PagedCollection extends Backbone.Collection
    pageSize: 20

    constructor: ->
      @_hasMore = true
      super

    loadNextPage: (options = {}) ->
      _.extend options, { remove: false }
      url = options.url ? _.result @, 'url'
      if @length > 0
        url = url + "?offset=#{@length}"
      options.url = url
      previousSize = @size()
      @fetch(options).then (response) =>
        @_hasMore = @size() - previousSize >= @pageSize

    hasMore: ->
      @_hasMore
