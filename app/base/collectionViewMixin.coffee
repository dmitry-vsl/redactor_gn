define (require) ->
  Marionette = require 'marionette'


  (clazz) ->
    eachChildView: (callback) ->
      @children.each (v) => 
        unless (@emptyView? and (v instanceof @emptyView))
          callback(v)

    getLoadingView: ->
      Marionette.getOption @, "loadingView"

    showEmptyView: ->
      EmptyView = @getEmptyView()

      if EmptyView && !@_showingEmptyView
        @_showingEmptyView = true
        @model = new Backbone.Model unless @model?
        @addItemView @model, EmptyView, 0

    showLoadingView: ->
      LoadingView = do @getLoadingView

      if LoadingView? and !@_showingEmptyView
        @_showingEmptyView = true
        @model = new Backbone.Model unless @model?
        @addItemView @model, LoadingView, 0
        # When a non-empty collection is fetched, the collection view is 
        # authomatically re-rendered. If the collection is still empty after
        # it has been fetched, show empty view.
        @collection.once 'sync', =>
          if @collection.length is 0 
            @closeEmptyView()
            @showEmptyView()

    checkEmpty: ->
      if @getLoadingView()?
        if !@collection?.length
          if @collection?.isNew()
            @showLoadingView()
          else
            @showEmptyView()
      else
        clazz::checkEmpty.apply @, arguments

    # Inserts child view regarding index. Original appendHtml inserts 
    # view at the beginning of the el ignoring index
    #
    # https://github.com/marionettejs/backbone.marionette/wiki/Adding-support-for-sorted-collections
    appendHtml: (collectionView, itemView, index) ->
      if collectionView.isBuffering
        collectionView._bufferedChildren.push itemView

      childrenContainer = 
        if collectionView.isBuffering 
          $(collectionView.elBuffer)
        else
          collectionView.itemViewContainer ? collectionView.$el

      if _.isString childrenContainer then childrenContainer = collectionView.$(childrenContainer)
      children = childrenContainer.children()
      if index >= children.length
        unless @reverseOrder
          childrenContainer.append itemView.el
        else
          childrenContainer.prepend itemView.el
      else
        unless @reverseOrder
          children.eq(index).before itemView.el
        else
          children.eq(children.length - index - 1).after itemView.el

    setSort: (newOrderIds) -> 
      @eachChildView (v) =>
        newIndex = newOrderIds.indexOf v.model.id
        @.appendHtml @, v, newIndex

    render: ->
      clazz::render.apply @, arguments
      if @paged
        @on 'dom:refresh', @initPaging

    pagingThresholdOffset: 100

    initPaging: ->
      container = @getPagingContainer() 
      container.on 'scroll', =>
        if not @loadingNextPage and @collection.hasMore()
          scrollBottom = container[0].scrollHeight - container.outerHeight() - container.scrollTop()
          if scrollBottom <= @pagingThresholdOffset
            @loadingNextPage = true
            @collection.loadNextPage().then =>
              @loadingNextPage = false

    getPagingContainer: ->
      if @pagingContainer?
        $(@pagingContainer)
      else
        @getItemViewContainer @
