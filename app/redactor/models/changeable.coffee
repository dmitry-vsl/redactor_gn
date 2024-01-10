define ->
  startChanges: ->
    redactor = @getRedactor()
    redactor.startChanges.apply redactor, arguments
    @originalState = @cloneState()

  stopChanges: ->
    @getRedactor().stopChanges()

  finishChanges: ->
    @getRedactor().finishChanges()

  hasUncommitedChanges: ->
    @originalState? and not _.isEqual @originalState, @cloneState()

  rollbackChanges: ->
    if @hasUncommitedChanges()
      @set @originalState
    @originalState = undefined
    @stopChanges()

  commitChanges: ->
    if @hasUncommitedChanges()
      @saveState()
    @originalState = undefined
    @stopChanges()

  setAndCommit: ->
    @startChanges()
    @set.apply @, arguments
    @commitChanges()
