define (require) ->
  ItemView = require 'base/itemView'
  openFile = require 'utils/openFile'
  showLoadFailMessage = require './shapePanels/showLoadFailMessage'


  class PageBackgroundView extends ItemView
    template: 'redactor.pageBackgroundBlock'
    serializeData: ->
    events: 
      'click .js-google' : 'google'
      'click .js-upload' : 'upload'
      'click .js-remove' : 'removeBackground'

    modelEvents:
      'change:backgroundImageFile' : 'togglePreview'

    initialize: ({@controller,@closeView}) ->

    onRender: ->
      @togglePreview()

    togglePreview: ->
      hasBgImage = @model.get('backgroundImageFile')?
      @$('.js-backgroundImageBlock').toggle hasBgImage
      @$('.js-removeBackgroundImageBlock').toggle not hasBgImage
      if hasBgImage
        @$('.js-preview').css
          backgroundImage: "url('#{@model.get('backgroundImageFile').original}')"
          backgroundSize: 'cover'

    upload: ->
      @controller.showShapePanel()
      openFile(accept: "image/*").then ([file]) =>
        @selectedImageType = 'upload'
        @model.uploadBackground file

    google: ->
      @controller.showGoogleSearch
        onSelect: (item) =>
          file = item.toJSON()
          @model.set 'backgroundImageFile', original: file.original
          @selectedImageType = 'google'
        onCancel: =>
          @model.rollbackChanges()
          @controller.showShapePanel()
          @closeView()
        onApply: =>
          @model.setGoogleBackground().then =>
            @model.commitChanges()
          .fail =>
            @model.rollbackChanges()
            showLoadFailMessage()
          .always =>
            @controller.showShapePanel()
            @closeView()

    removeBackground: ->
      @model.set 'backgroundImageFile', null
