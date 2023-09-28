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

--Transform objects into its string representation
---@param object table
---@param initalIdentation? string
---@param parents? table[]
---@return string
function Object.stringify(object, initalIdentation, parents)
  parents = parents or {}

  print('Parents: '..#parents)
  for index, value in ipairs(parents) do
    print('- '..tostring(value))
  end

  if type(object) ~= 'table' then
    return tostring(object)
  end

  if type(object.toString) == 'function' then
    return object.toString()
  elseif getmetatable(object) ~= nil and type(getmetatable(object).__tostring) == 'function' then
    return getmetatable(object).__tostring(object)
  end

  -- Hopefully, one day I will implement key sorting
  -- local keyTypesOrder = {
  --   'boolean',
  --   'number',
  --   'string',
  --   'table',
  --   'function',
  -- }

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
    end

    local stringifiedValue = value

    local valueIsEqualToAncestor, ancestorIndex = listContainsItemReverse(parents, value)
    local parentDeepLevel = valueIsEqualToAncestor and (#parents - ancestorIndex + 1) or nil

    if value == object then
      stringifiedValue = '[[Self]]'
    elseif valueIsEqualToAncestor then
      stringifiedValue = '[[Parent: '..parentDeepLevel..']]'
    elseif type(value) == 'table' then
      local clonedParents = cloneList(parents)
      table.insert(clonedParents, object)

      stringifiedValue = Object.stringify(value, identation..'  ', clonedParents)
    elseif type(value) == 'string' then
      stringifiedValue = ("'"..value.."'")
    end

    objectString = objectString..identation..'['..stringifiedKey..']: '..tostring(stringifiedValue)..',\n'
  end

  local metatable = getmetatable(object)
  if metatable ~= nil then
    local clonedParents = cloneList(parents)
    table.insert(clonedParents, object)

    objectString = objectString..'\n'..identation.."[[MetaTable]]: "..Object.stringify(metatable, identation..'  ', clonedParents)..',\n'
  end

  local debugMetatable = debug.getmetatable(object)
  if debugMetatable ~= nil then
    local clonedParents = cloneList(parents)
    table.insert(clonedParents, object)

    objectString = objectString..identation.."[[Debug: MetaTable]]: "..Object.stringify(debugMetatable, identation..'  ', clonedParents)..',\n'
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
