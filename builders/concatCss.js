// Парсит файл public/css/all.scss и заменяет его на конкатенацию файлов
// которые он импортирует

var fs = require('fs');

var BASE_DIR = 'public/css/';
var ALL_CSS_FILE = BASE_DIR + 'all.css';
var match;
var regexp = /url\s*\(['"](.+?)['"]\)/g;
var allCss = fs.readFileSync(ALL_CSS_FILE,{encoding:'utf8'});
var resultFileContents = '';
while(match = regexp.exec(allCss)){
  var fileName = match[1];
  var cssFileContents = fs.readFileSync(BASE_DIR+fileName);
  resultFileContents = resultFileContents + cssFileContents;
}
fs.writeFileSync(ALL_CSS_FILE,resultFileContents);
