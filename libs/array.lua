local Object = require('utils.object')
local Constructor = require('utils.object').Constructor
local Iterator    = require('libs.iterator')
local Number      = require('utils.number')
local cmd = require('utils.cmd')

---
---@class ArrayClass
---@overload fun(initialItems?: any[] | ArrayInstance): ArrayInstance
---@field private constructor fun(self: ArrayInstance, initialItems?: any[] | ArrayInstance): ArrayInstance
local Array = setmetatable({}, Constructor)

---
---@class ArrayInstance: ArrayPrototype
---#end

---
---@class ArrayPrototype: ArrayReadOnlyProperties
Array.prototype = {}

---
---@class ArrayReadOnlyProperties: ArrayPrototypeMethods
---@field length number
---@diagnostic disable
local readOnlyPropertiesType = setmetatable({
  length = 'number'
}, {
  __tostring = function(self, initalIdentation)
    local identation = '  '

    if type(initalIdentation) == 'string' then
      identation = initalIdentation
    end

    local function increaseIndentation()
      identation = identation..'  '
    end
  
    local function dicreaseIndentation()
      identation = identation:sub(1, identation:len() - 2)
    end

    local objectStringify = ''

    objectStringify = objectStringify..'{\n'

    for key, value in pairs(self) do
      local stringifiedKey = key

      -- Key ANSI Style
      stringifiedKey = cmd.setStringANSIStyle(stringifiedKey, {color = cmd.colors.yellow})

      local stringifiedValue = value

      -- Value ANSI Style
      if value == 'number' then
        stringifiedValue = cmd.setStringANSIStyle(stringifiedValue, {color = cmd.colors.green})
      elseif value == 'string' then
        stringifiedValue = cmd.setStringANSIStyle(stringifiedValue, {color = cmd.colors.yellow})
      elseif value == 'table' then
        stringifiedValue = cmd.setStringANSIStyle(stringifiedValue, {color = cmd.colors.blue})
      elseif value == 'function' then
        stringifiedValue = cmd.setStringANSIStyle(stringifiedValue, {color = cmd.colors.magenta})
      end

      objectStringify = objectStringify..identation..stringifiedKey..': '..stringifiedValue..',\n'
    end

    dicreaseIndentation()
    objectStringify = objectStringify..identation..'}'
    increaseIndentation()

    return objectStringify
  end
})

---
---@class ArrayReadOnlyPropertiesInstancesMap
---@field [ArrayInstance] ArrayReadOnlyProperties
local readOnlyProperties = setmetatable({}, {__mode = 'k'})

local keyReadOnly = setmetatable({}, {__tostring = function() return '[readonly]' end})

---
---@class ArrayPrototypeMethods: ArrayGetAccesors
local prototypeMethods = {}

local keyGet = setmetatable({}, {__tostring = function() return '[get]' end})
local keySet = setmetatable({}, {__tostring = function() return '[set]' end})

---
---@class ArrayPrototypeAccesors
local prototypeAccesors = {
  ---
  ---@class ArrayGetAccesors
  get = {},

  ---
  ---@class ArraySetAccesors
  set = {}
}

---
---@param self ArrayInstance
---@param key any
---@return any
function Array.__index(self, key)
  if key == nil then
    error("'nil' is not a valid index")
  end

  local readOnlyValue = readOnlyProperties[self][key]

  if readOnlyValue ~= nil then
    return readOnlyValue
  end

  local method = prototypeMethods[key]

  if method ~= nil then
    return method
  end

  local getter = prototypeAccesors.get[key]

  if getter ~= nil then
    return getter(self)
  end
end

---
---@param self ArrayInstance
---@param key any
---@param value any
function Array.__newindex(self, key, value)
  if key == nil then
    error("'nil' is not a valid index")
  end

  local readOnlyValue = readOnlyProperties[self][key]

  if readOnlyValue ~= nil then
    error("Cannot set readonly property: '"..key.."'")
  end

  local setter = prototypeAccesors.set[key]

  if setter ~= nil then
    setter(self, value)
    return
  end

  -- Handle number properties
  if type(key) == 'number' then
    if Number.isNaN(key) then
      error("'NaN' is not a valid index")
    elseif not Number.isFinite(key) then
      error("index must be a finite number: '"..key.."'")
    elseif math.type(key) == 'integer' then
      rawset(self, key, value)
      return
    elseif math.type(key) == 'float' then
      error("Cannot use decimal numbers as index: "..key)
    else
      error("Invalid numeric value to use as index: "..key)
    end
  end

  if self[key] == nil then
    error("Cannot set undeclared property '"..key.."'")
  end
