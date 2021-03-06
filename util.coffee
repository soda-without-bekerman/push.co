#
# Вспомогательные функции
#
#

crypto    = require "crypto"
home      = process.env.HOME + "/.push.in.co"
uData     = process.env.HOME + "/.push.in.co+data"
fs        = require "fs"
_         = require "underscore"
require "colors"


#
# Public: Хеш строки
#
#
exports.createHash = createHash = (str, secret="soda labs") ->
  crypto.createHmac("sha1", secret).update(str).digest("hex")


#
# Настройки по умолчанию
#
_defaultSettings = ->
  user:
    name      : null
    avatar    : null
  push:
    email     : null
    phone     : null
  secretHash  : createHash "my-hash"
  dataFile    : uData
  outFormat   : "H:6|T:40"
  daysForTodo : 7


# ----------------------------------------
# СТРОКИ
# ----------------------------------------

#
# Public: Центрировать строку 
#
#
_centerString = (str, len) ->
  r = "#{str}"
  if r.length < len
    delta = parseInt (len - r.length) / 2
    "#{([1..delta].map (_x) -> ' ').join ''}#{r}"
  else
    r

#
# Internal: Получить длину для value, исходя из того,
#           что длина max_value = max_chars
#
_normalize = (value, max_value, max_chars) ->
  (value * max_chars ) / max_value


#
# Internal: Дублировать строку несколько раз
#
#
_dup = (str, times) ->
  ([1..times].map -> str).join ""

#
# Public: Индекс месяца в имя
#
#
_getMonthName = (ind) ->
  "ЯНВАРЬ:ФЕВРАЛЬ:МАРТ:АПРЕЛЬ:МАЙ:ИЮНЬ:ИЮЛЬ:АВГУСТ:СЕНТЯБРЬ:ОКТЯБРЬ:НОЯБРЬ:ДЕКАБРЬ".split(":")[ind] or "???"

#
# Public: Шапка календаря
#
_getCalHead = ->
  "|  пн  |  вт  |  ср  |  чт  |  пт  |  сб  |  вс  |"

#
# Public: День недели
#
_dayOfWeek = (date) ->
  _wd = date.getDay()
  if _wd is 0
    return 6
  return _wd - 1


#
# Public: Получить день недели первого числа месяца
#
_firstDayOfMonth = (date) ->
  day = new Date date
  day.setDate 1
  _dayOfWeek day
  

#
# Public: Получить последний день месяца
#
# http://learn.javascript.ru/task/poslednij-den-mesyaca
_getMaxDay = (date) ->
  day = new Date date.getFullYear(), date.getMonth()+1, 0
  day.getDate()


#
# Internal: Перевести число в код брайля
#
#
_intToDots = (num, color, inverse) ->
  # символы алфавита Брайля (http://en.wikipedia.org/wiki/Braille_Patterns)
  #" ⠁⠂⠃⠄⠅⠆⠇⠈⠉⠊⠋⠌⠍⠎⠏⠐⠑⠒⠓⠔⠕⠖⠗⠘⠙⠚⠛⠜⠝⠞⠟⠠⠡⠢⠣⠤⠥⠦⠧⠨⠩⠪⠫⠬⠭⠮⠯⠰⠱⠲⠳⠴⠵⠶⠷⠸⠹⠺⠻⠼⠽⠾⠿"
  #" ⡀⡄⡆⡇⡏⡟⡿⣿"
  if num < 9
    " •⡄⡆⡇⡏⡟⡿⣿"[num][color]
  else
    (" ⡀⡁⡂⡃⡄⡅⡆⡇⡈⡉⡊⡋⡌⡍⡎⡏⡐⡑⡒⡓⡔⡕⡖⡗⡘⡙⡚⡛⡜⡝⡞⡟⡠⡡⡢⡣⡤⡥⡦⡧⡨⡩⡪⡫⡬⡭⡮⡯⡰⡱⡲⡳⡴⡵⡶⡷⡸⡹⡺⡻⡼⡽⡾⡿⢀⢁⢂⢃⢄⢅⢆⢇⢈⢉⢊⢋⢌⢍⢎⢏⢐⢑⢒⢓⢔⢕⢖⢗⢘⢙⢚⢛⢜⢝⢞⢟⢠⢡⢢⢣⢤⢥⢦⢧⢨⢩⢪⢫⢬⢭⢮⢯⢰⢱⢲⢳⢴⢵⢶⢷⢸⢹⢺⢻⢼⢽⢾⢿⣀⣁⣂⣃⣄⣅⣆⣇⣈⣉⣊⣋⣌⣍⣎⣏⣐⣑⣒⣓⣔⣕⣖⣗⣘⣙⣚⣛⣜⣝⣞⣟⣠⣡⣢⣣⣤⣥⣦⣧⣨⣩⣪⣫⣬⣭⣮⣯⣰⣱⣲⣳⣴⣵⣶⣷⣸⣹⣺⣻⣼⣽⣾⣿"[num] or "∞")[inverse].inverse



