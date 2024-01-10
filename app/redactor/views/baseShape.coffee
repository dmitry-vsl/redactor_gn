define (require) ->
  ItemView = require 'base/itemView'
  Utils = require 'utils/utils'
  Vector = require '../vector'
  TouchToMouse = require '../touchToMouse'



  KEYCODE_TO_DIRECTION = 
    37 : [-1 , 0 ]
    38 : [ 0 , -1]
    39 : [ 1 , 0 ]
    40 : [ 0 , 1 ]

  ARROW_CODES = Object.keys KEYCODE_TO_DIRECTION

  class BaseShapeView extends ItemView
    className: 'gn-redactor-shape-container'

    serializeData: ->
      cornerControl: [
        {positionLeft:  0, positionTop: 0, positionClass: 'left-top'    }
        {positionLeft:  1, positionTop: 0, positionClass: 'right-top'   }
        {positionLeft:  0, positionTop: 1, positionClass: 'left-bottom' }
        {positionLeft:  1, positionTop: 1, positionClass: 'right-bottom'}
      ]
      
    events:
      'mousedown': 'handleMouseDown'
      'mousedown @ui.zoom': 'startZoom'
      'mousedown @ui.rotate': 'startRotate'

    readonlyEvents:
      'click' : 'clickInteractiveLink'

    modelEvents: 
      'change:rotate' : 'updateRotate'
      'change:position' : 'updatePosition'
      'change:size' : 'updateSize'
      'change:borderColor' : 'updateBorder'
      'change:borderWidth' : 'updateBorder'
      'change:hasBorder'   : 'updateBorder'
      'change:borderStyle' : 'updateBorder'
      'change:opacity' : 'updateOpacity'

    ui:
      border: '.js-border'
      zoom: '.js-zoom'
      rotate: '.js-rotate'
      shapeContent: '.shape-content'
      withBorder: '.js-withBorder'

    initialize: ({@page, @layerPreviewMode}) ->
      @template = 'redactor.shapes.' + @model.get('type')
      @transformProps = {}
      unless @layerPreviewMode
        @previewMode = @page.previewMode
        @selectLinkSourceMode = @page.selectLinkSourceMode
        @playerMode = @page.playerMode
        @readonly = @page.readonly
      else
        @readonly = true
        @previewMode = true

      if @playerMode
        @events = @readonlyEvents

      @events = TouchToMouse.wrapEventsHash @events

      if @previewMode
        @events = {}

      unless @readonly
        @listenTo @model, 'change:selected' , @displaySelection

    onRender: ->
      @updateRotate()
      @updateSize()
      @updatePosition()
      @updateBorder()
      @updateOpacity()
      @setCursor()

      unless @readonly
        @displaySelection()
      else
        @hideControls()

      if @layerPreviewMode
        @$el.css Utils.createVendorCss 'transform-origin', 'center'
        @$el.css 
          position: 'relative'
          left: '50%'
          top: '50%'

    isClickable: ->
      @model.get('link')? isnt !!@page.selectLinkSourceMode

    clickInteractiveLink: ->
      if @isClickable()
        @page.children.each (view) => 
          view.$el.toggleClass 'select-transition-source', view is @
        @model.interactiveLinkSelect()

    onDomRefresh: ->
      if @layerPreviewMode
        @fitToContainer()

    displaySelection: ->
      if @model.get 'selected'
        @showSelection()
      else
        @removeSelection()

    removeSelection: =>
      @hideControls()
      @unbindKeyHandlers()

    hideControls: ->
      @ui.border.hide()

    showSelection: =>
      @ui.border.show()
      @showRotateControl()
      @bindKeyHandlers()

    bindKeyHandlers: ->
      @page.keyHandler.subscribeBackspace (e) =>
        @model.remove()
        e.preventDefault()
      @page.keyHandler.subscribeDel (e) =>
        @model.remove()
      @page.keyHandler.subscribeEnter (e) => 
        @trigger 'ok', keyEvent: e
      @page.keyHandler.subscribeEsc => 
        @trigger 'cancel'

      $(window).on 'keydown.moveShape', (e) =>
        keyCodeStr = e.keyCode.toString()
        if keyCodeStr in ARROW_CODES
          Utils.repeatUntilKeyReleased
            action: => @model.moveByUnit KEYCODE_TO_DIRECTION[keyCodeStr]
            keyCode: e.keyCode
        true

    unbindKeyHandlers: ->
      $(window).off 'keydown.moveShape'
      @page.keyHandler.unsubscribeDel()
      @page.keyHandler.unsubscribeBackspace()
      @page.keyHandler.unsubscribeEnter()
      @page.keyHandler.unsubscribeEsc()

    updateSize: ->
      @$el.css Vector.toCssSize @model.get('size')
      if @layerPreviewMode
        @fitToContainer()

    updatePosition: ->
      unless @layerPreviewMode
        [left,top] = @model.get('position')
        @$el.css {left, top}

    updateRotate: ->
      @applyTransform rotate: "#{@model.get('rotate')}deg"

    toggleResizeControls: (show) ->
      @ui.zoom.toggle show
      if show
        @showRotateControl()
      else
        @ui.rotate.hide()

    setCursor: ->
      unless @playerMode
        @$el.css 'cursor', 'pointer'
      else
        videoInPlayer = @model.get('type') is 'video' and 
          not @selectLinkSourceMode
        if @isClickable() and not videoInPlayer
          @$('*').css cursor: 'pointer'
        else
          @$('*').css cursor: 'default'

    updateBorder: ->
      if @model.get('hasBorder')
        borderWidth =
          if @model.get('type') is 'text' 
            @model.getEffectiveBorderWidth()
          else
            @model.get('borderWidth')

        @ui.withBorder.css 
          borderWidth: borderWidth + 'px'
          borderStyle: @model.get 'borderStyle'

        borderColor = @model.get('borderColor')
        if borderColor?
          @ui.withBorder.css {borderColor}
        else
          @ui.withBorder.each (index,el) -> el.style.removeProperty 'border-color'
      else
        @ui.withBorder.css borderWidth: '0px'

    updateOpacity: ->
      @$('.shape-content').css 'opacity', @model.get('opacity')

    handleMouseDown: (event) ->
      if @model.getPage().focusedShape? and not @model.isFocused()
        return false
      @modelWasSelectedBeforeMove = @model.get 'selected'
      @model.select()
      @startMove {event}
      return false

    startMove: ({event}) ->
      @model.startChangesIfNotFocused()
      @model.saveOriginalPosition()
      @originalXY = [event.pageX, event.pageY]
      @page.onMouseEvent 'mousemove.moveshape', @processMove
      @page.onMouseEvent 'mouseup.moveshape', @finishMove

    processMove: (event) =>
      unless @moved
        @moved = true
      newXY = [event.pageX, event.pageY]
      diff = Vector.multiply Vector.subtract(newXY,@originalXY),
        1/@getZoom()
      @model.move diff

    finishMove: (event) =>
      @page.offMouseEvent 'mousemove.moveshape'
      @page.offMouseEvent 'mouseup.moveshape'
      if @moved
        @model.commitChangesIfNotFocused()
      else
        if @modelWasSelectedBeforeMove
          @onClick?(event)
      @moved = false

    startZoom: (event) ->
      @model.startChangesIfNotFocused()
      @model.saveOriginalPosition()
      zoomControl = $(event.target)
      @zoomDirection = [
        Number zoomControl.attr 'data-position-left'
        Number zoomControl.attr 'data-position-top'
      ]

      @originalXY = [event.pageX, event.pageY]
      @page.onMouseEvent 'mousemove.shape.zoom', @processZoom
      @page.onMouseEvent 'mouseup.shape.zoom', @finishZoom
      return false

    processZoom: (event) =>
      mouseMoveVector = Vector.subtract [event.pageX, event.pageY], @originalXY
      @model.scale {
        mouseMoveVector: Vector.multiply mouseMoveVector,1/@getZoom()
        @zoomDirection
      }

    finishZoom: =>
      @page.offMouseEvent 'mousemove.shape.zoom'
      @page.offMouseEvent 'mouseup.shape.zoom'
      @model.commitChangesIfNotFocused()
      return false

    startRotate: (event) ->
      @model.startChangesIfNotFocused()
      @model.saveOriginalPosition()

      mousePosition = [event.pageX, event.pageY]

      pageOffset = @page.ui.canvas.offset()
      @center = Vector.add Vector.multiply(@model.getCenter(),@getZoom()),
        Vector.fromCssPosition pageOffset

      @initialRotateVector = Vector.subtract mousePosition, @center
      
      @page.onMouseEvent 'mousemove.shape.rotate', @processRotate
      @page.onMouseEvent 'mouseup.shape.rotate', @finishRotate
      return false

    processRotate: (event) =>
      mousePosition = [event.pageX, event.pageY]

      currentRotateVector = Vector.subtract mousePosition, @center
      @model.rotate Vector.angle currentRotateVector, @initialRotateVector 

    finishRotate: (event) =>
      @showRotateControl()
      @page.offMouseEvent 'mousemove.shape.rotate'
      @page.offMouseEvent 'mouseup.shape.rotate',
      @model.commitChangesIfNotFocused()

    showRotateControl: ->
      @ui.rotate.hide()
      [left,top] = @model.getCornerOppositeToTop()
      @ui.rotate.each (i, el) =>
        $el = $ el
        if (parseInt $el.attr('data-position-left')) is left and 
        (parseInt $el.attr('data-position-top')) is top
          $el.show()

    applyTransform: (options) ->
      style = ''
      for prop in ['translate','scale','rotate']
        @transformProps[prop] = options[prop] if options[prop]?
        if @transformProps[prop]?
          style += "#{prop}(#{@transformProps[prop]}) "
      if style? and style isnt ''
        @$el.css Utils.createVendorCss 'transform', style 

    fitToContainer: ->
      unless @parent?
        parent = @$el.parent()
        if parent.size() is 0
          return
        @cWidth = parent.width()
        @cHeight = parent.height()
      scaleX = @cWidth / @model.get('size')[0]
      scaleY = @cHeight / @model.get('size')[1]
      scale = Math.min scaleX, scaleY

      @applyTransform 
        scale: "#{scale},#{scale}"
        translate: "#{-50}% , #{-50}%"

    getZoom: -> @page.zoom

    onClose: ->
      if not @readonly
        if @model.get('selected')
          @removeSelection()
        @unbindKeyHandlers()
