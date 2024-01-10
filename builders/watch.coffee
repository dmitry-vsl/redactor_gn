fs = require 'fs'
chokidar = require 'chokidar'
mkdirp = require 'mkdirp'
coffee = require 'coffee-script'
sass = require 'node-sass'
chalk = require 'chalk'
exec = require('child_process').exec

APP_DIRS = ['static','stylesheets','app','templates']

showError = (message) ->
  console.log chalk.red message
  console.log '\u0007'

showSuccess = (message) ->
  console.log chalk.green message

compileCoffeeAndLint = (source, target) -> 
  fileSource = fs.readFileSync source, encoding: 'utf8'  
  try
    js = coffee.compile fileSource
  catch e
    message = "#{source}:#{e.location.first_line}:#{e.location.first_column} #{e.message}"
    showError message
    return
  mkdirp.sync require('path').dirname target
  fs.writeFileSync target, js, 'utf8'
  showSuccess "#{source} compiled successfully"

compileSass = (source, target) ->
  try
    css = sass.renderSync
      file: source
      includePaths: ['vendor/bower/compass-mixins/lib/','stylesheets'],
  catch e
    showError e
    return
  fs.writeFileSync target, css.css
  showSuccess "#{source} compiled successfully"

compileTemplates = (source, target) ->
  exec "./builders/compileTemplates", (error, stdout, stderr) ->
    if error?
      showError "Failed to compile #{source}"
      console.log stderr
    else
      showSuccess "#{source} compiled successfully"

copy = (source, target) ->
  file = fs.readFileSync(source,encoding: 'utf8')
  mkdirp.sync require('path').dirname target
  fs.writeFileSync target, file
  showSuccess "#{source} copied"

rule = (source, target, action) ->
  return {
    pattern: new RegExp(
      '^' +  
      source.replace('.','\\.').replace('%','(.*)') + 
      '$'
    )
    target: target
    action: action
  }

handleFile = (file) -> 
  for rule in rules
    if (matches = rule.pattern.exec file)?
      rule.action file, rule.target.replace '%', matches[1]

rules = [
  rule 'tests/coffee/%.coffee','tests/js/%.js', compileCoffeeAndLint
  rule 'app/%.coffee','public/js/%.js', compileCoffeeAndLint
  rule 'app/%.js','public/js/%.js', copy
  rule 'static/%','public/%', copy
  rule 'mockups/%','public/%', copy
  rule 'stylesheets/%.css','public/css/%.css', copy
  rule 'stylesheets/%.scss','public/css/%.css', compileSass
  rule 'templates/%.hbs', 'public/templates/templates.js', compileTemplates
]

console.log 'Initializing file watches. It may take some time'
  
chokidar.watch APP_DIRS, ({persistent: true, ignoreInitial: true})
  .on 'add', handleFile
  .on 'change', handleFile
  .on 'ready', -> showSuccess 'Ready to work'
