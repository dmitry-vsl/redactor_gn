define (require) ->
  Layout = require 'base/layout'
  AlertView = require './alert'
  ConfirmView = require './confirm'
  PromptView = require './prompt'


  
  modalViews = []

  class ModalView extends Layout
    template: "widgets.modal"

    templateHelpers: ->
      overlayClass: @overlayClass
      contentClass: @contentClass

    hotkeys:
      events:
        'esc': 'cancel'

    events: ->
      @options.closeOnBackdropClick ?= true
      events = {}
      if @options.closeOnBackdropClick
        events["click .#{@overlayClass}"] = 'cancel'
      events

    initialize: ({@view}) ->
      @view.once "modal:close", => do @close
      @view.once "modal:close:all", => do ModalView.closeAll

    cancel: ->
      @view.trigger "modal:cancel"
      do @close

    close: ->
      i = modalViews.indexOf @
      if i isnt -1 then modalViews.splice(i, 1)

      @$el.addClass @hiddenClass
      # wait for css transition to end and close modal
      setTimeout (=> super), 300

    onRender: ->
      @$el.addClass @modalClass
      @$el.addClass @hiddenClass

      modalViews.push @

      $lastModal = $(".#{@modalClass}:last")
      if $lastModal.length 
        $lastModal.after @$el
      else
        @$el.prependTo('body')
      @content.show @view
      do @adjustPosition
      @$el.removeClass @hiddenClass
      @trigger "modal:show"

    adjustPosition: ->
      # move to center of the screen
      $box = @regionManager.get('content').$el
      $container = $(window)
      $box.css
        left: $container.width() / 2 - $box.width() / 2
        top: $container.height() / 2 - $box.height() / 2

    # Opens a modal window
    # @param view - a Marionette.View instance.
    # @param options.success - callback when modal view is rendered
    # @param option.closeOnBackdropClick - true by default
    # @returns a ModalView instance.
    @open: (view, options={}) ->
      if not view? then throw new Error 'Couldn\'t open modal without a view.'

      modal = new ModalView _.extend view: view, options

      modal.once "modal:show", ->
        if _.isFunction options.success then options.success.call @, @modal

      do modal.render
      modal.$el.css zIndex: options.zIndex if options.zIndex
      modal

    # Closes a modal window
    # @param modal - a modal view to close; closes the last open modal if called without arguments.
    @close: (modal) ->
      if not modal? 
        if modalViews.length is 0 then return
        modal = modalViews.pop()
      do modal.close 

    # Closes all modals
    @closeAll: () ->
      while modalViews.length > 0 then do ModalView.close

    # Shortcut method to open an alert view.
    # @param options - see AlertView
    @alert: (options={}) ->
      view = new AlertView options
      @open view; view

    # Shortcut method to open a confirm view.
    # @param options - see ConfirmView
    @confirm: (options={}) ->
      view = new ConfirmView options
      @open view, options
      view

    # Shortcut method to open a prompt view.
    # @param options - see PromptView
    @prompt: (options={}) ->
      view = new PromptView options
      @open view; view

    # Initial setup for all modals in the application
    #
    # @param options.template - modal window template
    # @param options.modalClass - css class of the modal
    # @param options.hiddenClass, options.contentClass, options.overlayClass -
    # can be set directly or extended from options.modalClass.
    # E.g. if options = { modalClass: "my-modal" }, then markup must contain the
    # following css classes: 
    # "my-modal" - modal window container
    # "my-modal-hidden" - hidden modal (display:none)
    # "my-modal-box" - where the content should be rendered
    # "my-modal-overlay" - overlay
    @setup: (options={}) ->
      options.hiddenClass ?= "#{options.modalClass}-hidden"
      options.contentClass ?= "#{options.modalClass}-box"
      options.overlayClass ?= "#{options.modalClass}-overlay"

      _.extend ModalView::, options
      ModalView::regions = 
        content: ".#{options.contentClass}"

    # Always perform setup with default parameters, for backward compatibilty with Geenio
    @setup modalClass: 'gn-modal' 
