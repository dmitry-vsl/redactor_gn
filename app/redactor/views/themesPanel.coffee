define (require) ->
  ItemView = require 'base/itemView'
  Constants = require '../constants'


  class ThemesPanel extends ItemView
    className: 'panel customize'
    template:  'redactor.themes'
    templateHelpers: {THEMES: Constants.THEMES}

    events: 
      'click .js-closePanel' : -> 
        @controller.showShapePanel()

    initialize: ({@controller}) ->

    onRender: ->
      @hidePopups()
      ['color','font'].forEach (prop) =>
        @updateTheme prop
        @$el.on "click", ".js-#{prop}", =>
          @hidePopups()
          @$(".js-#{prop}-popup").show()
          @$(".js-#{prop}").addClass 'active'
        @$el.on 'click', ".js-#{prop}-item", (e) =>
          themeIndex = parseInt $(e.currentTarget).attr 'data-themeIndex'
          theme = Constants.THEMES[prop][themeIndex]
          @model.setTheme prop, theme
        @listenTo @model, 'change:theme', => @updateTheme prop

    updateTheme: (prop) ->
      index = undefined
      theme = @model.getTheme()[prop]
      for t,i in Constants.THEMES[prop]
        if _.isEqual t, theme
          index = i
          break
      @$(".js-#{prop}-item").removeClass('current').eq(index).addClass 'current'
      
      switch prop
        when 'color'
          @$(".js-color-theme-name").text theme.name
          for colorType in ['header','content','border','fill','background']
            @$(".js-color-preview-#{colorType}").css 'background', theme[colorType]
          @$(".js-color-theme-name").css 'color', theme.header
          @$(".js-font-color-header").css 'color', theme.header
          @$(".js-font-color-content").css 'color', theme.content
        when 'font'
          @$(".js-font-preview-header").text(theme.header).css 'font-family', 
            theme.header
          @$(".js-font-preview-content").text(theme.content).css 'font-family', 
            theme.content

    hidePopups: ->
      @$(".js-color-popup,.js-font-popup").hide()
      @$(".js-color,.js-font").removeClass 'active'
