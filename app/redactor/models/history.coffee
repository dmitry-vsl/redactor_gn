define ['backbone'], () ->
  
  historyNumber = 0

  class History
    _.extend @::, Backbone.Events

    constructor: ->
      @stack = []
      @undoDepth = 0

    saveState: (state) ->  
      state = JSON.parse JSON.stringify state
      if @undoDepth is 0
        @_push state
      else
        @stack.splice -@undoDepth, @undoDepth
        @undoDepth = 0
        @_push state

        if @lastPersistedStateIndex? and @_getCurrentStateIndex() < @lastPersistedStateIndex
          @lastPersistedStateIndex = undefined
      @trigger 'change'

    getItemNumber: (action) ->
      diff = switch action
        when 'undo' then -1
        when 'redo' then 1
      @stack[@_getCurrentStateIndex() + diff].number

    isActionAvailable: (action) ->
      switch action
        when 'undo' then @_getCurrentStateIndex() > 0
        when 'redo' then @undoDepth > 0

    undoOrRedo: (action) ->
      unless @isActionAvailable action
        throw new Error 'cannot ' + action
      else
        switch action
          when 'undo' then @undoDepth++
          when 'redo' then @undoDepth--
        @trigger 'change'
        JSON.parse JSON.stringify @stack[@_getCurrentStateIndex()].state

    setPersisted: ->
      @lastPersistedStateIndex = @_getCurrentStateIndex()
      @trigger 'change'

    hasUnsavedChanges: ->
      @lastPersistedStateIndex isnt @_getCurrentStateIndex()

    #private

    _push: (state) ->
      @stack.push {state, number: historyNumber++}


    _getCurrentStateIndex: ->
      @stack.length - @undoDepth - 1
