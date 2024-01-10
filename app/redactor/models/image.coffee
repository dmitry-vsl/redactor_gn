define (require) ->
  Shape = require './shape'
  Vector = require '../vector'



  class Image extends Shape
    defaults: _.extend {}, Shape::defaults,
      size: [200, 200]

    setGoogleImage: (image) ->
      @setImage image

    applyGoogleImage: ->
      if @hasUncommitedChanges()
        @setImage @get 'file'
        @commitChanges()

    uploadImage: (file) ->
      @startChanges()
      @getPage().uploadFile(file,{type:'image'}).then (file) =>
        @setImage file
        @saveState()

    setImage: (file) ->
      @setSizePreservingWidthAndCenter [file.width,file.height]
      @set 
        cropSize:     @get('size')
        originalSize: @get('size')
        cropPosition: [0,0]
        file:         file
 
    cancelCropping: ->
      @rollbackChanges()
      @set 'cropping', false
