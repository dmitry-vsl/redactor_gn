require.config
  baseUrl: '/js'

  deps: [
    "index"
  ]

  shim:
    "underscore":
      exports: "_"

    backbone: deps: ['underscore']

    "templates":
      exports: "Templates"

    "scroller":
      deps: [
        'jquery'
      ]

    "crop":
      deps: [
        'jquery'
      ]

    "imageUtils":
      deps: [
        'jquery'
      ]

    "jqueryui-touch-punch":
      deps: [
        'jqueryui'
      ]

    "jqueryui":
      deps: [
        'jquery'
      ]

    "marionette":
      exports: "Marionette"
      deps: [
        'backbone'
        'backbone.wreqr'
        'backbone.babysitter'
      ]

  paths:
    "marionette" : "libs/bower/marionette/lib/core/amd/backbone.marionette"
    "backbone": "libs/bower/backbone/backbone"
    "backbone.wreqr": "libs/bower/backbone.wreqr/lib/backbone.wreqr"
    "backbone.babysitter": "libs/bower/backbone.babysitter/lib/backbone.babysitter"
    "jqueryui" : "libs/jquery-ui-1.10.4.custom"
    "underscore" : "libs/bower/underscore/underscore"
    "jquery" : "libs/bower/jquery/jquery"
    "handlebars.runtime" : "libs/bower/handlebars/handlebars.runtime.amd"

    'jqueryui-touch-punch' : 'libs/bower/jqueryui-touch/jquery.ui.touch-punch'

    "scroller" : "libs/bower/nanoscroller/bin/javascripts/jquery.nanoscroller"
    "crop" : "libs/bower/jcrop/js/jquery.Jcrop"
    "templates": "../templates/templates"
    'colpick' : 'libs/bower/colpick/js/colpick'
