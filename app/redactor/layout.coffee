define (require) ->
  Layout = require "base/layout"
  PageView = require './views/page'



  PANELS = [
    'googleSearch','shapePanel','themesPanel','layersPanel',
    'pagesPanel','youtubeSearch'
  ]

  class RedactorLayout extends Layout
    template: "redactor.layout"
    className: "redactor"

    regions:
      layersPanel:  '.js-layersPanel'
      shapePanel:   '.js-shapePanel' 
      googleSearch: '.js-googleSearch'
      youtubeSearch: '.js-youtubeSearch'
      page:         '.js-page'
      tools:        '.js-tools'
      themesPanel:  '.js-themesPanel'
      pagesPanel :  '.js-pagesPanel'

    onShow: ->
      for panel in PANELS
        @$(".js-#{panel}").hide()

    showPanel: (name) ->
      for panel in PANELS
        @$(".js-#{panel}").toggle panel is name

    hidePanel: (name) ->
      @$(".js-#{name}").hide()

    renderPage: ({controller,model}) ->
      container = @$ @page.el
      container[0].style = undefined
      pageView = new PageView {model, controller, backgroundElement: container}
      @page.show pageView
      pageView
