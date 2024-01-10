define (require) ->
  BaseSvg = require './baseSvg'
  Vector = require '../../vector'
  loadBasicSvgs = require '../../loadBasicSvgs'


  class BasicSvgView extends BaseSvg

    serializeData: ->
      _.extend super,
        sideControl: [
          {positionClass: 'left-center', positionLeft: -1, positionTop: 0}
          {positionClass: 'right-center', positionLeft: 1, positionTop: 0}
          {positionClass: 'center-top', positionLeft: 0, positionTop: -1}
          {positionClass: 'center-bottom', positionLeft: 0, positionTop: 1}
        ]
        showSideControls: @model.get('shapeCategory') is 'basic'

    events: _.extend {}, BaseSvg::events,
      'mousedown .js-scaleSide' : 'startScaleSide'

    modelEvents: _.extend {}, BaseSvg::modelEvents,
      'change:fillColor' : 'updateFillColor'
      'change:radius' : 'updateRadius'
      'change:shapeType' : 'renderShape'
      
    onRender: ->
      super
      @renderShape()

    renderShape: ->
      @shapeEl?.remove()
      loadBasicSvgs().then (svgs) =>
        @shapeEl = $ svgs[@model.get('shapeType')].cloneNode(true)
        @ui.svgContainer.append @shapeEl
        @updateBorder()
        @updateFillColor()
      if @model.get('shapeType') is 'rectangle'
        @updateRadius()
    
    updateFillColor: ->
      if @shapeEl?
        fillColor = @model.get 'fillColor'
        if fillColor?
          @shapeEl.css 'fill', fillColor
        else
          @shapeEl[0].style.removeProperty 'fill'
        
    updateRadius: ->
      radius = @model.get 'radius'
      @shapeEl?.attr('rx',radius).attr('ry',radius)

    # TODO
    #clipOuterStroke: ->
    #  clipId = 'redactorSvgClip'+@model.id
    #  clone = @shapeEl[0].cloneNode()
    #  @clipPath = @createSvgNode 'clipPath', id: clipId
    #  @clipPath.appendChild clone
    #  @shapeEl[0].parentNode.appendChild @clipPath
    #  @shapeEl.attr 'clip-path', "url(##{clipId})"

    updateBorder: ->
      if @shapeEl?
        if @model.get('hasBorder')
          borderColor = @model.get 'borderColor'
          if borderColor?
            @shapeEl.css 'stroke', borderColor
          else
            @shapeEl[0].style.removeProperty 'stroke'

          borderWidth = @model.get('borderWidth')
          @shapeEl.css 'stroke-width', borderWidth
          dashArray = switch @model.get('borderStyle')
            when "solid" then ""
            when "dashed" then "#{3*borderWidth},#{3*borderWidth}"
            when "dotted" then "#{borderWidth},#{borderWidth}"
          @shapeEl.css 'stroke-dasharray', dashArray
        else
          @shapeEl.css 'stroke-width', 0

    startScaleSide: (event) ->
      @model.startChangesIfNotFocused()
      @model.saveOriginalPosition()
      scaleControl = $(event.target)
      @scaleDirection = [
        Number scaleControl.attr 'data-position-left'
        Number scaleControl.attr 'data-position-top'
      ]

      @originalXY = [event.pageX, event.pageY]
      @page.onMouseEvent 'mousemove.shape.scaleSide', @processScaleSide
      @page.onMouseEvent 'mouseup.shape.scaleSide', @finishScaleSide
      return false

    processScaleSide: (event) =>
      mouseMoveVector = Vector.subtract [event.pageX, event.pageY], @originalXY
      @model.scaleSide {mouseMoveVector, @scaleDirection}

    finishScaleSide: =>
      @page.offMouseEvent 'mousemove.shape.scaleSide'
      @page.offMouseEvent 'mouseup.shape.scaleSide'
      @model.commitChangesIfNotFocused()
      return false
