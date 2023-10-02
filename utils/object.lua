local cmd = require('utils.cmd')
local Object = {}


---Abstract class to extend other classes
---allowing an OOP prototype based pattern like in JavaScript
---@class Constructor
Object.Constructor = {}

---Allow classes to be callable to instantiate objects
---@param self { constructor: fun(...:unknown): table }
---@param ... unknown
---@return table
function Object.Constructor:__call(...)
  local instance = setmetatable({}, self)
  return self.constructor(instance, ...)
end

---
---@param object table
---@param property any
---@return boolean
function Object.hasProperty(object, property)
  if object[property] == nil then
    return false
  end

  return true
end

---
---@param object table
---@param property any
---@return boolean
function Object.hasOwnProperty(object, property)
  if rawget(object, property) == nil then
    return false
  end

  return true
end

---
---@param target table
---@param ... table Sources of objects to apply to the target
---@return table
function Object.assign(target, ...)
  local args = {...}

  for index, source in ipairs(args) do
    for key, value in pairs(source) do
      target[key] = value
    end
  end

  return target
end

---Print string representation of objects
function Object.print(object)
  print(Object.stringify(object))
end

---Helper functions for lists

---
---@param list any[] | nil
---@param item any
---@return boolean, number?
local function listContainsItem(list, item)
  if list == nil then
    return false
  end

  for index = 1, #list, 1 do
    if list[index] == item then
      return true, index
    end
  end

  return false
end

---
---@param list any[] | nil
---@param item any
---@return boolean, number?
local function listContainsItemReverse(list, item)
  if list == nil then
    return false
  end

  for index = #list, 1, -1 do
    if list[index] == item then
      return true, index
    end
  end

  return false
end

---
---@param list any[]
---@return any[]
local function cloneList(list)
  if list == nil then
    error("'list' cannot be 'nil'")
  end

  local clonedList = {}

  for index = 1, #list, 1 do
    clonedList[index] = list[index]
  end

  return clonedList
end

---
---@param str string
---@return string
local function scapeCharactersToScapeRepresentation(str)
  local scapeColor = cmd.colors.red

  local result = str
                 :gsub('\n', cmd.setStringANSIStyle('\\n', {color = scapeColor}))
                 :gsub('\r', cmd.setStringANSIStyle('\\r', {color = scapeColor}))
                 :gsub('\t', cmd.setStringANSIStyle('\\t', {color = scapeColor}))
                 :gsub('\v', cmd.setStringANSIStyle('\\v', {color = scapeColor}))
                 :gsub('\b', cmd.setStringANSIStyle('\\b', {color = scapeColor}))
                 :gsub('\f', cmd.setStringANSIStyle('\\f', {color = scapeColor}))

  return result
end

