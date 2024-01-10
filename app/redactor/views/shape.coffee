define (require) ->
  ImageView = require './imageShape'
  TextView = require './text'
  LocalVideo = require './video/localVideo'
  YoutubeVideo = require './video/youtubeVideo'
  PlaceholderVideo = require './video/placeholderVideo'
  UploadedSvg = require './svg/uploadedSvg'
  BasicSvg = require './svg/basicSvg'


  (options) ->
    clazz = switch options.model.get 'type'
      when 'text' then TextView
      when 'image' then ImageView
      when 'video'
        switch options.model.get 'videoType'
          when 'local' then LocalVideo
          when 'youtube' then YoutubeVideo
          when null then PlaceholderVideo
      when 'svg'
        switch options.model.get 'shapeCategory'
          when 'uploaded' then UploadedSvg
          when 'basic' then BasicSvg
        
    return new clazz options
