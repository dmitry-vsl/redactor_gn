define (require) ->
  BaseSearchPanel = require './baseSearchPanel'



  class YoutubeVideosPanel extends BaseSearchPanel
    className: 'panel settings video'
    template: 'redactor.media.youtube'
