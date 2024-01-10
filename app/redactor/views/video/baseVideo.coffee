define (require) ->
  BaseShapeView = require '../baseShape'
  Vector = require '../../vector'



  class VideoView extends BaseShapeView
      
    initialize: ()->
      super
      @currentInterval=
        startSeconds : null
        endSeconds: null

      @pins=
        intervalMode:
          start: null
          end: null
        playbackMode:
          start: null
      
    pinTpl: $('<div class="round-control">
              <div class="round-inner"></div></div>')
    
    eventToReaction =  
      'click .js-play' : 'play'
      'click .js-playBt' : 'playVideo'
      'click .js-pauseBt' : 'stopVideo'
      'mousedown .js-timeline' : 'handleClickTimebar' 
      'mousedown .js-end-of-timeline' : 'handleClickTimebar' 
    
    events: _.extend {}, BaseShapeView::events, 
      eventToReaction

    intervalBorderNames: ['startSeconds', 'endSeconds']
    readonlyEvents: _.extend {}, eventToReaction

    serializeData: ->
      _.extend super,
        typevideo: true
        previewMode: @previewMode
        previewSrc: @getPreviewSrc()

    ui: _.extend {}, BaseShapeView::ui, 
      video: '.js-video'
      preview: '.js-preview'
      play: '.js-play'
      intervalControlsContainer: '.js-intervalControlsContainer'
      intervalTimelineContainer: '.js-timeline'
      timeLine : '.js-videoTimeline'
      intervalTimeline : '.js-interval'
      playBt: '.js-playBt'
      pauseBt: '.js-pauseBt'
      playbackTimeContainer : ".js-playbackTimeContainer"
      currentTimeContainer: '.js-currentTime'
      wholeTimeContainer: '.js-wholeTime'
      intervalTimeContainer : ".js-intervalTimeContainer"
      intervalTimeStart : ".js-intervalModeTimeStart"
      intervalTimeEnd : ".js-intervalModeTimeEnd"
      positionHelper : ".js-position-helper"
      playbackModeControls : "[data-hook-mode='playback']"
      intervalModeControls : "[data-hook-mode='interval']"

    startEditInterval: ->
      @enterIntervalMode()
      @model.startChanges onFinishChanges: =>
        @applyInterval()
        @model.commitChanges()

    stopEditInterval: ->
      @exitIntervalMode()
      @model.rollbackChanges()

    onRender: ->
      super
      unless @readonly
        @on 'ok', =>
          if @model.get('intervalMode')
            @startEditInterval()
        @on 'cancel', =>
          if @model.get('intervalMode')
            @stopEditInterval()
        
      if @selectLinkSourceMode
        @$el.on 'click', => @clickInteractiveLink()

      if @previewMode or @selectLinkSourceMode
        @ui.play.hide()
      else
        @ui.preview.show()
        @changeControlsMode(true);
        unless @playerMode
          @registerModelEvents();
        else
          

    onDomRefresh: ->
      super
      unless @previewMode
        @renderPlayer()

      if @playerMode and not @selectLinkSourceMode and @model.get 'autoplay'
        @play()

    getPreviewSrc: ->
      file = @model.getPreviewImageFile()
      file.original

    showPreview: ->
      @ui.preview.show()
      @stopVideo()

    hidePreview: ->
      @ui.preview.hide()

    removeSelection: ->
      super
      @showPreview()

    updateBorder: ->
      super
      @ui.shapeContent.css 'background', 
        if (@model.get('hasBorder')) 
          @model.get 'borderColor'
        else
          'transparent'
 
    onPause: =>
      unless (@playerMode and @not selectLinkSourceMode) or 
                            @model.get("intervalMode")
        @showPreview()

    play: ->
      @playVideo()
      @hidePreview()
 
    exitIntervalMode: ->
      if @model.get "intervalMode"
        @model.set "intervalMode", false;
        @changeControlsMode true;
        @setPinPositionFromSeconds @pins.playbackMode.start, 0
        @seekTo 0
        @setCurrentTime 0
      
      
    enterIntervalMode: ->
      @model.set "intervalMode", true;
      @stopVideo();
      @changeControlsMode false;
      @hidePreview();
      @seekTo @model.get "startSeconds"
      @setCurrentIntervalBorderValue(@pins.intervalMode.start, 
        @model.get("startSeconds"))
      @setCurrentIntervalBorderValue(@pins.intervalMode.end, 
        @model.get("endSeconds"))

    applyInterval: ->
      @model.applyInterval @currentInterval.startSeconds, 
        @currentInterval.endSeconds
      @reRenderPlayer();
      @exitIntervalMode()
      
    reRenderPlayer: ->
      @renderMetadata()
      
    changeControlsMode: (playbackOrInterval) ->
      @ui.playbackModeControls.toggle playbackOrInterval
      @ui.intervalModeControls.toggle !playbackOrInterval      
      
    setCurrentIntervalBorderValue: (pin, value)->
      borderName = @determineBorderNameByPin(pin);
      @currentInterval[borderName] = value;
      @showIntervalBorderValue pin, value
      pin[0].style.left = @getPercentageFromSeconds(value, true) + '%'
      @setIntervalWidth();
        
    changeIntervalBorderValue: (borderName, value)->
      pin = @pins.intervalMode[if borderName is 'startSeconds' then 'start' else
        'end']
      @setCurrentIntervalBorderValue(pin, value);
      
    getCurrentPlaybackTime: ->
      startSeconds = @model.get "startSeconds"
      time = @getRealPlaybackTime();
      time - startSeconds
      
      
    addPin: (seconds, purpose)->
      pin = @pinTpl.clone();
      @ui.intervalTimelineContainer.append(pin);      
      if not @pinWidth
        @pinWidth = pin.width();
      if seconds?
        position = @model.getPercentage seconds, @getDuration(true)
      else
        position = 100
      
      pin.css left : position + '%'
      if purpose
        @ui.intervalModeControls = @ui.intervalModeControls.add(pin);
        @pins.intervalMode[purpose] = pin
        pinDragCb = @onIntervalPinDrag;
      else
        @ui.playbackModeControls = @ui.playbackModeControls.add(pin);
        @pins.playbackMode["start"] = pin
        pinDragStartCb = ()=>
          @saveCurrentPlaybackState();
          @pauseVideo(true);
        pinDragCb = @onPlaybackPinDrag;
        dragEndCb = (pin, e)=>
          @restorePlaybackState();
      
      @attachDragEventsToPin(pin, pinDragStartCb, pinDragCb, dragEndCb);
      return

    setPinPositionFromSeconds: (pin, seconds, wholeDuration)->
      pos = @model.getPercentage(seconds, @getDuration(wholeDuration));
      pin.css "left" : pos+= '%'
      unless wholeDuration
        @ui.timeLine.css "width" : pos

    getSecondsFromPercentage: (percent, wholeOrInterval)->
      _duration = @getDuration(wholeOrInterval);
      @model.getValueFromPercentage percent, _duration

    getPercentageFromSeconds: (seconds, wholeOrNot)->
      duration = @getDuration(wholeOrNot);
      @model.getPercentage seconds, duration

    attachDragEventsToPin: (pin, dragStartCb, dragCb, dragEndCb) ->
      onCatchDragStart = (e)=>
        @onPinDragStart(pin, dragCb, dragEndCb);
        if dragStartCb
          dragStartCb();
        pinPos = pin.offset();
        now = [e.pageX, e.pageY]
        diff = Vector.subtract now, [pinPos.left,pinPos.top]
        @deltaXVector = Vector.rotate diff, @model.get "rotate"
        pos = @ui.positionHelper.offset()
        @startCoords = [pos.left, pos.top]
        
      catchStartDrag = (e)=>
        onCatchDragStart(e)
        @changePinVisualState(pin, true);
        e.preventDefault();
        e.stopPropagation();
        return false;
        
      pin[0].onmousedown = catchStartDrag;
      pin[0].onclick = (e)->
        e.preventDefault();
        e.stopPropagation();
        e.returnValue = false;
        return false;
      return;
      
    processPinOffset: (mouseEvent, borderName)->
      currentMouseVector = [mouseEvent.pageX, mouseEvent.pageY];
      offset = Vector.subtract Vector.subtract(currentMouseVector,@startCoords),
        @deltaXVector
      width = @getTimeLineWidth();
      realOffset = @model.processRotatedOffset offset, min : 0, max : width;  
      leftOffset = @model.getPercentage realOffset, width;
      seconds = @getSecondsFromPercentage leftOffset, if borderName then true 
      else false
      if borderName
        seconds = @ensureRestrictionPass borderName, seconds
      @getPercentageFromSeconds seconds, if borderName then true else false
      
    ensureRestrictionPass: (borderName, seconds)->
      invertedBorderName = startSeconds :'endSeconds',endSeconds:'startSeconds'
      if borderName is 'startSeconds' then cmpf = Math.min else cmpf = Math.max
      cmpf @currentInterval[invertedBorderName[borderName]], seconds
        
    showIntervalBorderValue: (pin, value) ->
      valueContainer = @ui.intervalTimeContainer.find(
        "[data-hook=#{@determineBorderNameByPin pin}]"
      );
      valueContainer.text(@model.transformTime value);
        
    setIntervalWidth: ()->
      stT = @ui.intervalTimeline[0].style;
      duration = @getCurrentIntervalWidth();
      width = @getPercentageFromSeconds duration, true
      left = @getPercentageFromSeconds @currentInterval['startSeconds'], true
      stT.width = width + '%';
      stT.left = left+'%'

    getCurrentIntervalWidth: ()->
      @currentInterval['endSeconds'] - @currentInterval['startSeconds']

    setCurrentTime: (seconds)->
      time = @model.transformTime seconds;
      @ui.currentTimeContainer.text(time);      
      

    calculateSecondsWithShift: (seconds)->
      previewModeShift = if @model.get "intervalMode" then 0 
      else @model.get "startSeconds" 
      seconds + previewModeShift 

    renderMetadata: ->
      @setCurrentTime(0);
      @ui.wholeTimeContainer.text(@model.transformTime @getDuration());    
    
    initIntervalData: ->
      if(start = @model.get "startSeconds") is null
        start = @getDefaultBorderValue "startSeconds"
        @model.set "startSeconds", start, silent:true 
      if(end = @model.get "endSeconds") is null
        end = @getDuration(true);
        @model.set "endSeconds", end, silent:true
      @currentInterval.startSeconds = start
      @currentInterval.endSeconds = end
      
    initControls: ->
      unless @previewMode
        @addPin(0);
        @addPin(@currentInterval.startSeconds, 'start');
        @addPin(@currentInterval.endSeconds, 'end');
        @changeControlsMode(true);
        @seekTo 0

    handleClickTimebar: (e)->
      pin = @getNearestPin(e);
      @startCoords = Vector.rotate [e.pageX, e.pageY], @model.get "rotate"
      @deltaXVector = [0,0]
      pos = @ui.positionHelper.offset();
      @startCoords = [pos.left, pos.top]
      handleF = if pin is @pins.playbackMode.start then @onPlaybackPinDrag else
        @onIntervalPinDrag
      seconds = handleF(pin, e);
      @seekTo seconds
      e.stopPropagation();
      e.preventDefault();
        
    getNearestPin: (e)->
      xOffset = e.pageX;
      if @model.get "intervalMode"
        startPinOffset = @pins.intervalMode.start.offset().left
        endPinOffset = @pins.intervalMode.end.offset().left
        deltaStart = startPinOffset - xOffset
        absDeltaStart = Math.abs deltaStart
        deltaEnd = endPinOffset - xOffset
        absDeltaEnd = Math.abs deltaEnd 
        if absDeltaStart < absDeltaEnd
          pin = @pins.intervalMode.start
        else if absDeltaStart == absDeltaEnd
          if deltaStart < 0
            pin = @pins.intervalMode.end
          else
            pin = @pins.intervalMode.start
        else
          pin = @pins.intervalMode.end
      else
        pin = @pins.playbackMode.start
      pin
      
    changePinVisualState: (pin, flag)->
      action = if flag then 'add' else 'remove'
      pin["#{action}Class"]('active')
      pin.find('.round-inner')["#{action}Class"]('red');
      
    getTimeLineWidth: ->
      width = @model.get("size")[0];
      (width - @pinWidth) * @getZoom();
      
    registerModelEvents: ()->
      ['startSeconds', 'endSeconds'].forEach(
        (borderName)=>
          @listenTo(@model, "change:#{borderName}", ()=> 
            @handleChangeIntervalBorderValue borderName
          ); 
      );
      
    handleChangeIntervalBorderValue: (borderName)->
      @showPreview();
      if newValue is null
        newValue = @getDefaultBorderValue(borderName);
        @model.set borderName, newValue, silent:true
      @currentInterval[borderName] = newValue;
      @renderMetadata();
      @seekTo 0
      @setPinPositionFromSeconds @pins.playbackMode.start, 0
      
    handlePlaybackProgress: ()=>
      if @model.get("intervalMode") || @isPaused()
        return false;
      realCurrentTime = @getRealPlaybackTime(5)
      endSeconds = @model.getIntervalBorder 'endSeconds', 5
      startSeconds = @model.getIntervalBorder 'startSeconds', 5
      if  (endSeconds >= realCurrentTime >= startSeconds)
        @setCurrentTime(@getCurrentPlaybackTime());
        @setPinPositionFromSeconds(@pins.playbackMode.start, 
          @getCurrentPlaybackTime());
        return false;
      else
        @setCurrentTime(startSeconds);
        @setPinPositionFromSeconds(@pins.playbackMode.start, 0);
        @stopVideo();
        @onVideoEnded();
        return true;

    close: ->
      unless @previewMode
        @detachAllPlayerEvents();
      super

    onPinDragStart: (pin, dragCb, dragEndCb)->
      @seekinFlag = true;
      onDragEnd = (e)=>
        @onPinDragEnd(pin, e);
        @changePinVisualState(pin, false);
        document.body.removeEventListener('mouseup', onDragEnd)
        document.body.removeEventListener('mousemove', onDragCatch)
        if dragEndCb
          dragEndCb(pin, e);

          
      onDragCatch = (e)=>
        seconds = dragCb(pin, e);
        @seekTo seconds;

      document.body.addEventListener 'mousemove', onDragCatch
      document.body.addEventListener 'mouseup', onDragEnd;

    onPlaybackPinDrag: (pin, e)=>
      offset = @processPinOffset e
      seconds = @getSecondsFromPercentage offset, false
      @setPinPositionFromSeconds pin, seconds, false
      @setCurrentTime seconds
      seconds
      
    onIntervalPinDrag: (pin, e)=>
      borderName = @determineBorderNameByPin pin, false;
      offset = @processPinOffset e, borderName;
      seconds = @getSecondsFromPercentage offset, true
      @changeIntervalBorderValue borderName, seconds
      seconds

    onPinDragEnd: (pin)->
      @seekinFlag = false;
        
    determineBorderNameByPin: (pin, isNeedOpposite)->
      if !@model.get "intervalMode"
        return null;
      index = if pin is @pins.intervalMode.start then 0 else 1
      if !isNeedOpposite then @intervalBorderNames[index] else 
        @intervalBorderNames[++index % 2]
        
    getDefaultBorderValue: (borderName)->
      if borderName is 'startSeconds' then 0 else @getDuration(true);

    onVideoEnded: ->
      if !@model.get("intervalMode") and !@seekinFlag
        @seekTo 0;
        @setPinPositionFromSeconds @pins.playbackMode.start, 0
        @setCurrentTime 0
        @showPreview();
        if @model.get('link')?
          @model.interactiveLinkSelect()
