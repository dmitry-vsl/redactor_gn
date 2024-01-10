define (require) ->
  Shape = require './shape'
  Vector = require '../vector'


  class Video extends Shape
    defaults: _.extend {}, Shape::defaults,
      autoplay: false
      fullscreen: false
      startSeconds : null
      endSeconds : null
      previewFile: null
      size: [480,360]
      videoType: null

    set: ->
      attrs = arguments[0]
      attrChanged = (attr) =>
        (typeof(attrs[attr]) isnt 'undefined') and 
          not (_.isEqual attrs[attr], @get(attr))
      if attrChanged('youtubeId') or attrChanged('videoType') or attrChanged('file')
        @trigger 'forceRemoveView', @
        super
        @trigger 'forceRenderView', @
      else
        super
      
    isYoutube: ->
      @get('videoType') is 'youtube'

    getPreviewImageFile: ->
      switch @get('videoType')
        when 'local' then @get('file').image
        when 'youtube' then @get 'previewFile'
        else undefined

    getLocalVideoSrc: ->
      @get('file').original

    setIntervalBorder: (borderName, seconds, silent)->
      @set borderName, seconds, if silent then silent : true
      
    getIntervalBorder: (borderName, precision)->
      if precision
        +@get(borderName).toPrecision(precision);
      else
        @get borderName

    applyInterval: (start, end)->
      @setIntervalBorder "startSeconds", start, true
      @setIntervalBorder "endSeconds", end, true
      
    getIntervalDuration: ->
      @get("endSeconds") - @get("startSeconds")


    transformTime: (seconds)->
      _timeParts = [];
      # http://jsperf.com/math-round-vs-hack/5
      _floorHack = (num)->
        ~~num;
      firstZero = (num)->
        num+=''
        if num.length == 1
          num = '0'+num;
        num;
      if seconds > 3600
        hours = firstZero(_floorHack(seconds / 3600))          
        _timeParts.push(hours);

      minutes = firstZero(_floorHack(seconds % 3600 / 60))
      seconds = firstZero(_floorHack(seconds % 60))
      _timeParts.push(minutes, seconds);
      return _timeParts.join(':');

    getPercentage: (part, whole)->
      (part / whole) * 100
      
    getValueFromPercentage: (percentage, whole)->
      (whole / 100) * percentage

    processRotatedOffset: (offsetVector, restrictions)->
      rotatedBasis = Vector.rotate [1,0], @get("rotate")
      result = Vector.scalarProduct rotatedBasis, offsetVector
      if restrictions
        if result < restrictions.min
          result = restrictions.min
        else if result >  restrictions.max
          result = restrictions.max
      return result;

    uploadVideo: (file) ->
      @finishChanges()
      @getPage().uploadFile(file,{type:'video'}).then (file) =>
        @set
          startSeconds: null
          endSeconds: null
          videoType: 'local'
          file: file
        @saveState()

    setYoutubeVideo: ({youtubeId,original,width,height}) ->
      @set
        videoType: 'youtube',
        youtubeId: youtubeId
        previewFile: {original}
        startSeconds: null
        endSeconds: null
      @setSizePreservingWidthAndCenter [width,height]

    applyYoutubeVideo: ->
      @commitChanges()