end

--- Turn instances of Array into callable objects
---```lua
---local instance = Array()
---local result = instance()  
---```
---@param self ArrayInstance
---@return IteratorInstance
function Array.__call(self)
  return self:values()
end

---
---@param self ArrayInstance
---@param initialItems? any[] | ArrayInstance
---@return ArrayInstance
function Array.constructor(self, initialItems)
  readOnlyProperties[self] = {
    length = 0
  }

  if initialItems == nil then
    return self
  end

  if Array.isArray(initialItems) then
    for index = 1, initialItems.length, 1 do
      local value = rawget(initialItems, index)
      rawset(self, index, value)
    end

    readOnlyProperties[self].length = initialItems.length
  elseif type(initialItems) == 'table' then
    if #initialItems == 0 then
      rawset(self, 1, initialItems)

      readOnlyProperties[self].length = 1
    else
      for index = 1, #initialItems, 1 do
        rawset(self, index, initialItems[index])
      end
  
      readOnlyProperties[self].length = #initialItems
    end
  end

  return self
end

---
---@param array ArrayInstance
---@return function
function Array.generatorFunctionFromArray(array)
  return function()
    for index = 1, array.length, 1 do
      local value = rawget(array, index)
      coroutine.yield(value, index)
    end
  end
end

---
---@param self ArrayClass
---@param array ArrayInstance | unknown
---@return boolean
---@nodiscard
function Array.isArray(array)
  return readOnlyProperties[array] ~= nil
end

---
---@param self ArrayInstance
---@param ... any
---@return ...
function prototypeMethods.push(self, ...)
  local values = {...}

  for index = 1, #values, 1 do
    local value = values[index]

    readOnlyProperties[self].length = self.length + 1
    rawset(self, self.length, value)
  end

  return ...
end

---
---@param self ArrayInstance
---@return any
function prototypeMethods.pop(self)
  local poppedItem = self[self.length]

  self[self.length] = nil
  readOnlyProperties[self].length = self.length - 1

  return poppedItem
end

