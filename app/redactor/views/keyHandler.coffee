define ->

  KEY_CODES =
    46: 'Del'
    13: 'Enter'
    27: 'Esc'
    8:  'Backspace'
    9:  'Tab'

  KEYS = Object.keys KEY_CODES

  class KeyHandler

    constructor: ->
      @handlers = {}
      for code,name of KEY_CODES
        @handlers[code] = []
        @genAccessor code, name

      $(window).on 'keydown.redactor.keyHandler', (e) =>
        keyStr = e.keyCode.toString()
        if keyStr in KEYS
          return @handlers[keyStr][0]?(e)

    genAccessor: (keyCode,name) ->
      @['subscribe'+name] = (handler) -> 
        @handlers[keyCode.toString()].unshift handler
      @['unsubscribe'+name] = ->
        @handlers[keyCode.toString()].shift()

    close: ->
      $(window).off 'keydown.redactor.keyHandler'
