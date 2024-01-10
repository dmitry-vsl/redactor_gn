define (require) ->
  Handlebars = require 'handlebars.runtime'
  Templates = require 'templates'


  
  slashRegexp = /\//g
  for name, template of Templates
    newName = name.replace slashRegexp, '.'
    Templates[newName] = template

  Handlebars = Handlebars.default
  Handlebars.partials = Templates 

  # Switch-case for Handlebars:
  # {{#switch var}}
  #   {{#when 'value1'}}...{{/when}}
  #   {{#when 'value2' 'value3' ... 'valueN'}}...{{/when}}
  #   {{else}}
  #     ...
  # {{/switch}}
  Handlebars.registerHelper "switch", (param, obj) ->
    @_isSwitch = true
    @_switchparam = param
    res = obj.fn @, obj
    if not @_switchdone then res = obj.inverse @, obj
    delete @_isSwitch
    delete @_switchdone
    delete @_switchparam
    res

  Handlebars.registerHelper "when", () ->
    if not  @_isSwitch? then throw new Error ("When statement outside a switch.")
    if @_switchdone then return

    obj = Array.prototype.pop.apply arguments

    if _.contains arguments, @_switchparam 
      @_switchdone = true; obj.fn @, obj     

  # IfEqual: renders content if two parameters are equal.
  # {{#ifequal var value}}..{{/ifequal}}
  Handlebars.registerHelper "ifequal", (val1, val2) ->
    obj = Array.prototype.pop.apply arguments
    if val1 is val2 then obj.fn @, obj  