---
---@param self ArrayInstance
---@param ... any
---@return ...
function prototypeMethods.unshift(self, ...)
  local values = {...}

  for index = self.length, 1, -1 do
    rawset(self, index + #values, rawget(self, index))
  end

  for index = 1, #values, 1 do
    rawset(self, index, values[index])
  end

  readOnlyProperties[self].length = self.length + #values

  return ...
end

---
---@param self ArrayInstance
---@return any
function prototypeMethods.shift(self)
  local shiftedItem = self[1]

  for index = 2, self.length, 1 do
    self[index - 1] = self[index]
  end

  self[self.length] = nil
  readOnlyProperties[self].length = self.length - 1

  return shiftedItem
end

---
---@param self ArrayInstance
---@return IteratorInstance
---@nodiscard
function prototypeMethods.values(self)
  local generatorFunction = Array.generatorFunctionFromArray(self)
  return Iterator(generatorFunction)
end

---
---@param self ArrayInstance
---@return ArrayInstance
---@nodiscard
function prototypeMethods.clone(self)
  local array = Array()

  for index = 1, self.length, 1 do
    local value = rawget(self, index)
    rawset(array, index, value)
  end

  readOnlyProperties[array].length = self.length

  return array
end

---
---@param self ArrayInstance
---@param item any
---@return boolean
---@nodiscard
function prototypeMethods.contains(self, item)
  for index = 1, self.length, 1 do
    if self[index] == item then
      return true
    end
  end

  return false
end

---
---@param self ArrayInstance
---@param from number
---@param to? number
---@return ArrayInstance
---@nodiscard
function prototypeMethods.slice(self, from, to)
  if type(from) ~= 'number' then
    error("'from' must be a number")
  end

  to = to == nil and self.length or to

  if type(to) ~= 'number' then
    error("'to' must be a number")
  end

  if from == 0 or to == 0 then
    error("'from' or 'to' cannot be 0")
  end

  local computedFrom = from
  local computedTo = to

  if computedFrom > self.length then
    computedFrom = computedFrom % self.length + math.floor(computedFrom / self.length)
  elseif computedFrom < 0 then
    computedFrom = (computedFrom % self.length) + 1 - math.ceil(computedFrom / self.length)
  end

  if computedTo > self.length then
    computedTo = computedTo % self.length + math.floor(computedTo / self.length)
  elseif computedTo < 0 then
    computedTo = computedTo % self.length - math.ceil(computedTo / self.length)
  end

  local array = Array()

  for index = computedFrom, computedTo, 1 do
    array[index - computedFrom + 1] = self[index]
  end

  readOnlyProperties[array].length = computedTo - computedFrom + 1

  return array
end

---
---@param self ArrayInstance
---@param index number
---@return any
---@nodiscard
function prototypeMethods.at(self, index)
  if type(index) ~= 'number' then
    error("'index' must be a number")
  end

  if index == 0 then
    error("'index' cannot be 0")
  end

  local computedIndex = index

  print('index', computedIndex)

  if computedIndex > self.length then
    computedIndex = computedIndex % self.length + math.floor(computedIndex / self.length)
  elseif computedIndex < 0 then
    computedIndex = (computedIndex % self.length) + 1 - math.ceil(computedIndex / self.length)
  end

  local value = self[computedIndex]

  if value == nil then
    value = null
  end

  return value
end

---Sets the value at the given index and returns the old value
---@param self ArrayInstance
---@param index number
---@param value any
---@return any
---@nodiscard
function prototypeMethods.setAt(self, index, value)
  if type(index) ~= 'number' then
    error("'index' must be a number")
  end

  if index == 0 then
    error("'index' cannot be 0")
  end

  local computedIndex = index

  print('index', computedIndex)

  if computedIndex > self.length then
    computedIndex = computedIndex % self.length + math.floor(computedIndex / self.length)
  elseif computedIndex < 0 then
    computedIndex = (computedIndex % self.length) + 1 - math.ceil(computedIndex / self.length)
  end

  local oldValue = self[computedIndex]

  if oldValue == nil then
    oldValue = null
  end

  self[computedIndex] = value

  return oldValue
end

---
---@param self ArrayInstance
---@param ... ArrayInstance | any[] | any
---@return ArrayInstance
---@nodiscard
function prototypeMethods.concat(self, ...)
  local concatenatedArray = Array()

  local arrays = {...}

  for index = 1, self.length, 1 do
    local value = rawget(self, index)
    concatenatedArray:push(value)
  end

  for i = 1, #arrays, 1 do
    local array = arrays[i]

    if not Array.isArray(array) then
      if type(array) == 'table' then
        array = Array(array)
      else
        concatenatedArray:push(array)
        goto continue
      end
    end

    for index = 1, array.length, 1 do
      local value = rawget(array, index)
      concatenatedArray:push(value)
    end

    ::continue::
  end

  return concatenatedArray
end

---
---@param self ArrayInstance
---@param deep? number
---@return ArrayInstance
---@nodiscard
function prototypeMethods.flat(self, deep)
  deep = deep or 1

  if deep < 0 then
    error("'deep' parameter cannot be less than 0")
  end

  if deep == 0 then
    return self:clone()
  end

  local flattendArray = Array()

  for index = 1, self.length, 1 do
    ---@type ArrayInstance | unknown
    local value = self[index]

    if Array.isArray(value) then
      local innerFlattenedArray = value:flat(deep > 0 and deep - 1 or 0)

      for innerIndex = 1, innerFlattenedArray.length, 1 do
        flattendArray:push(innerFlattenedArray[innerIndex])
      end
    else
      flattendArray:push(value)
    end
  end

  return flattendArray
end



Object.assign(
  Array.prototype,

  prototypeMethods,
  {
    [keyReadOnly] = readOnlyPropertiesType,
    [keyGet] = prototypeAccesors.get,
    [keySet] = prototypeAccesors.set
  }
)

return Array
