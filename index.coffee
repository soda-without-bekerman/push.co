#!/usr/bin/env coffee

#
# Основной файл скрипта трекера. Обрабатывает команды консоли.
# Команды консоли описаны в docs.scon
#

require "colors"
docData = require "#{__dirname}/docs.RU"
commands = require "./commands"

util = require "./util"


#
# Собрать имена команд из справки
#
procs = {}
for k,v of docData.commands
  for cmd in v.alias
    procs[cmd] = v.procName

#
# Короткое имя команды в имя функции
#
#
getCommandName = (name) ->
  procs[name] or null


#
# Загрузить конфиг
#
util.loadConfig (err, cf) ->
  cmd = process.argv[2]
  if cmd in ["-v", "--version"]
    fs = require "fs"
    try
      pkg = JSON.parse fs.readFileSync "./package.json", "utf-8"
      console.log "push.co tracker v#{pkg.version}"
    catch e
      console.error "ошибка при чтении настроек пакета".red
    return 

  cmd = getCommandName cmd
  switch cmd
    when "help", "h"
      commands[cmd].call @, process.argv[3..], docData.commands
    else
      util.loadData cf, (err, data) ->
        if cmd?
          commands[cmd].call @, process.argv[3..], docData.commands, data, cf
        else
          if process.argv[2]?
            console.error "команда #{process.argv[2].bold} не найдена".red
          commands.help.call @, [], docData.commands






