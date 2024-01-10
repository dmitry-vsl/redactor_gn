define (require) ->
  ItemView = require 'base/itemView'
  ColorPicker = require '../colorPicker'
  Utils = require 'utils/utils'


  class BaseShapePanel extends ItemView
    className: 'panel settings'

    serializeData: -> {}

    modelEvents: {}

    events:
      'click .js-duplicate' : -> @model.duplicate()
      'click .js-delete'    : -> @model.remove()
      'click  @ui.maximize' : -> @model.maximize()
      'click .js-closePanel': -> @model.set 'selected', false

    ui: 
      imagePreview   : '.js-imagePreview'
      noimage        : '.js-noimage'
      imageContainer : '.js-imageContainer'
      previewIcon    : '.js-preview-icon' 
      maximize       : '.js-maximize'
      applyButtons   : '.js-applyButtons'
      controlButtons : '.js-controlButtons'

    initialize: ({@pageView,@controller}) ->
      @shapeView = @pageView.children.findByModel @model
      @template = "redactor.shapePanels.#{@model.get('type')}"

    onRender: ->

    initOpacity: ->
      @initSlider 'opacity',
        formatText: (val) -> Math.round(val*100) + '%'
        maxValue: 1
    
    initCheckbox: (attr) ->
      el = @$(".js-#{attr}")
      el.on 'click', => 
        @model.setAndCommit attr, not @model.get attr
      updateEl =  => 
        el.prop 'checked', @model.get attr
      updateEl()
      @listenTo @model, "change:#{attr}", =>
        updateEl()

    initSlider: (attr,{formatText,maxValue}) ->
      el = @$(".js-#{attr}")
      textEl = el.find '.js-slider-text'
      stripeEl = el.find '.js-slider-stripe'
      updateEl =  => 
        textEl.html formatText @model.get attr
        stripeEl.width @model.get(attr)/maxValue*100 + '%'
      updateEl()
      @listenTo @model, "change:#{attr}", =>
        updateEl()
      el.slider
        start: => @model.startChanges()
        slide: (event,ui) =>  @model.set attr, ui.value/100*maxValue
        change: (event,ui) => @model.commitChanges()

    initColorPicker: (el,{
      onColorChange,
      onOpen,
      onApply,
      onCancel,
      currentColor,
    })->
      colorPicker = undefined
      el.click (e) =>
        if e.target isnt el[0]
          # filter clicks bubbled from color picker
          return
        if colorPicker?
          return
        onOpen()
        colorPicker = new ColorPicker({
          #TODO custom palette
          currentColor: currentColor(),
          onColorChange,
          onCancel: =>
            onCancel()
            colorPicker = undefined
          onApply: =>
            onApply()
            colorPicker = undefined
        }).render()
        el.append colorPicker.$el
        
      return closeColorPicker: ->
        colorPicker?.close()
        colorPicker = undefined
 
    initBorder: ->
      borderStyleButtons = {}
      updateBorderStyle = =>
        currentStyle = @model.get 'borderStyle'
        for borderStyle, button of borderStyleButtons
          button.toggleClass 'active', borderStyle is currentStyle
      ['dashed','solid','dotted'].forEach (borderStyle) =>
        (borderStyleButtons[borderStyle] = @$(".js-border-#{borderStyle}"))
        .click => 
          @model.setAndCommit {borderStyle}
        @listenTo @model, 'change:borderStyle', updateBorderStyle
      updateBorderStyle()

      borderControls = @$('.js-borderParam')
      toggleBorderControls = =>
        borderControls.toggle @model.get('hasBorder')
      @listenTo @model, 'change:hasBorder', toggleBorderControls
      toggleBorderControls()

      @initSlider 'borderWidth',
        maxValue: 50
        formatText: (val) -> Math.round(val) + 'px'

      @initCheckbox 'hasBorder'

      colorEl = @$('.js-color')
      updateBorderColor = =>
        borderColor = @model.get 'borderColor'
        if borderColor?
          colorEl.css 'background-color', borderColor
        else
          colorEl[0].style.removeProperty 'background-color'
      updateBorderColor()
      @listenTo @model, 'change:borderColor', updateBorderColor
      borderColorPicker = @initColorPicker colorEl,
        currentColor: =>
          @model.get 'borderColor'
        onOpen: =>
          @model.startChanges onFinishChanges: =>
            borderColorPicker.closeColorPicker()
            @model.commitChanges()
        onColorChange: (color) => 
          @model.set 'borderColor', color
        onApply: => 
          @model.finishChanges()
        onCancel: => 
          @model.rollbackChanges()
