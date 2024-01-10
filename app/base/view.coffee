define (require) ->
  Marionette = require 'marionette'
  Templates = require 'templates'
  KeyManager = require 'utils/keyManager'
  i18n = require 'i18n'



  # You can define 'bindings' param for data bindings. Example:
  # class MyView extends ItemView
  #   bindings: ['someModelAttr', 'someOtherModelAttr']
  # Currently the only type is checkbox. The model's field with name
  # 'someModelAttr' will be binded to element with same name in @ui hash

  keyManager = new KeyManager

  (clazz) ->
    close: ->
      if @animateRenderClose?
        @_getAnimateRenderCloseEl().animate @animateRenderClose.hide,
          @animateRenderClose.duration
        setTimeout (=> @_doClose()), @animateRenderClose.duration
      else
        @_doClose()

    _doClose: ->
      clazz::close.apply @, arguments
      @unbindHotkeys()

    _getAnimateRenderCloseEl: ->
      selector = @animateRenderClose.selector
      if selector?
        if _.isFunction selector
          selector.call @
        else if _.isString selector
          @$el.find selector
        else throw new Error 'unknown selector type ' + selector
      else
        @$el

    getTemplate: ->
      tpl = clazz::getTemplate.apply @, arguments
      if _.isString tpl then Templates[tpl] ? throw new Error 'Could not find template ' + @template
      else tpl

    constructor: ->
      clazz::constructor.apply @, arguments
      if @bindings?
        @_bindViewToModel binding for binding in @bindings
      if @animateRenderClose?
        @on 'show', =>
          @_getAnimateRenderCloseEl().css @animateRenderClose.hide
          @_getAnimateRenderCloseEl().animate @animateRenderClose.show,
            @animateRenderClose.duration

    _bindViewToModel: (binding) ->
      @listenTo @model, "change:" + binding, (model,value,{eventSource}) => 
        @_updateView binding, eventSource

    _bindModelToView: (binding) ->
      events = switch @_getBindingType binding
        when 'textinput' then 'change input'
        when 'checkbox' then 'click change'
        when 'editable' then 'input'
        when 'text' then undefined

      if events? and @ui[binding].length > 0
        @ui[binding].on events, (ev) => 
          @_updateModel binding, ev.target

    _updateView: (binding, eventSource) ->
      # don't update element that caused model update
      unless @ui[binding][0] is eventSource
        switch @_getBindingType binding
          when 'text', 'editable'
            @ui[binding].text @model.get binding
          when 'textinput'
            @ui[binding].val @model.get binding
          when 'checkbox'
            # !! to convert undefined to false
            @ui[binding].prop 'checked', !!(@model.get binding)

    _getBindingType: (binding) ->
      switch @ui[binding][0].nodeName
        when 'INPUT'
          switch @ui[binding].attr 'type'
            when 'checkbox' then 'checkbox'
            when 'text' then 'textinput'
            else throw new Error 'unsupported input type'
        when 'TEXTAREA' then 'textinput'
        when 'P'
          if @ui[binding].prop 'contenteditable' then 'editable'
          else 'text'
        else 'text'

    _updateModel: (binding, eventSource) ->
      switch @_getBindingType binding
        when 'textinput'
          @model.set binding, @ui[binding].val(), eventSource: eventSource
        when 'checkbox'
          value = !!(@ui[binding].prop 'checked')
          @model.set binding, value
        when 'editable'
          @model.set binding, @ui[binding].text(), { eventSource }

    render: ->
      clazz::render.apply @, arguments

      if @bindings?
        for binding in @bindings
          if @ui[binding].length > 0
            @_bindModelToView binding 
            @_updateView binding


      # If view.usePushStateLinks is set to true, then click handler attached to
      # every link to perform app.router.navigate. Disabled by default
      if @usePushStateLinks
        @$('button[href],a[href]').click () ->
          app.router.navigate $(this).attr('href'), trigger: true
          # prevent default
          false

      @configureHotkeys()

      @trigger 'after:render'

    mixinTemplateHelpers: ->
      target = clazz::mixinTemplateHelpers.apply @, arguments
      target.currentUser = app?.user.attributes
      target.l = i18n.getBundle()
      target

    # prepare handlers for hotkeys (only single keystrokes for now)
    configureHotkeys: ->
      @_suspendedHotkeys = []
      do @addKeyHandlers

    addKeyHandlers: (keys) ->
      if not @hotkeys? then return

      addHandler = (key, handler) =>
        if not keys? or _.contains keys, key
          keyManager.add key, handler, @

      if @hotkeys.events?
        _.each @hotkeys.events, (handler, key) =>
          addHandler key, if _.isString handler then @[handler] else handler
      if @hotkeys.triggers?
        _.each @hotkeys.triggers, (eventName, key) =>
          addHandler key, => @.trigger eventName

    # unbinds all hotkeys of the view
    unbindHotkeys: (keys) ->
      if not _.isArray keys then keys = Array.prototype.splice.call arguments, 0
      @_suspendedHotkeys?.push keys...
      keyManager.unbind @, keys

    # resume suspended hotkeys
    resumeHotkeys: (keys) ->
      if not _.isArray keys then keys = Array.prototype.splice.call arguments, 0
      resumingKeys = []; k = null
      while k = @_suspendedHotkeys.pop()
        if _.contains keys, k then resumingKeys.push k
      keys = resumingKeys
      if keys.length then @addKeyHandlers keys
