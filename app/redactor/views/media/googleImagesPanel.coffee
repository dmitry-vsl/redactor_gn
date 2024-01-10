define (require) ->
  BaseSearchPanel = require './baseSearchPanel'



  class GoogleImagesPanel extends BaseSearchPanel
    className: 'panel settings image'
    template: 'redactor.media.google'
