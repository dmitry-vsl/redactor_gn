define (require) ->
  BaseSvg = require './baseSvg'


  class SvgView extends BaseSvg

    modelEvents: _.extend {}, BaseSvg::modelEvents, 
      'change:file' : 'updateFile'

    onRender: ->
      super
      @updateFile()

    updateFile: ->
      src = @model.get('file').original
      @ui.svgContainer.css backgroundImage: "url('#{src}')"