---
---@param str string
---@return string
local function nonPrintableCharactersToUnicode(str)
  local stringColor = cmd.colors.yellow
  local unicodeColor = cmd.colors.red

  local result = ''

  local charCodes = {str:byte(1, #str)}

  for index, charCode in ipairs(charCodes) do
    if (charCode >= 0 and charCode <= 7) or (charCode >= 14 and charCode <= 31) or (charCode >= 127 and charCode <= 159) then
      local unicodeChar = '\\u{'..string.format('%x', charCode)..'}'
      unicodeChar = cmd.setStringANSIStyle(unicodeChar, {color = unicodeColor})

      result = result..unicodeChar
    else
      local char = string.char(charCode)
      char = cmd.setStringANSIStyle(char, {color = stringColor})
  
      result = result..char
    end
  end

  return result
end

--Transform objects into its string representation
---@param object table
---@param initalIdentation? string
---@param parents? table[]
---@return string
function Object.stringify(object, initalIdentation, parents)
  parents = parents or {}

  if type(object) ~= 'table' then
    return tostring(object)
  end

  if type(object.toString) == 'function' then
    return object:toString(initalIdentation)
  elseif getmetatable(object) ~= nil and type(getmetatable(object).__tostring) == 'function' then
    return getmetatable(object).__tostring(object, initalIdentation)
  end

  local identation = '  '

  if type(initalIdentation) == 'string' then
    identation = initalIdentation
  end

  local emptyObjectString = '{\n'..identation:sub(1, identation:len() - 2)..'}'

  local objectString = '{\n'

  local function increaseIndentation()
    identation = identation..'  '
  end

  local function dicreaseIndentation()
    identation = identation:sub(1, identation:len() - 2)
  end

  local key, value = nil, nil

  while true do
    key, value = next(object, key)

    if key == nil then
      break
    end

    local stringifiedKey = key

    if type(key) == 'string' then
      stringifiedKey = "'"..key.."'"

      stringifiedKey = nonPrintableCharactersToUnicode(stringifiedKey)
      stringifiedKey = scapeCharactersToScapeRepresentation(stringifiedKey)
    else
      stringifiedKey = tostring(key)
    end

    -- Key ANSI Style
    if type(key) == 'number' or type(key) == 'boolean' then
      stringifiedKey = cmd.setStringANSIStyle(stringifiedKey, {color = cmd.colors.green})
    elseif type(key) == 'string' then
      stringifiedKey = cmd.setStringANSIStyle(stringifiedKey, {color = cmd.colors.yellow})
    elseif type(key) == 'table' then
      stringifiedKey = cmd.setStringANSIStyle(stringifiedKey, {color = cmd.colors.cyan})
    elseif type(key) == 'function' then
      stringifiedKey = cmd.setStringANSIStyle(stringifiedKey, {color = cmd.colors.magenta})
    end

    local stringifiedValue = value

    local valueIsEqualToAncestor, ancestorIndex = listContainsItemReverse(parents, value)
    local parentDeepLevel = valueIsEqualToAncestor and (#parents - ancestorIndex + 1) or nil

    if value == object then
      stringifiedValue = cmd.setStringANSIStyle('@Self', {isBold = true, color = cmd.colors.blue})
    elseif valueIsEqualToAncestor then
      stringifiedValue = cmd.setStringANSIStyle('@Parent(', {isBold = true, color = cmd.colors.blue})..cmd.setStringANSIStyle(parentDeepLevel, {color = cmd.colors.green})..cmd.setStringANSIStyle(')', {isBold = true, color = cmd.colors.blue})
    elseif type(value) == 'table' then
      local clonedParents = cloneList(parents)
      table.insert(clonedParents, object)

      stringifiedValue = Object.stringify(value, identation..'  ', clonedParents)
    elseif type(value) == 'string' then
      stringifiedValue = "'"..value.."'"

      stringifiedValue = nonPrintableCharactersToUnicode(stringifiedValue)
      stringifiedValue = scapeCharactersToScapeRepresentation(stringifiedValue)
    else
      stringifiedValue = tostring(stringifiedValue)
   end


    -- Value ANSI Style
    if type(value) == 'number' or type(value) == 'boolean' then
      stringifiedValue = cmd.setStringANSIStyle(stringifiedValue, {color = cmd.colors.green})
    elseif type(value) == 'string' then
      stringifiedValue = cmd.setStringANSIStyle(stringifiedValue, {color = cmd.colors.yellow})
    elseif type(value) == 'function' then
      stringifiedValue = cmd.setStringANSIStyle(stringifiedValue, {color = cmd.colors.magenta})
    end

    objectString = objectString..identation..'['..stringifiedKey..']: '..stringifiedValue..',\n'
  end

  local metatable = getmetatable(object)
  if metatable ~= nil then
    local clonedParents = cloneList(parents)
    table.insert(clonedParents, object)

    local metatableKey = cmd.setStringANSIStyle('[', {isBold = true, color = cmd.colors.blue})
    metatableKey = metatableKey..cmd.setStringANSIStyle('MetaTable', {isItalic = true, isBold = true, color = cmd.colors.blue})
    metatableKey = metatableKey..cmd.setStringANSIStyle(']', {isBold = true, color = cmd.colors.blue})

    objectString = objectString..'\n'..identation..'['..metatableKey..']: '..Object.stringify(metatable, identation..'  ', clonedParents)..',\n'
  end

  local debugMetatable = debug.getmetatable(object)
  if debugMetatable ~= nil and debugMetatable ~= metatable then
    local clonedParents = cloneList(parents)
    table.insert(clonedParents, object)

    local debugeMetatableKey = cmd.setStringANSIStyle('['..cmd.setStringANSIStyle('Debug: MetaTable', {isItalic = true})..']', {isBold = true, color = cmd.colors.blue})

    objectString = objectString..identation..debugeMetatableKey..": "..Object.stringify(debugMetatable, identation..'  ', clonedParents)..',\n'
  end

  dicreaseIndentation()
  objectString = objectString..identation..'}'
  increaseIndentation()

  if objectString == emptyObjectString then
    return '{}'
  end

  return objectString
end

return Object
