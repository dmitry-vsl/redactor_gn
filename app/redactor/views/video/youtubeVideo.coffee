define (require) ->
  BaseVideo = require './baseVideo'
  googleAPI = require '../../googleAPI'


  SEEK_TIMEOUT = 150
  REQUEST_INTREVAL = 1000
        
  class YoutubeVideo extends BaseVideo
    
    serializeData: ->
      _.extend super,
        youtube: true

    ui: _.extend {}, BaseVideo::ui, 
      video: '.js-video'

    eventsToReactions = 
      'click .js-pauseBt' : ->
        @pauseVideo();
    readonlyEvents: _.extend {}, BaseVideo::readonlyEvents,
      eventsToReactions

    events: _.extend {}, BaseVideo::events,
      eventsToReactions
    

    initialize: ->
      super
      @playerReadyDef = $.Deferred()
      @seekTimeoutId = null
      @seekInitialized = false;
      @inited = false;
      @stateChangeHandlers = [];
      
    renderPlayer: ->
      @setOverlay();
      googleAPI.loadYoutubePlayerAPI().then =>
        @pausedStates = [YT.PlayerState.UNSTARTED, YT.PlayerState.PAUSED, 
                         YT.PlayerState.CUED, YT.PlayerState.ENDED, YT.PlayerState.BUFFERING]
        playerElId = "video-#{@model.id}"
        @ui.video.attr 'id', playerElId
        @youtubePlayer = new YT.Player playerElId,
          videoId: @model.get 'youtubeId'
          playerVars: 
            loop: 0
          events:
            onStateChange: (e)=>
              stateId = e.data;
              eventName = "stateChangedTo";
              switch stateId
                when YT.PlayerState.PLAYING then eventName += "Playing"
                when YT.PlayerState.PAUSED then eventName += "Paused"
                when YT.PlayerState.ENDED then eventName += "Ended"
                when YT.PlayerState.UNSTARTED, YT.PlayerState.CUED then eventName+= "Unavailible"
                else return;
              @trigger eventName;
              
            onReady: =>
              if not @inited
                @playerReadyDef.resolve();
                @initIntervalData();
                @initControls();
                @renderMetadata();
                @subscribeOnPlaybackStateChangeEvents();
                @inited = true;
              @makePlayerAvailableForSeek();
              
    _finilizeSeekAvailability: (stateId)=>
      @youtubePlayer.pauseVideo();
      @youtubePlayer.setVolume(100);
      @seekInitialized = true;
              
    makePlayerAvailableForSeek: ()=>
      if @seekInitialized is true
        return false;
      @youtubePlayer.playVideo();
      @youtubePlayer.setVolume(0);
      @once 'stateChangedToPlaying', @_finilizeSeekAvailability;
      
      
    subscribeOnPlaybackStateChangeEvents: ->
      @on 'stateChangedToPaused', @stopRequestingTimeUpdateInterval
      @on 'stateChangedToEnded', @onVideoEnded
      @on 'stateChangedToPlaying', @startRequestingTimeUpdateInterval
      @on 'stateChangedToPlaying', ()=>
        if @model.get("intervalMode")
          @youtubePlayer.pauseVideo();
      
    
    playVideo: ->
      @playerReadyDef.then =>
        if @seekInitialized is false
          @seekInitialized = true;
          @off 'stateChangedToPlaying', @_finilizeSeekAvailability;
          @youtubePlayer.setVolume(100);
        @youtubePlayer.playVideo();
        @ui.playBt.hide();
        @ui.pauseBt.show();
        @ui.preview.hide();

    stopVideo: ()->
      @playerReadyDef.then =>
        @pauseVideo();
        @ui.preview.show();
        
    pauseVideo: (noHideControls)->
      @youtubePlayer.pauseVideo();
      @stopRequestingTimeUpdateInterval();
      unless noHideControls
        @ui.playBt.show();
        @ui.pauseBt.hide();

    applyInterval: ->
      super;
      @setPinPositionFromSeconds(@pins.playbackMode.start, 0);
      
      
    getDuration: (whole)->
      if whole
        @youtubePlayer.getDuration();
      else
        @model.getIntervalDuration();
    
    _seekTo: (second)=>
      shiftedSeconds = @calculateSecondsWithShift(second);
      @youtubePlayer.seekTo(shiftedSeconds, true);
    
    seekTo: (seconds)->
      if @seekTimeoutId is null
        @_seekTo seconds
        @seekTimeoutId = 0;
      else
        clearTimeout @seekTimeoutId
        @seekTimeoutId = setTimeout =>
          @_seekTo seconds;
        , SEEK_TIMEOUT
      
    startRequestingTimeUpdateInterval: ()=>
      if @intervalSetted is true
        return false;
      @handlePlaybackProgress();
      @intervalId = window.setInterval(
        @handlePlaybackProgress,
        REQUEST_INTREVAL
      );
      @intervalSetted = true;
      
    stopRequestingTimeUpdateInterval: ()=>
      window.clearInterval(@intervalId);
      @intervalSetted = false;
      
    saveCurrentPlaybackState: ->
      pState = @youtubePlayer.getPlayerState();
      if pState in [YT.PlayerState.PLAYING, YT.PlayerState.PAUSED] 
        @model.set "savedPlaybackState", pState
      
    restorePlaybackState: ->
      pState = @model.get "savedPlaybackState"
      currentPstate = @youtubePlayer.getPlayerState();
      if pState is YT.PlayerState.PLAYING
        if currentPstate isnt YT.PlayerState.ENDED
          @playVideo();
        else
          @onVideoEnded();
      else if pState is YT.PlayerState.PAUSED && 
      currentPstate is YT.PlayerState.PLAYING
        @pauseVideo();

    detachAllPlayerEvents: ->
      clearInterval @intervalId
      clearTimeout @seekTimeoutId

    onPinDragEnd: (pin, mouseEvent)->
      super
      clearTimeout @seekTimeoutId;
      @seekTimeoutId = null;
      borderName = @determineBorderNameByPin pin;
      seconds = @getSecondsFromPercentage @processPinOffset(mouseEvent, borderName);
      @_seekTo seconds;

    isPaused: -> 
      if (@youtubePlayer.getPlayerState)
        return @youtubePlayer.getPlayerState() in @pausedStates 
      else
        return true;
      
    getRealPlaybackTime: (precision)->
      if precision
        +@youtubePlayer.getCurrentTime().toPrecision(precision);
      else
        @youtubePlayer.getCurrentTime()
      
    setOverlay: ->
      @overlay = $('<div>Overlay</div>')
      @overlay.addClass('js-overlay');
      @$el.append(@overlay);
      @overlay.css('height': '100%', 'height': '100%', 'opacity' : 0, 'cursor' : 'default');

    onClick: (e)=>
      target = e.target || e.srcElement;
      if @model.get("intervalMode") || !@overlay[0].contains target
        return false;
      if @isPaused() 
        @playVideo();
      else
        @pauseVideo()
      
    onVideoEnded: ->
      super
      unless @destroyed
        @youtubePlayer.playVideo();
        @youtubePlayer.stopVideo();
        @_seekTo 0;
    
    onClose: ->
      super
      @destroyed = true
      unless @readonly
        @youtubePlayer.destroy()
