define (require) ->
  BaseShapePanel = require './baseShapePanel'
  openFile = require 'utils/openFile'
  YoutubeSearch = require '../youtubeSearch'

  class VideoPanel extends BaseShapePanel
    events: _.extend {}, BaseShapePanel::events,
      'click .js-upload'     : 'upload'
      'click .js-youtube'    : 'showYoutubeSearch'
      'click @ui.interval'   : -> @shapeView.startEditInterval()
      'click .js-apply'      : -> @model.finishChanges()
      'click .js-cancel'     : -> @shapeView.stopEditInterval()

    ui: _.extend {}, BaseShapePanel::ui, 
      imagePreview: '.js-imagePreview'
      noimage     : '.js-noimage'
      imageContainer: '.js-imageContainer'
      previewIcon    : '.js-preview-icon' 
      interval : '.js-interval'

    modelEvents: _.extend {}, BaseShapePanel::modelEvents, 
      'change:file change:previewFile' : 'showVideoPreview'
      'change:intervalMode' : 'updateIntervalMode'

    onRender: ->
      super
      @updateIntervalMode()
      @ui.interval.css display: 
        if @model.get('videoType')? then 'inline-block' else 'none'
      @ui.previewIcon.addClass 'editor-video-insert'
      @showVideoPreview()
      @initCheckbox 'autoplay'
      @initBorder()

    updateIntervalMode: ->
      intervalMode = !! @model.get 'intervalMode'
      @ui.applyButtons.toggle     intervalMode
      @ui.controlButtons.toggle not intervalMode

    upload: ->
      openFile(accept: "video/*").then ([file]) =>
        @model.uploadVideo file

    showYoutubeSearch: ->
      YoutubeSearch.showYoutubeSearch {@controller, @model}

    showVideoPreview: ->
      file = @model.getPreviewImageFile()
      hasFile = file?
      @ui.imagePreview.toggle hasFile
      @ui.noimage.toggle not hasFile
      if hasFile
        @ui.imageContainer.empty().append ($('<img/>')
          .attr('src', file.original)
          .css 'width', '100%'
        )
        @ui.imageContainer.css 'position','static'
