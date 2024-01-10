define (require) ->
  BaseVideo = require './baseVideo'



  class LocalVideo extends BaseVideo
    serializeData: ->
      _.extend super,
        youtube: false
        src: @model.getLocalVideoSrc()

    ui: _.extend {}, BaseVideo::ui, 
      video: 'video'

    renderPlayer: ->
      @initPlaybackEventListeners();
      onMetadataReady = =>
        if !@controlsInited
          @initIntervalData();
          @initControls();
          @controlsInited = true;
        @renderMetadata()
        
      player = @ui.video;
      if player[0].readyState > 0 # 0 - HAVE NOTHING, 1 - HAVE METADATA
        onMetadataReady();
      else
        player[0].addEventListener('loadedmetadata', onMetadataReady);

    onRender: ->
      super
      unless @previewMode
        @ui.video.on 'ended', =>
          @onVideoEnded();      
    
    pauseVideo:(noHideControls) ->
      @ui.video[0].pause();
      unless noHideControls
        @ui.playBt.show();
        @ui.pauseBt.hide();

    playVideo: ->
      @ui.video[0].play();
      @ui.playBt.hide();
      @ui.pauseBt.show();      

    stopVideo: ->
      @pauseVideo();
      

    initPlaybackEventListeners: ->
      player = @ui.video;
      player.on('timeupdate', @handlePlaybackProgress);
        
    getRealPlaybackTime: (precision)->
      if precision
        @ui.video[0].currentTime;
      else
        +@ui.video[0].currentTime.toPrecision(precision);

    getDuration: (whole)->
      player = @ui.video[0];
      if whole
        player.duration
      else
        @model.getIntervalDuration();

    seekTo: (seconds)->
      seconds = @calculateSecondsWithShift(seconds) 
      @ui.video[0].currentTime = seconds;
      
    detachAllPlayerEvents: ->
      @ui.video.off('timeupdate', @handlePlaybackProgress)

    saveCurrentPlaybackState: ->
      pState = if @ui.video[0].paused then 'paused' else 'playing'
      @model.set "savedPlaybackState", pState

    restorePlaybackState: ->
      pState = @model.get "savedPlaybackState"
      if pState is 'playing'
        if @ui.video[0].ended is false
          @playVideo();
        else
          @onVideoEnded();
          
    isPaused: ->
      @ui.video[0].paused
