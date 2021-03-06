istty = process.stdout.isTTY
util = require('util')
slice = Array.prototype.slice
pid = process.pid.toString()
hostname = require('os').hostname().replace(/\s+/g, '')

levels =
  EMERGENCY: 0
  emergency: 0
  emerg: 0
  panic: 0
  ALERT: 1
  alert: 1
  CRITICAL: 2
  critical: 2
  crit: 2
  ERROR: 3
  error: 3
  err: 3
  WARNING: 4
  warning: 4
  warn: 4
  NOTICE: 5
  notice: 5
  INFO: 6
  info: 6
  DEBUG: 7
  debug: 7

levelNames = [
  'EMERGENCY'
  'ALERT'
  'CRITICAL'
  'ERROR'
  'WARNING'
  'NOTICE'
  'INFO'
  'DEBUG'
]

class Logger
  constructor: (@tag='', @level=levels.DEBUG)->

  _log: (level, message)->
    if level <= exports.level && level <= @level
      data = 
        tag: @tag
        pid: pid
        hostname: hostname
        timestamp: new Date()
        level: level
        levelName: levelNames[level]
        message: util.format.apply(this, message)
      process.stdout.write(exports.format(data)+"\n")

  log: (levelName)->
    level = levels[levelName]
    @_log(level, slice.call(arguments, 1))

  emergency: ()->
    @_log(0, arguments)
  emerg: @::emergency

  alert: ()->
    @_log(1, arguments)

  critical: ()->
    @_log(2, arguments)
  crit: @::critical

  error: ()->
    @_log(3, arguments)
  err: @::error

  warning: ()->
    @_log(4, arguments)
  warn: @::warning

  notice: ()->
    @_log(5, arguments)

  info: ()->
    @_log(6, arguments)

  debug: ()->
    @_log(7, arguments)

  ###
    Connect/Express middleware
  ###
  write: ()->
    @_log(6, arguments)

module.exports = exports = (tag, level)->
  level = levels[level.toUpperCase()] if 'string' == typeof level
  return new Logger(tag, level)

exports.level = levels.DEBUG

exports.setLevel = (level)->
  level = levels[level.toUpperCase()] if 'string' == typeof level
  exports.level = level if level?

exports.levels = levels

exports.formats = formats =
  console: (data)->
    return "#{data.timestamp.toLocaleTimeString()} #{data.hostname} #{data.tag}[#{data.pid}]: <#{data.levelName}> #{data.message}"
  file: (data)->
    return JSON.stringify(data)
  ###
    logstash's internal message format
    https://github.com/logstash/logstash/wiki/logstash's-internal-message-format
    https://logstash.jira.com/browse/LOGSTASH-675
  ###
  logstash: (data)->
    return JSON.stringify {
      '@timestamp': data.timestamp
      '@tags': [data.tag, data.pid, data.levelName]
      '@source': "#{data.hostname} #{data.tag}[#{data.pid}]"
      '@message': data.message
      '@fields':
        level: data.level
        levelName: data.levelName
    }

if istty == true
  exports.format = formats.console
else
  exports.format = formats.file
