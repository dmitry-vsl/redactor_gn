define (require) ->
  BaseShapeView = require './baseShape'
  Vector = require '../vector'
  Constants = require '../constants'
  setEndOfContenteditable = require '../setEndOfContenteditable'
  Utils = require 'utils/utils'
  rgb2hex = require 'utils/rgb2hex'


  
  # TODO sanitize html
  class TextView extends BaseShapeView
    
    events: _.extend {}, BaseShapeView::events,
      'paste @ui.textbox': 'pastePlainText'
      'mousedown @ui.resize': 'startResize'

    serializeData: ->
      _.extend super,
        typetext: true

    modelEvents: _.extend {}, BaseShapeView::modelEvents,
      'updateModelHeight' : 'updateModelHeight'
      'change:scale' : -> 
        @updateScale()
        @updateBorder()
      'change:text' : 'updateText'
      'change:editing' : ->
        unless @readonly
          if @model.get('editing')
            @showTextEditing()
          else
            @hideTextEditing()

    ui: _.extend {}, BaseShapeView::ui,
      textbox: '.js-textbox'
      resize: '.js-resize'

    onRender: ->
      super
      @updateText()
      @ui.resize.hide()
      @updateScale()
      unless @readonly
        @on 'ok', ({keyEvent}) =>
          @startEditing()
          keyEvent.preventDefault()
        @ui.textbox.on 'keyup mouseup', =>
          if @model.get('editing')
            if @shouldSetFontSize
              @applyFontSize()
              @shouldSetFontSize = false
            @onTextUpdate()

      @ui.textbox.attr 'contenteditable', not @readonly
      @ui.textbox.css 'font-size', Constants.DEFAULT_FONT_SIZE

    onTextUpdate: ->
      @updateModelHeight()
      @model.set 'text', @ui.textbox.html(), silent: true
      @trigger 'change:textSelection'

    setFontSize: (fontSize) ->
      @fontSizeToBeApplied = fontSize / @model.get('scale')
      document.execCommand 'fontSize', false, 7
      if window.getSelection().type is 'Range'
        @applyFontSize()
        @onTextUpdate()
      else
        @shouldSetFontSize = true
        @trigger 'change:textSelection'

    applyFontSize: ->
      @ui.textbox.find('font[size=7]').each (index,el) =>
        $(el).removeAttr('size').css 'fontSize', @fontSizeToBeApplied

    setTextTheme: (theme) ->
      if theme is 'header'
        @execCommand 'formatBlock', 'h1'
      else
        @execCommand 'formatBlock', 'p'

    handleMouseDown: (event) ->
      if @model.get('editing')
        event.stopPropagation()
      else
        super

    onClick: ->
      if (@model.get 'selected') and not @model.get('editing')
        @startEditing()

    startEditing: ->
      @model.set 'editing', true
      @model.startChanges onFinishChanges: =>
        @model.set 'editing', false
        @model.commitChanges()

    updateText: ->
      @ui.textbox.html @model.get('text')

    updateBorder: ->
      super
      @updateModelHeight()

    updateScale: ->
      scale = @model.get 'scale'
      @ui.textbox.css Utils.createVendorCss 'transform', 
        "scale(#{scale},#{scale})"

    showTextEditing: ->
      @$el.css 'cursor', 'text'
      @unbindKeyHandlers()
      @page.keyHandler.subscribeEsc => @model.finishChanges()

      @toggleResizeControls false
      @ui.resize.show()
      @ui.border.addClass 'active-text-border'
      @ui.textbox[0].focus()
      setEndOfContenteditable @ui.textbox[0]
      @trigger 'change:textSelection'

    hideTextEditing: ->
      window.getSelection().removeAllRanges()
      @setCursor()
      @ui.textbox.blur()
      @ui.border.removeClass 'active-text-border'
      @toggleResizeControls true
      @ui.resize.hide()
      @page.keyHandler.unsubscribeEsc()
      @bindKeyHandlers()

    getCurrentElement: ->
      el = window.getSelection().anchorNode
      if el.nodeType is 3
        el = el.parentNode  
      el

    getCurrentColor: ->
      rgb2hex $(@getCurrentElement()).css 'color'

    getCurrentTheme: ->
      contentTags = ['div','p']
      headerTags  = ['h1']
      themeTags = contentTags.concat headerTags
      el = @getCurrentElement()
      loop 
        tagName = el.tagName.toLowerCase()
        if tagName in themeTags
          return if tagName in contentTags then 'content' else 'header'
        else
          el = el.parentNode

    getCurrentFontSize: ->
      el = @getCurrentElement()
      while isNaN parseInt el.style.fontSize
        el = el.parentNode
      parseFloat(el.style.fontSize)*@model.get('scale')

    execCommand: (command,argument,options={}) ->
      styleWithCss = options.styleWithCss ? false
      document.execCommand 'styleWithCss', false, styleWithCss
      document.execCommand command, false, argument
      @onTextUpdate()

    pastePlainText: (e) ->
      text = e.originalEvent.clipboardData.getData('text/plain')
      @execCommand 'insertText', text
      false

    updateModelHeight: ->
      if not @readonly and document.contains @$el[0]
        newSize = [
          @model.get('size')[0]
          @ui.textbox.outerHeight()*@model.get('scale')
        ]
        @model.set 'size', newSize, silent: true
        @$el.css height: @model.get('size')[1]
        @setTextBoxWidth()

    startResize: (event) ->
      @model.saveOriginalPosition()
      @originalXY = [event.pageX, event.pageY]
      @page.onMouseEvent 'mousemove.shape.resize', @processResize
      @page.onMouseEvent 'mouseup.shape.resize', @finishResize
      return false

    processResize: (event) =>
      newXY = [event.pageX, event.pageY]
      diff = Vector.multiply Vector.subtract(newXY,@originalXY), 1/@getZoom()
      @model.resize diff
      @updateModelHeight()

    stretch: ->
      @model.saveOriginalPosition()
      @model.fitWidthToPage()
      @updateModelHeight()
      @model.restoreVerticalCenter()

    updateSize: ->
      super
      @setTextBoxWidth()

    setTextBoxWidth: =>
      @ui.textbox.outerWidth @model.get('size')[0]/@model.get('scale')

    finishResize: (event) =>
      @page.offMouseEvent 'mousemove.shape.resize'
      @page.offMouseEvent 'mouseup.shape.resize'
      @model.saveState()
      return false
