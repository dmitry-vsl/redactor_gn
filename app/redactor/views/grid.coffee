define (require) ->
  Constants = require '../constants'


  class GridView 
    constructor: (css) ->
      generateSvg = ->
        result = """
          <svg 
            preserveAspectRatio='none' 
            viewbox='0 0 #{Constants.GRID_SIZE} #{Constants.GRID_SIZE}'>
        """

        for x in [0..Constants.GRID_SIZE]
          result += generateLine x, 0, x, Constants.GRID_SIZE
          result += generateLine 0, x, Constants.GRID_SIZE, x

        result += '</svg>'

      generateLine = (x1,y1,x2,y2) ->
        """ 
          <line  
            vector-effect="non-scaling-stroke"
            stroke-width='0.5'
            x1 = '#{x1}' 
            y1 = '#{y1}' 
            x2 = '#{x2}' 
            y2 = '#{y2}' 
          />
        """

      @$el = $(generateSvg()).css _.extend css,
        'pointer-events': 'none'
        'opacity'       : 0.2
        'position'      : 'absolute'
    
    setColor: (@color) ->
      @$el.find('line').attr 'stroke', @color
