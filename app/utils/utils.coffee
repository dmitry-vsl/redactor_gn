define (require) ->
  require 'underscore'

  utils =
    text2html: (text) ->
      text ?= ''
      html = $('<div/>').text(text).html()
      html.replace /\n/g, '<br>'

    isMac: ->
      isOSX = navigator.userAgent.indexOf 'Mac OS X' > -1
      utils.isMac = -> isOSX;
      utils.isMac()

    # Example:

    # This is mixin. It can access methods of the class it is mixed to
    #   (clazz) ->
    #     foo: -> clazz::foo.apply @;console.log 'bar'

    # This is class with included mixin
    #   Utils.include(TestMixin).to class
    #     foo: -> console.log 'baz'

    # someVar = new Test
    # someVar.foo()
    # expected output: baz,bar


    include: (mixins...) ->
      to: (clazz)->
        resultClass = undefined
        _.each mixins, (mxn) -> 
          resultClass = class extends clazz
          _.extend resultClass::, mxn(clazz)
          clazz = resultClass
        resultClass

    createVendorCss: (prop, value) ->
      css = {}
      for vendor in ['webkit', 'moz']
        css["-#{vendor}-#{prop}"] = value
      css[prop] = value
      css

    repeatUntilKeyReleased: ({action, interval, keyCode}) ->
      $window = $ window
      interval ?= 200
      keyUp = false
      $window.one 'keyup.repeatUntilKeyReleased', ->
        keyUp = true
      waitUntilKeyUp = ->
        action()
        setTimeout -> 
          unless keyUp
            waitUntilKeyUp()
        , interval
      waitUntilKeyUp()
