define (require) ->
  BaseShapePanel = require './baseShapePanel'
  Constants = require '../../constants'



  class TextPanel extends BaseShapePanel
    
    events: _.extend {}, BaseShapePanel::events, 
      mousedown: (e) -> e.preventDefault()
      'click @ui.stretch' : -> @shapeView.stretch()

    ui: _.extend {}, BaseShapePanel::ui,
      textColor: '.js-textColor'
      stretch: '.js-stretch'
    
    modelEvents: _.extend {}, BaseShapePanel::modelEvents, 
      'change:editing' : 'toggleEditing'

    serializeData: -> _.extend super, 
      fontSizeOptions: for i in [0..15]
        i*Constants.FONT_SIZE_STEP + Constants.DEFAULT_FONT_SIZE

    # TODO strikeThrough, light
    onRender: ->
      @initBorder()
      @addToggleButton 'bold'
      @addToggleButton 'italic'
      @addToggleButton 'underline'
      @initJustify()
      @initFontSize()
      @initColor()
      @initOpacity()
      @initLists()
      @initStyles()
      @toggleEditing()

    toggleEditing: ->
      editing = !! @model.get 'editing'
      @$('.js-deepEditPanel').toggle editing
      @$('.js-commonEditPanel').toggle not editing
      @ui.stretch.css 'display', if editing then 'inline-block' else 'none'
      @ui.maximize.css 'display', unless editing then 'inline-block' else 'none'

    addToggleButton: (attr) ->
      button = @$(".js-#{attr}")
      currentState = undefined
      toggleActive = ->
        button.toggleClass 'active', currentState
      button.on 'click', =>
        currentState = !currentState
        @shapeView.execCommand attr
        toggleActive()
      @listenTo @shapeView, 'change:textSelection', =>
        currentState = document.queryCommandState attr
        toggleActive()

    initColor: ->
      initialColor = undefined
      showTextColor = (color) =>
        @ui.textColor.css 'background-color', color
      @listenTo @shapeView, 'change:textSelection', =>
        showTextColor @shapeView.getCurrentColor()
      setTextColor = (color) =>
        unless color?
          @shapeView.execCommand 'removeFormat', 'foreColor'
        else
          @shapeView.execCommand 'ForeColor', color, styleWithCss: true
      @initColorPicker @ui.textColor,
        currentColor: => initialColor = @shapeView.getCurrentColor()
        onOpen: ->
        onColorChange: (color) => 
          setTextColor color
        onApply: ->
        onCancel: ->
          setTextColor initialColor
          showTextColor initialColor

    initLists: ->
      buttons = {}
      attrs = ['insertOrderedList', 'insertUnorderedList']
      toggleActive = ->
        attrs.forEach (attr) ->
          buttons[attr].toggleClass 'active', document.queryCommandState attr
      attrs.forEach (attr) =>
        (buttons[attr] = @$(".js-#{attr}")).click (e) =>
          @shapeView.execCommand attr
          toggleActive()
        @listenTo @shapeView, 'change:textSelection', toggleActive

    initJustify: ->
      buttons = @$('.js-justify')
      currentJustify = undefined
      attrs = ['justifyLeft','justifyRight','justifyCenter','justifyFull']
      toggleActive = ->
        buttons.removeClass 'active'
        @$(".js-#{currentJustify}").addClass 'active'
      attrs.forEach (justify) =>
        @$(".js-#{justify}").on 'click', (e) =>
          @shapeView.execCommand justify
          currentJustify = justify
          toggleActive()
      @listenTo @shapeView, 'change:textSelection', =>
        for justify in attrs
          if document.queryCommandState justify
            currentJustify = justify
            toggleActive()

    initStyles: ->
      buttons = {}
      toggleActive = =>
        currentTheme = @shapeView.getCurrentTheme()
        for theme in Constants.TEXT_THEMES
          buttons[theme].toggleClass 'active', theme is currentTheme
      Constants.TEXT_THEMES.forEach (theme) =>
        (buttons[theme] = @$(".js-#{theme}")).click => 
          @shapeView.setTextTheme theme
      @listenTo @shapeView, 'change:textSelection', toggleActive

    initFontSize: ->
      preserveList = false
      fontSizeEl = @$('.js-fontSize')
      fontSizeCont = @$('.js-fontSizeCont')
      fontSizePopup = @$('.js-sizePopup')
      fontSizePopup.hide()
      toggleList = (show) =>
        fontSizeCont.toggleClass 'active', show
        fontSizePopup.toggle show
      fontSizeEl.click =>
        toggleList true
      @$el.find('.js-fontSizeOption').on 'click', (e) =>
        preserveList = true
        fs = parseInt $(e.target).attr('data-fontSize')
        @shapeView.setFontSize fs
        fontSizeEl.val fs + 'px'
      @listenTo @shapeView, 'change:textSelection', => 
        fontSizeEl.val Math.round(@shapeView.getCurrentFontSize()) + 'px'
        unless preserveList
          toggleList false 
        preserveList = false
