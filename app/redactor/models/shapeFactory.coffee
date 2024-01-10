define (require) ->
  Text = require './text'
  Image = require './image'
  Video = require './video'
  Svg = require './svg'



  class ShapeFactory
    constructor: (attrs, options) ->
      clazz = switch attrs.type
        when 'text' then Text 
        when 'video' then Video 
        when 'svg' then Svg 
        when 'image' then Image
        else
          throw new Error 'unknown shape type ' + attrs.type
      return new clazz attrs, options