#
# Public: Return calendar cell
#
#
_calendarCell = (day, is_today, todo=0, events=0) ->
  day       = if day > 9 then "#{day}" else " #{day}"
  day       = "#{day.magenta.bold}" if is_today
  todo_c    = _intToDots todo, "red", "yellow"
  events_c  = _intToDots events, "blue", "green"
  "#{events_c} #{day.white} #{todo_c}#{'|'.white}"

#
# Public: Отрисовать календарь в консоли
#
#
_drawCalendar = (d, dates) ->
  _year        = d.getFullYear()
  _month       = d.getMonth()
  _month_year  = ".#{_month}.#{_year}"
  # макс ширина для календаря
  max_width    = _getCalHead().length
  # создать шапку
  cal_str      = [ _dup("_", max_width).white ]
  cal_str.push _centerString("#{_getMonthName _month} #{_year}", max_width).white
  cal_str.push _dup("_", max_width).white
  cal_str.push _getCalHead().grey.inverse
  first_day    = _firstDayOfMonth d
  today        = d.getDate()
  s            = ["|".white]
  for j in [0...first_day]
    s.push _calendarCell " "
  _day = 1
  for j in [first_day...7]
    s.push _calendarCell _day, _day++ is today
  cal_str.push s.join ""

  max_day = _getMaxDay d

  while _day <= max_day
    s = ["|".white]
    for j in [0...7]
      ds      = "#{_day}#{_month_year}"
      events  = 0
      todo    = 0

      if _day <= max_day
        if dates[ds]?
          if dates[ds].events?
            events = dates[ds].events.length
          if dates[ds].todo?
            todo = dates[ds].todo.length
        s.push _calendarCell _day, _day is today, todo, events

      else
        s.push _calendarCell " "
      _day++

    cal_str.push s.join ""
  cal_str.push _dup("_", max_width).white
  cal_str.push "\n"
  console.log cal_str.join "\n"



#
# Internal: Символы для отображения в консоли
#
#
statusSymbols =
  "todo"     : symbol: "☐", color: "red", final: no
  "frozen"   : symbol: "❄", color: "blue", final: "frozen"
  "question" : symbol: "¿", color: "yellow", final: no
  "idea"     : symbol: "⚗", color: "magenta", final: no
  "bug"      : symbol: "⚒", color: "red", final: no
  "done"     : symbol: "☑", color: "green", final: yes
  "closed"   : symbol: "☒", color: "grey", final: yes
  "cancel"   : symbol: "☒", color: "grey", final: "cancel"
  "wontfix"  : symbol: "⚔", color: "grey", final: yes
  "fixed"    : symbol: "✪", color: "green", final: yes
  "merged"   : symbol: "⚭", color: "magenta", final: yes
  "pushed"   : symbol: "↦", color: "cyan", final: yes
  "event"    : symbol: "𝍔", color: "blue", final: "event"


#
# Internal: Начальные и конечные состояния
#
initialStates = []
finalStates   = []
hiddenStates  =  ["cancel"]
for k,v of statusSymbols
  if v.final is yes
    finalStates.push k
  else if v.final is no
    initialStates.push k


#
# Internal: Получить todo/events в словаре dates
#
# dates:
#  "DD.MM.YYYY":
#    events: [...]
#    todo:   [...]
#
#
_getTodoDates = (tasks) ->
  dates = {}
  for t in tasks
    if t.state is "event"
      d = new Date t.at
      ds = "#{d.getDate()}.#{d.getMonth()}.#{d.getFullYear()}"
      dates[ds] ||= {}
      dates[ds].events ||= []
      dates[ds].events.push t
    else if t.state in initialStates
      d = new Date t.created_at
      ds = "#{d.getDate()}.#{d.getMonth()}.#{d.getFullYear()}"
      dates[ds] ||= {}
      dates[ds].todo ||= []
      dates[ds].todo.push t
  dates


