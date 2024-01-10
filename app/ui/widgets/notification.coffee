define (require) ->
  ItemView = require 'base/itemView'


  notifications = [];
  class Notification extends ItemView
    template : 'widgets.notification'
    
    initialize: ({@text, @title, @type, @icon, @timeout})->
      super
      notifications.push(@);
      
    className: "notificationContainer"
    
    ui:
      textHolder: '.js-textHolder'
      titleHolder: '.js-titleHolder'
      closeCross: '.js-closeCross'
      iconHolder: '.js-iconHolder'
      
    events:
      'click .js-closeCross' : 'close'
          
    templateHelpers: ()->
      title : @title || ""
      text : @text || ""
      icon : @icon || ""
      type : @type || ""
      
    onShow:()->
      if @timeout
        setTimeout ()=>
          @close()
        , @timeout
    
    onRender: ()->
      @$el.addClass(@type)
        
    @closeAllNotifications: ()->
      notifications.forEach (nt)->
        nt.close();
