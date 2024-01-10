define(function(){
  return function(options){
    options = options ? options : {};
    var accept = options.accept;
    var uploadDef = $.Deferred();
    var input = $("<input type='file'></input>");
    if(accept){
      input.attr('accept', accept);
    }
    input.on('change', function({target}){
      return uploadDef.resolve(target.files);
    });
    input.click();
    return uploadDef;
  };
});
