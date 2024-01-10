define (require) ->
  Constants = require './constants'

  class GoogleAPI

    loadYoutubePlayerAPI: ->
      if @youtubeAPIDef?
        @youtubeAPIDef
      else
        @youtubeAPIDef = $.Deferred()
        window.onYouTubeIframeAPIReady = =>
          @youtubeAPIDef.resolve()
          delete window.onYouTubeIframeAPIReady
        require ["https://www.youtube.com/iframe_api"]
        @youtubeAPIDef

    loadGoogleAPI: ->
      unless @googleApiLoaded
        callbackName = 'onGoogleClientAPILoaded'
        url = 'https://apis.google.com/js/client.js'
        window[callbackName] = ->
          delete window[callbackName]
          gapi.client.setApiKey Constants.GOOGLE_API_KEY
          gapi.client.load 'youtube', 'v3', ->
          gapi.client.load 'customsearch', 'v1'
        require ["#{url}?onload=#{callbackName}"]
        @googleApiLoaded = true
  
  new GoogleAPI
