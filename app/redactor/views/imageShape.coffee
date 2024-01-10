define (require) ->
  BaseShapeView = require './baseShape'
  Vector = require '../vector'
  require 'crop'



  class ImageView extends BaseShapeView

    serializeData: ->
      _.extend super,
        typeimage: true

    ui: _.extend {}, BaseShapeView::ui, 
      image: '#image'
      default: '.js-default'

    modelEvents: _.extend {}, BaseShapeView::modelEvents, 
      'change:file'  : 'updateFile'
      'change:cropping' : ->
        if @model.get 'cropping'
          @showCrop()
        else
          @cropRemove()

    initialize: ->
      super

    getSrc: ->
      file = @model.get 'file'
      file?.original

    updateFile: ->
      @drawImageBackground()

    onRender: ->
      super
      @updateFile()
      @on 'ok', ->
        if @model.get 'cropping'
          @model.finishChanges()
          false
      @on 'cancel', ->
        if @model.get 'cropping'
          @model.cancelCropping()
          false

    startMove: ->
      if @model.get 'cropping'
        return false
      else
        super

    updateSize: ->
      super
      @drawImageBackground()

    drawImageBackground: ->
      hasFile = @model.get('file')?
      @ui.default.toggle not hasFile
      @ui.image.toggle hasFile
      if hasFile
        @ui.image.css @getBackgroundCss()

    getBackgroundCss: ->
      scale = @model.get('size')[0] / @model.get('cropSize')[0]
      [bpx,bpy] = Vector.multiply @model.get('cropPosition'), -scale
      [bsx,bsy] = Vector.multiply @model.get('originalSize'), scale
      css = 
        backgroundImage    : "url(#{@getSrc()})"
        backgroundPosition : "#{bpx}px #{bpy}px"
        backgroundSize     : "#{bsx}px #{bsy}px"
        backgroundRepeat   : "no-repeat"
        backgroundClip     : "border-box"

    showCrop: ->
      self = @
      @toggleResizeControls false
      @model.saveOriginalPosition()
      @model.set 'size', @model.get('originalSize')
      @ui.image.hide()

      cropEl = $('<div class="gn-redactor-image-crop"></div>').css
        background: "url(#{@getSrc()})"
        backgroundSize: '100% auto'
      @$el.append cropEl
      cropEl.Jcrop {keySupport: false}, ->
        self.jcrop = @
        [x,y] = self.model.get('cropPosition')
        [w,h] = self.model.get('cropSize')
        @setSelect [x,y,w+x,h+y]

    cropRemove: ->
      @jcrop.destroy()
      delete @jcrop
      @toggleResizeControls true
      @ui.image.show()

    startCropping: ->
      @model.startChanges onFinishChanges: =>
        @crop()
        @model.set 'cropping', false
        @model.commitChanges()
      @model.set 'cropping', true

    crop: ->
      {x,y,w,h} = @jcrop.tellSelect()
      newSize = [w,h]
      @model.set 'cropSize', newSize
      @model.set 'cropPosition', [x,y]
      @model.set 'size', newSize
