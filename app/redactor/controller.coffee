define (require) ->
  Marionette = require 'marionette'
  Redactor = require './models/redactor'
  GoogleImagesCollection = require './collections/media/googleImages'
  YoutubeVideosCollection = require './collections/media/youtubeVideos'
  Layout = require './layout'
  Theme = require './theme'
  ToolsView = require './views/tools'
  PagesView = require './views/pages'
  ShapePanel = require './views/shapePanel'
  LayersView = require './views/layers'
  GoogleImagesPanel = require './views/media/googleImagesPanel'
  YoutubeVideosPanel = require './views/media/youtubeVideosPanel'
  ThemesPanel = require './views/themesPanel'
  Modal = require 'ui/widgets/modal'
  i18n = require 'i18n'
  googleAPI = require './googleAPI'


  # Fake values
  PRESENTATION_ID = 1 
  PAGE_ID = 1

  redactorBundle = i18n.getBundle().redactor

  class RedactorController extends Marionette.Controller
    
    initialize: ->
      googleAPI.loadGoogleAPI()
      googleAPI.loadYoutubePlayerAPI()

      @layout = new Layout
      @layout.render()
      document
        .querySelectorAll('.gn-module-container')[0]
        .appendChild(@layout.el)

      @redactor = new Redactor {presentationId: PRESENTATION_ID, pageId: PAGE_ID}
      @redactor.on 'change:page', =>
        @renderPage()
        @showPages()
      @redactor.init()

      @render()

      #@initBeforeUnload()

    renderPage: =>
      page = @redactor.getPage()
      @pageView = @layout.renderPage {controller: @, model: page}
      @renderView 'shapePanel', new ShapePanel {
        model: page, 
        @pageView, 
        controller: @
      }
      @layout.showPanel 'shapePanel'

    render: =>
      @layout.layersPanel.reset()
      delete @layersView
      Theme.applyTheme 
        objectId: @redactor.getPage().getObjectId()
        theme   : @redactor.getTheme()
      @renderView 'tools', new ToolsView
        model: @redactor
        controller: @

    showGoogleSearch: ({onApply, onCancel, onSelect}) ->
      unless @googleImagesPanel?
        @googleImagesPanel = new GoogleImagesPanel {
          collection: new GoogleImagesCollection,
          controller: @,
          @redactor
        }
        @layout.googleSearch.show @googleImagesPanel
        @redactor.on 'change:selectedShape', =>
          @layout.hidePanel 'googleSearch'
      @layout.showPanel 'googleSearch'
      @googleImagesPanel.focusSearch()
      @googleImagesPanel.setButtonHandlers {onApply,onCancel,onSelect}

    showYoutubeSearch: ({onApply, onCancel, onSelect}) ->
      unless @youtubeVideosPanel?
        @youtubeVideosPanel = new YoutubeVideosPanel {
          collection: new YoutubeVideosCollection,
          controller: @,
          @redactor
        }
        @layout.youtubeSearch.show @youtubeVideosPanel
        @redactor.on 'change:selectedShape', =>
          @layout.hidePanel 'youtubeSearch'
      @layout.showPanel 'youtubeSearch'
      @youtubeVideosPanel.focusSearch()
      @youtubeVideosPanel.setButtonHandlers {onApply,onCancel,onSelect}

    showThemes: ->
      @redactor.getPage().deselectAll()
      @redactor.startChanges onFinishChanges: =>
        @redactor.applyTheme()
      unless @themesPanel?
        @themesPanel = new ThemesPanel
          model: @redactor
          controller: @
        @layout.themesPanel.show @themesPanel
      @layout.showPanel 'themesPanel'

    showShapePanel: ->
      @layout.showPanel 'shapePanel'

    showLayers: ->
      @redactor.getPage().deselectAll()
      @redactor.finishChanges()
      unless @layersView?
        @layersView = new LayersView 
          collection: @redactor.getPage().shapes
          controller: @
        @renderView 'layersPanel', @layersView
      @layout.showPanel 'layersPanel'

    showPages: ->
      @redactor.getPage().deselectAll()
      @redactor.finishChanges()
      unless @pagesView?
        @pagesView = new PagesView 
          collection: @redactor.pages
          controller: @
        @renderView 'pagesPanel', @pagesView
      @layout.showPanel 'pagesPanel'

    renderView: (region, view) ->
      @layout[region]?.show view

    initBeforeUnload: ->
      $(window).on 'beforeunload.redactor', (e) =>
        if @redactor.hasUnsavedChanges()
          message = redactorBundle.unsaved_changes
          e.originalEvent.returnValue = message
          message
