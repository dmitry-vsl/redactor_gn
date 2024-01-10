define ->
  
  MOUSE_TO_TOUCH = 
    mousemove : 'touchmove'
    mousedown : 'touchstart'
    mouseup   : 'touchend'
 
  mouseEventnameToTouch = (eventName) ->
    parts = eventName.split '.'
    parts[0] = MOUSE_TO_TOUCH[parts[0]]
    parts.join '.'

  makeTouchHandler = (mouseHandler) ->
    (e) ->
      touches = e.originalEvent.touches[0]
      if touches?
        _.extend e, _.pick touches, 'pageX','pageY','offsetX','offsetY'
      result = mouseHandler.call @, e
      e.preventDefault()
      result

  module =
    on: (el, event, selector, handler) ->
      if _.isFunction selector 
        handler = selector
        selector = undefined

      el.on event, selector, handler

      el.on mouseEventnameToTouch(event), selector, makeTouchHandler handler

    off: (el, event) ->
      el.off event
      el.off mouseEventnameToTouch event

    wrapEventsHash: (events) ->
      wrappedEvents = {}
      for event, handler of events
        do (event, handler) ->
          wrappedEvents[event] = handler
          if event.indexOf('mouse') is 0
            [ev, selector] = event.split ' '
            touchHandler =  makeTouchHandler (
              if _.isString handler
                (e) -> @[handler] e
              else
                handler
            )
            newEvent = mouseEventnameToTouch(ev)
            if selector? 
              newEvent += ' ' + selector 
            wrappedEvents[newEvent] = touchHandler
      wrappedEvents