#
# Считать минимальные настройки
#
# :cf - конфиг
#
# :fn  - обратный вызов
#   :err - ошибка
#   :cf  - измененный конфиг
#
_readConfigData = (cf, fn) ->
  if cf.user.name is null
    cf.user.name = process.env.USER
  #cf.user.email ?
  fn null, cf

#
# Public: Загрузить файл с настройками
# :fn - обратный вызов
#   :err - ошибка
#   :cf  - конфиг
#
exports.loadConfig = (fn) ->
  try
    cf = JSON.parse fs.readFileSync home, "utf-8"
    _readConfigData cf, fn
  catch e
    cf = _defaultSettings()
    _readConfigData cf, (err, cf) ->
      unless err
        fs.writeFileSync home, JSON.stringify(cf)
      fn err, cf

#
# Public: Сохранить конфигурацию
#
exports.saveConfig = (cf) ->
  fs.writeFileSync home, JSON.stringify cf

# ----------------------------------------
# Вызовы каталогов
# ----------------------------------------

#
# Internal: Создать новый каталог
#
_createFolder = (user_name, name, is_public, order, can_remove=yes) ->
  now = Date.now()
  hash       : createHash name
  created_at : now
  updated_at : now
  owner_name : user_name
  name       : name
  order      : order
  can_remove : can_remove
  is_public  : is_public


#
# Internal: Создать объект с задачами
#
_defaultDataFile = (cf) ->
  data = folders: {}, tasks: {}, end_tasks: {} # hash - folder hash, tasks in array
  now = Date.now()
  for f,i in ["personal", "family", "work"]
    f = _createFolder cf.user.name, f, no, i, no
    data.folders[f.hash] = f
    if 0 is i
      data.defaultFolder =
        hash: f.hash
        name: f.name
  data

#
# Public: Создать каталог
#
exports.createFolder = (cf, data, folder, fn=->) ->
  lastOrder = 0
  for k,v of data.folders
    if v.order > lastOrder
      lastOrder = v.order
    if v.name.toLowerCase() is folder.name.toLowerCase()
      return fn msg: "каталог существует", null
  f = _createFolder cf.user.name, folder.name, folder.is_public, lastOrder+1
  data.folders[f.hash] = f
  fn null, data, f

#
# Public: Переименовать каталог
#
# :target  - целевые данные
#   :old_name  - старое имя каталога
#   :new_name  - новое имя каталога
#
exports.renameFolder = (cf, data, target, fn=->) ->
  for k,v of data.folders
    if v.name.toLowerCase() is target.old_name.toLowerCase()
      v.name = target.new_name
      if data.defaultFolder.hash is k
        data.defaultFolder.name = v.name
      return fn null
  fn msg:"исходный каталог не найден"


#
# Internal: Получить хеш каталога по имени
#
#
_getFolderHash = (name, folders) ->
  for k,v of folders
    if name.toLowerCase() is v.name.toLowerCase()
      return k
  null

#
# Public: Удалить каталог
#
exports.removeFolder = (cf, data, folder, fn=->) ->
  rmByHash = (data, hash) ->
    if data.folders[hash].can_remove 
      delete data.folders[hash]
      fn null, data
    else
      fn msg: "каталог защищен от удаления"

  for k,v of data.folders
    if folder.name?
      if v.name.toLowerCase() is folder.name.toLowerCase()
        return rmByHash data, k
        
    else if folder.hash?
      if 0 is v.hash.indexOf folder.hash
        return rmByHash data, k
    else
      return fn msg: "хеш или имя не указаны", null
  fn msg: "каталог не найден"


