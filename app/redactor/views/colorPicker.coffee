define (require) ->
  ItemView = require 'base/itemView'
  Constants = require '../constants'
  require 'colpick'


  class ColorPicker extends ItemView
    template: 'redactor.colorPicker'
    className: 'popup color'
    events: 
      'click .js-apply' : -> @close() ; @onApply()
      'click .js-cancel' : -> @close(); @onCancel()
      'click @ui.picker' : 'showPicker'
    ui: 
      picker: '.js-picker'

    initialize: ({@currentColor,@onColorChange,@onApply,@onCancel}) ->

    setColor: (@currentColor) ->
      @onColorChange @currentColor

    onRender: ->
      addColorButtons = (el, colors) =>
        @$(el).append $("<div class='color-item transparent'/>").click =>
          @setColor null
        @$(el).append colors.map (color) =>
          $("<div class='color-item'/>")
          .css('background', color)
          .click => 
            @setColor color
            @picker?.colpickSetColor color

      addColorButtons '.js-palette', Constants.PALETTE

    showPicker: ->
      unless @picker?
        @picker = @ui.picker.empty().colpick 
          layout: 'hex'
          flat: true
          onChange: (hsb,hex) => @setColor '#' + hex
      @picker.colpickSetColor @currentColor
