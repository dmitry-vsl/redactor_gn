define (require) ->
  showLoadFailMessage = require './shapePanels/showLoadFailMessage'


  showYoutubeSearch: ({controller, model}) ->
    closeUI = =>
      controller.showShapePanel()
      model.removeFocusOnShape()
    model.startChanges onFinishChanges: =>
      closeUI()
      model.rollbackChanges()
    model.focusOnShape()
    controller.showYoutubeSearch
      onApply: =>
        closeUI()
        model.applyYoutubeVideo()
      onSelect: (item) =>
        model.setYoutubeVideo item.toJSON()
      onCancel: =>
        model.finishChanges()