#
# Public: Показать статистику
#
exports.showStat = (tags, cf, userData) ->
  [show_summary, tags] = _findAndRemove tags, /^::total$/i
  folders_list = []             # список имен каталогов
  first_date = Date.now()
  last_date  = 1

  max_width = 60                # максимальная ширина
  if show_summary
    todo_count    = 0
    done_count    = 0
    events_count  = 0
    missed_count  = 0
  days_limit = cf.daysForTodo   # дней до просрочки

  # 
  # вывести статистику (встроенная функция)
  # ----
  _show_folder_stat = (after="\n\n") -> 
    total_count           = todo_count + done_count + events_count
    st_events_count       = parseInt _normalize events_count, total_count, max_width
    st_todo_intime_count  = parseInt _normalize todo_count - missed_count, total_count, max_width
    st_todo_missed_count  = parseInt _normalize  missed_count, total_count, max_width
# max_width - st_todo_intime_count
    st_done_count         = parseInt _normalize done_count, total_count, max_width

    console.log _dup("_", max_width).yellow
    console.log _centerString("СТАТИСТИКА", max_width).yellow
    console.log _dup("_", max_width).yellow

    console.log _dup("#", st_events_count).blue
    console.log _dup("#", st_todo_intime_count).yellow + _dup("#", st_todo_missed_count).red
    console.log _dup("#", st_done_count).green
    console.log _dup("_", max_width).yellow
    legend = [""
              "задач:\t\t#{total_count.toString().bold}\t(100.00%)",
              " активных:\t#{todo_count}\t(#{(100 * todo_count / (todo_count + done_count)).toFixed 2}%)".yellow,
              "   пропущенных:\t#{missed_count}\t(#{((100 * missed_count / todo_count) or 0).toFixed 2}%)".red,
              " завершённых:\t#{done_count}\t(#{(100 * done_count / (todo_count + done_count)).toFixed 2}%)".green,
              "событий:\t#{events_count}\t(#{(100 * events_count / total_count).toFixed 2}%)".blue,
              ""
             ]
    console.log legend.join "\n"
    console.log after
    # ----

  for k,v of userData.folders

    if tags.length > 0
      unless v.name in tags
        continue

    unless show_summary
      todo_count    = 0
      done_count    = 0
      events_count  = 0
      missed_count  = 0

    tasks         = userData.tasks[k] or []
    for t,i in tasks
      # временной период
      if t.created_at < first_date
        first_date = t.created_at
      if t.updated_at > last_date
        last_date = t.updated_at

      # подсчет событий и todo
      if t.state is "event"
        events_count++
      else if t.state in initialStates
        todo_count++
        days = parseInt (Date.now() - t.updated_at)/ 86400000
        if days > days_limit
          missed_count++
  
      else if t.state in finalStates
        done_count++
    if tasks.length > 0
      if show_summary
        folders_list.push v.name
      else  
        console.log _dup "-", max_width
        console.log "| #{v.name}"
        console.log _dup "-", max_width
        _show_folder_stat()


  if show_summary
    days = parseInt (last_date - first_date) / 86400000
    end_of_stat = ["дней:\t\t#{days}",
                   "задач в день:\t#{(done_count/days).toFixed(2).bold}",
                   _dup("_", max_width).yellow,
                   "\nКАТАЛОГИ:\t".bold + folders_list.join(" | ").cyan,
                   "\n\n"  
                  ]
    _show_folder_stat end_of_stat.join "\n"

# конец вызовов для каталогов
# ----------------------------------------


# ----------------------------------------
# Вызовы для задач
# ----------------------------------------

#
# Internal: Найти шаблон и удалить из исходного массива
#
#
_findAndRemove = (tags, pattern) ->
  result = []
  tag = null
  for t in tags
    if pattern.test t
      tag = t
    else
      result.push t
  [tag, result]


#
# Internal: Найти шаблон
#
#
_find = (tags, pattern) ->
  result = []
  for t in tags
    if pattern.test t
      result.push t 
  [result, tags]

