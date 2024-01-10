define (require) ->
  PageModel = require './models/page'
  PageView = require './views/page'
  Theme = require './theme'


  
  Preview = 

    resetStyles: (el) ->
      el[0].style.removeProperty('background-color')
      el[0].style.removeProperty('background-image')
      el[0].style.removeProperty('background-size')
      for className in el.attr('class').split(' ')
        if className.indexOf('geenio-redactor') is 0
          el.removeClass className
    
    renderPagePreview: ({pageAttrs, presentationAttrs, container}) ->
      model = new PageModel pageAttrs, {previewMode: true, presentationAttrs}
      view = new PageView {model, previewMode: true}
      view.render()
      container.append view.$el
      view.onDomRefresh()
      view.scaleToFitContainer()

    renderPageInSelectLinkSourceMode: (attrs, container) ->
      pageModel = new PageModel attrs, playerMode: true
      pageView = new PageView {model: pageModel, selectLinkSourceMode: true}
      pageView.render()
      container.append pageView.$el
      pageView.onDomRefresh()
      pageView.scaleToFitContainer()
      pageModel

    renderPageInPlayer: (attrs, region, backgroundElement) ->
      pageModel = new PageModel attrs, 
        playerMode: true
        presentationAttrs: attrs.presentation
      pageView = new PageView 
        model: pageModel
        playerMode: true
        backgroundElement: backgroundElement

      pageModel.preloadImages().then =>
        region.show pageView
      pageModel
