define ->
  ->
    launchNano = ->
      nano = $('.nano')
      hasContent = !!nano.find('.content').length

      if hasContent
        nano.nanoScroller
          paneClass: 'pane'
          contentClass: 'content'
          sliderClass: 'slider'
          disableResize: true

    setInterval launchNano, 200