#
# Internal: Найти шаблон `at:12.03.12-12:30`
#
# ВАРИАНТЫ
# at:12.03.10-12:30:50     # число, месяц, год, час, минута и секунда
# at:12.03.10-12:30        # число, месяц, год, час и минута
# at:12.03.10-12           # число, месяц, год и час
# at:12.03.10              # число, месяц и год
# at:12.03                 # число и месяц 
# at:12                    # число этого или след. месяца
# at:null                  # сброс at
#
#
_getAtTime = (tags) ->
  [at, tags] = _findAndRemove tags, /^at:([-\d\.\:]+|null)$/
  if at?
    at = at[3..]
    d = new Date
    # этот код - просто заглушка
    if /^\d\d$/.test at                     # число
      at = new Date d.getFullYear(), d.getMonth(), parseInt at
    else if /^\d\d\.\d\d$/.test at          # число и месяц
      [d,m] = at.split(".").map (x) -> parseInt x
      m--
      at = new Date d.getFullYear(), m, d
    else if /^\d\d\.\d\d\.\d{2,4}$/.test at # число, месяц и год
      [d, m, y] = at.split(".").map (x) -> parseInt x
      if y < 99
        y += 2000
      m--
      at = new Date y, m, d
    # else if /^\d\d\.\d\d\.\d{2,4}-\d\d$/.test at # число, месяц, год и час
    #   at = ...
    # else if /^\d\d\.\d\d\.\d{2,4}-\d\d\:\d\d$/.test at # число, месяц, год, час и минута
    #   at = ...
    # else if /^\d\d\.\d\d\.\d{2,4}-\d\d\:\d\d\:\d\d$/.test at # число, месяц, год, час, минута и секунда
    #   at = ...
    else
      return [null, tags, no]
    [at, tags, yes]
  else
    [null, tags, no]

#
# Internal: tags
#
#
_getRegular = (tags) ->
  [pattern, tags] = _findAndRemove tags, /^::\d\d?[mwdy]$/i
  unless pattern is null
    number = parseInt pattern[2..-2]
    scale = pattern[-1..]
    pattern = [number, scale]
  [pattern, tags]


#
# Internal: Получить упоминания
#
# Упоминание в тексте по имени через @UserName
# Упоминание не удаляется
# 
_getMentions = (tags) ->
  [mentions, tags] = _find tags, /\@[-_a-z]+/ig
  [_.unique(mentions), tags]

#
# Internal: Получить приоритетность задачи
#
# По умолчанию приоритет 0. Задается как `p:1`, `p:2`, ...
#
_getTaskPriority = (tags) ->
  [pr, tags] = _findAndRemove tags, /^p:-?\d$/i
  if pr?
    [parseInt(pr[2..]), tags, yes]
  else
    [0, tags, no]

#
# Internal: Получить индекс задачи
#
_fetchTaskIndex = (tags) ->
  num = tags.shift()                 # num or hash
  if /^\d+$/.test num
    opts = num: parseInt num
  else
    opts = hash: num
  [opts, tags]

#
# Internal: Проверить есть ли совпадения элементов
# из `source` в `dest`
#
# :source - исходный массив
# :dest   - массив-назначение
# :fullText - полный поиск по тексту
#
_matchInArray = (source, dest, fullText=no) ->
  for s in source
    if fullText
      if 0 <= dest.join(" ").toLowerCase().indexOf s.toLowerCase()
        return yes
    else if s in dest
      return yes
  no


#
# Internal: Кому делегирована
#
#
_delegatedTo = (tags) ->
  # to:@UserName
  null

#
# Internal: Получить состояние задачи
#
#
_getState = (tags) ->
  [state, tags] = _findAndRemove tags, /^::[a-z\d]+$/i
  if state?
    [state[2..].toLowerCase(), tags, yes]
  else
    ["todo", tags, no]

#
# Internal: Получить каталог
#  задается как to::work
#
#
_getFolder = (tags) ->
  [folder, tags] = _findAndRemove tags, /^to::[-a-z\.а-я\d]+$/i
  if folder is null
    [null, tags]
  else
    [folder[4..], tags]

#
# Internal: Получить хеш-теги
#
#
_getHashTags = (tags, splitter="+") ->
  re = new RegExp "^\\#{splitter}[a-zа-я]+[-a-zа-я\d]+$", "i"
  ht = []
  new_tags = []
  for t in tags
    if re.test t
      ht.push "##{t[1..]}"
      new_tags.push "##{t[1..]}"
    else
      new_tags.push t
  [ht, new_tags]

#
# Internal: Получить адреса url
#
_getUrls = (tags) ->
  _find tags, /^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/

#
# Internal: initialize tags
#
_initTask = (task) ->
  now                 = Date.now()
  task.hash           = createHash task.text
  task.delegated_to ||= null
  task.created_at     = now
  task.updated_at     = now
  task.times          = []



