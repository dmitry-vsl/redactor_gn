define (require) ->
  Constants = require './constants'


  svgsDef = undefined
  svgs = {}
  ->
    unless svgsDef?
      defs = Constants.STANDART_SVG.map (name) ->
        $.ajax
          url: "/images/redactor-img/shapes/#{name}.svg"
          dataType: 'text'
          type: 'GET'
        .then (svg) ->
          svgForeignNode = new DOMParser().parseFromString(svg, 'application/xml').documentElement
          svgNode = document.importNode svgForeignNode, true
          svgNode.setAttribute 'width', '100%'
          svgNode.setAttribute 'height','100%'
          svgNode.setAttribute 'preserveAspectRatio','none'
          svgs[name] = svgNode
      svgsDef = $.when(defs...).then -> svgs
    svgsDef
