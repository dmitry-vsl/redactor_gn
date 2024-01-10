var glob = require('glob');
var sass = require('node-sass');
var fs = require('fs');

var files = glob.sync('stylesheets/**/*.scss');
for(var i = 0; i < files.length; i++){
  var file = files[i];
  var css = sass.renderSync({
    file: file, 
    includePaths: ['vendor/bower/compass-mixins/lib/','stylesheets'],
  });
  var cssFileName = file
    .replace('stylesheets','public/css')
    .replace('scss','css');
  fs.writeFileSync(cssFileName,css.css);
}