#
# Internal: Проверить уникальность задачи
#
#
_ensureUnique = (tasks, task) ->
  for t in tasks
    if t.hash is task.hash or t.text is task.text
      return no
  yes


#
# Internal: Обновить время изменения задачи
#
#
_touchTaskData = (task) ->
  task.updated_at        = Date.now()  

#
# Internal: Обновить данные по задачи из `tags`:
#
#   `hashtags`, `mention`, `urls`, `text`
#
_updateTaskData = (task, tags) ->
  [task.hashtags, tags]  = _getHashTags     tags
  [task.urls,     tags]  = _getUrls         tags
  [task.mention,  tags]  = _getMentions     tags
  task.text              = tags.join " "
  _touchTaskData  task


#
# Public: Проверить является ли задача повторяющейся,
#         и если да, проверить/обновить ее состояние
#
#
_updateRegular =  (t, task_index, userData, cf) ->
  nowDay = new Date()
  if t.regular   # todo fix code
    reg = t.regular.join ""
    if reg in ["1d", "d1"]          # every day
      d = new Date(t.updated_at).getDate()
      d2 = nowDay.getDate()
      if d isnt d2
        t.state = "todo"
        userData.tasks[t.folder_hash][task_index] = t
        storeData cf, userData


#
# Public: Добавить новую задачу
#
# новая задача может быть событием, обычной или регулярной задачей
#
exports.addTask = (tags, cf, userData, fn=->) ->
  taskData =
    folder_hash: userData.defaultFolder.hash
    owner_name: cf.user.name
      
  [taskData.at,       tags]  = _getAtTime       tags
  [taskData.priority, tags]  = _getTaskPriority tags
  [taskData.regular,  tags]  = _getRegular      tags
  [taskData.state,    tags]  = _getState        tags
  [folder,            tags]  = _getFolder       tags
  unless folder is null
    folder_hash = _getFolderHash folder, userData.folders
    unless folder_hash
      return fn msg: "каталог #{folder} не найден"
    taskData.folder_hash = folder_hash

  # event
  unless taskData.at is null
    taskData.state = "event"

  _updateTaskData taskData, tags
    #  todo add time_limit
  _initTask taskData

  userData.tasks[taskData.folder_hash] ||= []
  if _ensureUnique userData.tasks[taskData.folder_hash], taskData
    userData.tasks[taskData.folder_hash].unshift taskData
    # todo sort
    fn null, taskData
  else
    fn msg: "задача дублируется"


#
# Internal: Получить задачу по идентификатору
#
# :userData   - данные
# :opts
#   :num      - порядковый номер        | нужно выбрать любой
#   :hash     - начальные цифры хеша   | 
# :folderHash - хеш каталога (опция)
#
_getTask = (userData,  opts={}, folderHash=null) ->
  tasks = userData.tasks[folderHash or userData.defaultFolder.hash] or []
  if "number" is typeof opts.num and tasks[opts.num]?
    return [tasks[opts.num], opts.num]
  if opts.hash?
    for task,i of tasks         # todo check for hash duplicates
      if 0 is task.hash.indexOf opts.hash
        return [task, i]
  [null, null]


#
# Internal: Сохранить задачу
#
#
_saveTask = (userData, task, taskIndex, folderHash=null) ->
  folderHash ||= userData.defaultFolder.hash
  
  if task_index? and userData.tasks[folderHash][taskIndex]?
    userData.tasks[folderHash][taskIndex] = task
  else
    console.error "task index not set"


#
# Public: Удалить задачу
#
#
exports.removeTask = (tags, cf, userData, fn=->) ->
  [opts, tags] = _fetchTaskIndex tags
  [task, num] = _getTask userData, opts
  if task
    userData.tasks[userData.defaultFolder.hash].splice num, 1
    return fn null
  fn msg: "задача не найдена"

