define (require) ->
  BaseShapePanel = require './baseShapePanel'
  Utils = require 'utils/utils'
  openFile = require 'utils/openFile'
  showLoadFailMessage = require './showLoadFailMessage'
  Vector = require '../../vector'



  IMAGE_PREVIEW_WIDTH = 180

  class ImagePanel extends BaseShapePanel
    modelEvents: _.extend {}, BaseShapePanel::modelEvents, 
      'change:file'     : 'showImagePreview'
      'change:file change:cropSize change:cropPosition': 'showImagePreview'
      'change:cropping' : 'toggleCropping'

    events: _.extend {}, BaseShapePanel::events,
      'click .js-upload'     : 'upload'
      'click .js-google'     : 'showGoogleSearch'
      'click .js-crop'       : -> @shapeView.startCropping()
      'click .js-apply'      : -> @model.finishChanges()
      'click .js-cancel'     : -> @model.cancelCropping()

    onRender: ->
      super
      @ui.previewIcon.addClass 'image-icon'
      @showImagePreview()
      @toggleCropping()
      @initBorder()
      @initOpacity()

    toggleCropping: ->
      cropping = !!@model.get 'cropping'
      @ui.controlButtons.toggle not cropping
      @ui.applyButtons.toggle cropping

    upload: ->
      openFile(accept: "image/*").then ([file]) =>
        @model.uploadImage file

    showGoogleSearch: ->
      closeUI = =>
        @controller.showShapePanel()
      @model.focusOnShape()
      @model.startChanges onFinishChanges: =>
        closeUI()
        @model.removeFocusOnShape()
        @model.rollbackChanges()
      @controller.showGoogleSearch 
        onApply: =>
          closeUI()
          @model.removeFocusOnShape()
          @model.applyGoogleImage()?.fail =>
            @model.rollbackChanges()
            showLoadFailMessage()
        onCancel: => 
          @model.finishChanges()
        onSelect: (item) =>
          @model.setGoogleImage item.toJSON()

    showImagePreview: ->
      hasFile = @model.get('file')?
      @ui.imagePreview.toggle hasFile
      @ui.noimage.toggle not hasFile
      @$('.js-crop').css 'display', if hasFile then 'inline-block' else 'none'
      if hasFile
        aspectRatio = @model.get('size')[1]/@model.get('size')[0]
        @ui.imagePreview.height IMAGE_PREVIEW_WIDTH*aspectRatio
        scale = IMAGE_PREVIEW_WIDTH / @model.get('size')[0]
        @ui.imageContainer.css @shapeView.getBackgroundCss()
        @ui.imageContainer.css Vector.toCssSize @model.get('size')
        @ui.imageContainer.css Utils.createVendorCss 'transform', 
          "scale(#{scale},#{scale})"