#
# Public: Переместить задачу
#
#
exports.moveTask = (tags, cf, userData, fn=->) ->
  [opts, tags] = _fetchTaskIndex tags
  [from, to] = tags
  if "undefined" is typeof from
    return fn msg: "не указаны каталоги для перемещения"
  if "undefined" is typeof to
    [from, to] = [userData.defaultFolder.name, from]

  from_hash = _getFolderHash from, userData.folders
  to_hash = _getFolderHash to, userData.folders
  if null in [from_hash, to_hash]
    return fn msg: "каталог не найден"

  [task, num] = _getTask userData, opts, from_hash


  if task

    userData.tasks[to_hash] ||= []
    if _ensureUnique userData.tasks[to_hash], task
      userData.tasks[to_hash].unshift task
      # todo sort
      userData.tasks[from_hash].splice num, 1
    else
      fn msg: "задача дублируется"

  else
    console.log "task = #{JSON.stringify task, null, 2}"
    return fn msg: "задача не найдена"

  fn null, task

#
# Public: Дела на сегодня
#
exports.todaysTasks = (tags, cf, userData, fn=-> ) ->
  for k,v of userData.folders
    # show folders
    foundOneTask = no
    tasks = []
    for t,i in userData.tasks[k] or []
      # сбросить состояние для повторяющихся задач
      _updateRegular t, i, userData, cf
 
      unless t.state in finalStates
        foundOneTask = yes  
        t.index = i
        tasks.push t
    if foundOneTask
      if v.name is userData.defaultFolder.name
        console.log "\n# #{v.name}".magenta
      else
        console.log "\n# #{v.name}"
      console.log "----------------------------------------"
    printTasks tasks, daysForTodo: cf.daysForTodo or 7


#
# Public: Обновить состояние задачи
#
#
exports.updateTask = (tags, cf, userData, fn=-> ) ->
  return fn msg: "не указаны параметры" if 0 is tags.length
  [opts, tags] = _fetchTaskIndex tags
  [task, num] = _getTask userData, opts
  unless task
    return fn msg: "задача не найдена"
  
  # task
  [pr, tags, found] = _getTaskPriority tags
  task.priority = pr if found
  [at, tags, found] = _getAtTime tags
  task.at = at if found
  [state, tags, found] = _getState tags
  if found
    task.state = state # todo move to ended tasks

  if tags.length > 0
    _updateTaskData task, tags
  else
    _touchTaskData  task


  fn null, task


#
# Public: Перевести задачу в событие
#
# `s tte 7 at:12.06.2014`
#
exports.toEvent = (tags, cf, userData, fn=-> ) ->
  return fn msg: "укажите задачу" if 0 is tags.length
  [opts, tags] = _fetchTaskIndex tags
  [task, num] = _getTask userData, opts
  return fn msg: "задача не найдена" if null is task
  [task.at, tags]  = _getAtTime tags
  if task.at
    task.state = "event"
    _touchTaskData task
    fn null, task
  else
    fn msg: "дата/время не указаны"


#
# Public: Перевести событие в задачу 
#
# `s ett 8`
# 
exports.toTask = (tags, cf, userData, fn=-> ) ->
  return fn msg: "укажите задачу" if 0 is tags.length
  [opts, tags] = _fetchTaskIndex tags
  [task, num] = _getTask userData, opts
  return fn msg: "задача не найдена" if null is task
  task.state = "todo"
  task.at = null
  _touchTaskData task
  fn null, task

#
# Public: Показать свойства задачи
#
exports.inspectTask = (tags, cf, userData, fn=->) ->
  return fn msg: "укажите задачу" if 0 is tags.length
  [opts, tags] = _fetchTaskIndex tags
  [task, num] = _getTask userData, opts
  if task
    console.log JSON.stringify task, null, 2
    fn null, task
  else
    fn msg: "задача не найдена"

#
# Public: Вывести календарь
#
#
exports.showCalendar = (tags, cf, userData, fn=->) ->
  d = new Date 

  tasks = []
  # собрать все задачи
  for k,v of userData.tasks
    for t in v
      tasks.push t
  dates = _getTodoDates tasks

  if tags.length is 0
    _drawCalendar new Date(), dates
  else
    if /^\d\d?$/.test tags[0]   # month
      d = new Date
      d.setMonth parseInt(tags[0]) - 1
      _drawCalendar d, dates
#
# Public: Показать список задач
#
exports.listTasks = (tags, cf, userData, fn=->) ->
  tasks = userData.tasks[userData.defaultFolder.hash] or []
  #maxVal = if "-a" in [tags] then 1000000 else 20
  search = null
  for t in tags
    if /^::[a-z]+$/i.test t
      search ||={}
      search.states ||= []
      search.states.push t.toLowerCase()[2..]
    else if /^\+[a-zа-я]+[-a-zа-я\d]+$/i.test t
      search ||={}
      search.hashtags ||= []
      search.hashtags.push "##{t[1..]}"
    else                         # filter options
      search ||={}
      search.words ||= []
      search.words.push t      


  _tasks = []
  for t,i in tasks
    _updateRegular t, i, userData, cf
    if search is null and i < 20 and not (t.state in finalStates) and not (t.state in hiddenStates)
      t.index = i
      _tasks.push t
    else
      try
        if search.states? and  t.state in search.states
          printTask t, index: i
        else if search.hashtags? and _matchInArray search.hashtags, t.hashtags
          printTask t, index: i, words: [[search.hashtags, "red"]]   # пометить совпадение
        else if search.words? and _matchInArray search.words, t.text.split(" "), yes
          printTask t, index: i, words: [[search.words, "red"]]   # пометить совпадение
      catch e
        "skip this step"

  printTasks _tasks, daysForTodo: cf.daysForTodo or 7

#
# Internal: Подсветить текст
#
# :text - исходный текст
# :words[] - массив совпадений, элементы - слова и цвет :  [words, color]
#
_colorizeText = (text, words=[]) ->
  result = []
  for word in text.split " "
    found = no
    for words_array in words
      break if found
      for w in words_array[0] or []
        ind = word.toLowerCase().indexOf w.toLowerCase()
        if 0 <= ind

          wrd = word.substring ind, ind+w.length
          wrd = w.bold[words_array[1]]
          if 0 is ind
            result.push "#{wrd}#{word.substring w.length}"
          else
            _word = "#{word.substring 0, ind}#{wrd}#{word.substring ind + w.length}"
            result.push _word
          found = yes
          break
    result.push word unless found      
  result.join " "


#
# Public: Вывести задачи в консоль
#
printTasks = (tasks, opts={}) ->
  tasksDict = {}
  names = []
  now = Date.now()
  for t in tasks                # make key, then sort
    name = "#{-t.priority}#{now - t.updated_at}"
    tasksDict[name] = t
    names.push name
  names.sort()

  for name,i in names
    t = tasksDict[name]
    opts.index = t.index
    printTask t, opts

#
# Public: Вывести задачу в консоль
#
exports.printTask = printTask = (task, opts={}) ->
  r = []
  flags = {}
  if task.priority > 0
    flags.p = "!"
    if task.priority > 2
      flags.p = "!".red
  else
    flags.p = " "
  if statusSymbols[task.state]?
    r.push "#{statusSymbols[task.state].symbol[statusSymbols[task.state].color]} "
  else
    r.push "☉ "
  r.push flags.p
  unless "undefined" is typeof opts.index
    r.push "#{opts.index}\t"
  else
    r.push " \t"

  if task.state is "event"
    lastField = r.pop()
    r.push lastField.replace "\t", "  "
    d = new Date task.at
    r.push "#{d.getDate()}.0#{d.getMonth()+1}.#{d.getFullYear().toString()[2..]}\t".blue
  else if task.regular          # regular task
    r.push "#{task.regular[0]}#{task.regular[1]}\t".yellow
  else
    # days for todo
    if opts.daysForTodo?
      days = parseInt (Date.now() - task.updated_at)/ 86400000
      if days < .4 * opts.daysForTodo
        r.push "\t"
      else if days < 0.9 * opts.daysForTodo
        r.push "#{days.toString().yellow}\t"
      else
        r.push "#{days.toString().red}\t"

  # color opts
  opts.words ||= []
  opts.words.unshift [task.hashtags, "magenta"] # add urls too?
  r.push _colorizeText task.text, opts.words
  console.log r.join ""


# конец вызовов для задач
# ----------------------------------------


#
# Public: Сохранить данные
#
exports.storeData = storeData = (cf, data) ->
  fs.writeFileSync cf.dataFile, JSON.stringify data, null, 2

#
# Public: Загрузить данные из файла 
#
exports.loadData = (cf, fn) ->
  try
    userData = JSON.parse fs.readFileSync cf.dataFile, "utf-8"
  catch e
    # создать новый файл
    userData = _defaultDataFile cf
    fs.writeFileSync cf.dataFile, JSON.stringify userData, null, 2
  fn null, userData
