local Object = require('utils.object')
local Constructor = require('utils.object').Constructor
local Iterator    = require('libs.iterator')
local Number      = require('utils.number')
local cmd = require('utils.cmd')

---
---@class ArrayClass
---@overload fun(initialItems?: any[] | ArrayInstance | string): ArrayInstance
---@field private constructor function
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
      if key < 1 then
        error("index cannot be equal or lower than 0")
      end

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
---@param initialItems? any[] | ArrayInstance | string | integer
---@return ArrayInstance
function Array.constructor(self, initialItems)
  readOnlyProperties[self] = {
    length = 0
  }

  if initialItems == nil then
    return self
  end

  if type(initialItems) == 'number' then
    if math.type(initialItems) ~= 'integer' or initialItems < 0 then
      error("If the argument it's a number, it must be a positive integer to specify the length of the Array")
    end

    readOnlyProperties[self].length = initialItems
  elseif Array.isArray(initialItems) then
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
  elseif type(initialItems) == 'string' then
    for index = 1, initialItems:len(), 1 do
      rawset(self, index, initialItems:sub(index, index))
    end

    readOnlyProperties[self].length = initialItems:len()
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
---@param any ...
---@return ArrayInstance
---@nodiscard
function Array.of(...)
  return Array({...})
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
    if rawget(self, index) == item then
      return true
    end
  end

  return false
end

---
---@overload fun(self: ArrayInstance): integer
---@param self ArrayInstance
---@param randomIntFunc? fun(from: integer, to: integer): integer
---@return unknown
---@nodiscard
function prototypeMethods.randomItem(self, randomIntFunc)
  if randomIntFunc ~= nil and type(randomIntFunc) ~= 'function' then
    error("'randomIntFunc' must be a function or not specified")
  end

  randomIntFunc = randomIntFunc ~= nil and randomIntFunc or math.random

  local randomIndex = randomIntFunc(1, self.length)

  if math.type(randomIndex) ~= 'integer' then
    error("random 'index' must be an integer")
  end

  if randomIndex < 1 or randomIndex > self.length then
    error("random 'index' is out of bounds: "..randomIndex)
  end

  return self[randomIndex]
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

  if from > self.length then
    return Array()
  end

  if from < 0 and math.abs(from) >= self.length then
    return self:clone()
  end

  local computedFrom = Number.rotateIfOutOfRange(from, 1, self.length)
  local computedTo

  if to > self.length then
    computedTo = self.length
  else
    computedTo = Number.rotateIfOutOfRange(math.min(to, self.length), 1, self.length)
  end

  if from < 0 then
    computedFrom = computedFrom + 1
  end

  local array = Array()

  for index = computedFrom, computedTo, 1 do
    rawset(array, index - computedFrom + 1, rawget(self, index))
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

  local computedIndex = Number.rotateIfOutOfRange(index, 1, self.length)

  if index < 0 then
    computedIndex = computedIndex + 1
  end

  local value = rawget(self, computedIndex)

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

  local computedIndex = Number.rotateIfOutOfRange(index, 1, self.length)

  if index < 0 then
    computedIndex = computedIndex + 1
  end

  local oldValue = rawget(self, computedIndex)

  rawset(self, computedIndex, value)

  return oldValue
end

---
---@param self ArrayInstance
---@param ... ArrayInstance | any[] | any
---@return ArrayInstance
---@nodiscard
function prototypeMethods.concat(self, ...)
  local concatenatedArray = self:clone()

  local arrays = {...}

  for i = 1, #arrays, 1 do
    local array = arrays[i]

    if not Array.isArray(array) then
      if type(array) == 'table' and #array > 0 then
        for index = 1, #array, 1 do
          local value = array[index]
          concatenatedArray:push(value)
        end
      else
        concatenatedArray:push(array)
      end

      goto continue
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

  if math.type(deep) ~= 'integer' or deep < 0 then
    error("'deep' must be an integer greater than 0")
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

---
---@param self ArrayInstance
---@param separator? string
---@return string
function prototypeMethods.join(self, separator)
  separator = separator or ', '

  if type(separator) ~= 'string' then
    error("'separator' must be a string")
  end

  local result = ''

  for index = 1, self.length - 1, 1 do
    ---@type string
    local stringItem = rawget(self, index)
    result = result..stringItem..separator
  end

  result = result..rawget(self, self.length)

  return result
end

---
---@generic T: ArrayInstance
---@param self T
---@param callback fun(item: unknown, index?: number, array?: T)
function prototypeMethods.forEach(self, callback)
  if type(callback) ~= 'function' then
    error("'callback' must be a function")
  end

  for index = 1, self.length, 1 do
    local item = rawget(self, index)
    callback(item, index, self)
  end
end

---
---@generic T: ArrayInstance, R
---@param self T
---@param callback fun(item: unknown, index?: number, array?: T): R
---@return ArrayInstance
---@nodiscard
function prototypeMethods.map(self, callback)
  if type(callback) ~= 'function' then
    error("'callback' must be a function")
  end

  local mappedArray = Array()

  for index = 1, self.length, 1 do
    local item = rawget(self, index)
    local value = callback(item, index, self)

    rawset(mappedArray, index, value)
  end

  readOnlyProperties[mappedArray].length = self.length

  return mappedArray
end

---
---@generic T: ArrayInstance, R, A
---@param self T
---@param callback fun(accumulator: A, item: unknown, index?: number, array?: T): A
---@param initialAccumulator A
---@param direction 1 | -1
---@return A
---@nodiscard
function prototypeMethods.reduce(self, callback, initialAccumulator, direction)
  if type(callback) ~= 'function' then
    error("'callback' must be a function")
  end

  if direction ~= 1 and direction ~= -1 then
    error("'direction' must 1 or -1")
  end

  local accumulator = initialAccumulator

  local from = direction == 1 and 1 or self.length
  local to = direction == -1 and 1 or self.length

  for index = from, to, direction do
    local item = rawget(self, index)

    accumulator = callback(accumulator, item, index, self)
  end

  return accumulator
end

---
---@generic T: ArrayInstance, R, A
---@param self T
---@param callback fun(accumulator: A, item: unknown, index?: number, array?: T): A
---@param initialAccumulator A
---@return A
---@nodiscard
function prototypeMethods.reduceStart(self, callback, initialAccumulator)
  return self:reduce(callback, initialAccumulator, 1)
end

---
---@generic T: ArrayInstance, R, A
---@param self T
---@param callback fun(accumulator: A, item: unknown, index?: number, array?: T): A
---@param initialAccumulator A
---@return A
---@nodiscard
function prototypeMethods.reduceEnd(self, callback, initialAccumulator)
  return self:reduce(callback, initialAccumulator, -1)
end

---
---@param self ArrayInstance
---@param index1 number
---@param index2 number
function prototypeMethods.swapItems(self, index1, index2)
  if math.type(index1) ~= 'integer' then
    error("'index1' must be an integer")
  end

  if math.type(index2) ~= 'integer' then
    error("'index2' must be an integer")
  end

  local value1 = rawget(self, index1)
  local value2 = rawget(self, index2)

  rawset(self, index1, value2)
  rawset(self, index2, value1)
end

---
---@generic T: ArrayInstance
---@param self T
---@return T
function prototypeMethods.reverse(self)
  local length = math.floor(self.length / 2)

  for index = 1, length, 1 do
    local reversedIndex = self.length - index + 1

    self:swapItems(index, reverseIndex)
  end

  return self
end

---
---@param self ArrayInstance
---@return ArrayInstance
function prototypeMethods.toReversed(self)
  local reversedArray = Array()

  for index = 1, self.length, 1 do
    local reversedIndex = self.length - index + 1
    local item = rawget(self, reversedIndex)

    rawset(reversedArray, index, item)
  end

  readOnlyProperties[reversedArray].length = self.length

  return reversedArray
end

---
---@param self ArrayInstance
---@param callback fun(item1, item2): number
---@return ArrayInstance
function prototypeMethods.sort(self, callback)
  if type(callback) ~= 'function' then
    error("'callback' must be a function")
  end

  while true do
    local isIterationSorted = true

    for index = 1, self.length - 1, 1 do
      local item1 = rawget(self, index)
      local item2 = rawget(self, index + 1)

      local sortNumber = callback(item1, item2)

      if sortNumber > 0 then
        isIterationSorted = false
        self:swapItems(index, index + 1)
      elseif sortNumber < 0 then
        --
      elseif sortNumber ~= 0 then
        error("The return value of the sort callback must be a number")
      else
      end
    end

    if isIterationSorted then
      break
    end
  end

  return self
end

---
---@param self ArrayInstance
---@param callback fun(item1, item2): number
---@return ArrayInstance
---@nodiscard
function prototypeMethods.toSorted(self, callback)
  return self:clone():sort(callback)
end

---Returns Array of deleted items
---@param self ArrayInstance
---@param start integer
---@param deleteCount? integer
---@return ArrayInstance
function prototypeMethods.delete(self, start, deleteCount)
  if math.type(start) ~= 'integer' then
    error("'start' must be an integer")
  end

  deleteCount = deleteCount or 1

  if math.type(deleteCount) ~= 'integer' or deleteCount < 1 then
    error("'deleteCount' must be a positive non 0 integer or not specified")
  end

  local deletedItems = Array()

  for index = start, start + deleteCount - 1, 1 do
    local itemToBeDeleted = rawget(self, index)
    deletedItems:push(itemToBeDeleted)

    rawset(self, index, nil)
  end

  for index = start, self.length - deleteCount, 1 do
    self:swapItems(index, index + deleteCount)
  end

  readOnlyProperties[self].length = self.length - deleteCount

  return deletedItems
end

---Returns a new Array without the deleted items
---and Array containing the deleted items
---@param self ArrayInstance
---@param start integer
---@param deleteCount? integer
---@return ArrayInstance, ArrayInstance
function prototypeMethods.toDeleted(self, start, deleteCount)
  local arrayWithDeletedItems = self:clone()

  local deletedItems = arrayWithDeletedItems:delete(start, deleteCount)

  return arrayWithDeletedItems, deletedItems
end

---
---@param self ArrayInstance
---@param start integer
---@param replaceCount integer
---@param any ... Items to insert in place of the replaced items
---@return ArrayInstance
function prototypeMethods.replace(self, start, replaceCount, ...)
  if math.type(start) ~= 'integer' then
    error("'start' must be an integer")
  end

  if math.type(replaceCount) ~= 'integer' or replaceCount < 1 then
    error("'replaceCount' must be a positive non 0 integer or not specified")
  end

  local deletedItems = Array()

  for index = start, start + replaceCount - 1, 1 do
    local itemToBeDeleted = rawget(self, index)
    deletedItems:push(itemToBeDeleted)

    rawset(self, index, nil)
  end

  local itemsToInsert = {...}

  if #itemsToInsert > replaceCount then
    local arraySizeIncrement = #itemsToInsert - replaceCount

    for index = self.length, start + replaceCount, -1 do
      rawset(self, index + arraySizeIncrement, rawget(self, index))
    end

    readOnlyProperties[self].length = self.length + arraySizeIncrement
  end

  for index = start, start + #itemsToInsert - 1, 1 do
    rawset(self, index, itemsToInsert[index - start + 1])
  end

  return deletedItems
end

---
---@param self ArrayInstance
---@param start integer
---@param replaceCount? integer
---@param any ... Items to insert in place of the replaced items
---@return ArrayInstance, ArrayInstance
function prototypeMethods.toReplaced(self, start, replaceCount, ...)
  local arrayWithReplaceItems = self:clone()

  local replacedItems = self:replace(start, replaceCount, ...)

  return arrayWithReplaceItems, replacedItems
end

---
---@param self ArrayInstance
---@param start integer
---@param insertPosition 1 | -1
---@param any ... Items to insert before or after the index provided
---@return ArrayInstance
function prototypeMethods.insert(self, start, insertPosition, ...)
  if math.type(start) ~= 'integer' then
    error("'start' must be an integer")
  end

  if insertPosition ~= 1 and insertPosition ~= -1 then
    error("'insertPosition must 1 or -1")
  end

  local itemsToInsert = {...}

  if #itemsToInsert == 0 then
    error("Must specify items to insert")
  end

  local indexBeforeInsertedItems = start + (insertPosition == 1 and 1 or 0)

  for index = self.length, indexBeforeInsertedItems, -1 do
    rawset(self, index + #itemsToInsert, rawget(self, index))
  end

  for index = indexBeforeInsertedItems, indexBeforeInsertedItems + #itemsToInsert - 1, 1 do
    rawset(self, index, itemsToInsert[index - indexBeforeInsertedItems + 1])
  end

  readOnlyProperties[self].length = self.length + #itemsToInsert

  return self
end

---
---@param self ArrayInstance
---@param start integer
---@param insertPosition 1 | -1
---@param any ... Items to insert before or after the index provided
---@return ArrayInstance
function prototypeMethods.toInserted(self, start, insertPosition, ...)
  return self:clone():insert(start, insertPosition, ...)
end

---
---@param self ArrayInstance
---@param start integer
---@param any ... Items to insert before the index provided
---@return ArrayInstance
function prototypeMethods.insertBefore(self, start, ...)
  return self:insert(start, -1, ...)
end

---
---@param self ArrayInstance
---@param start integer
---@param any ... Items to insert before the index provided
---@return ArrayInstance
function prototypeMethods.toInsertedBefore(self, start, ...)
  return self:clone():insertBefore(start, ...)
end

---
---@param self ArrayInstance
---@param start integer
---@param any ... Items to insert after the index provided
---@return ArrayInstance
function prototypeMethods.insertAfter(self, start, ...)
  return self:insert(start, 1, ...)
end

---
---@param self ArrayInstance
---@param start integer
---@param any ... Items to insert after the index provided
---@return ArrayInstance
function prototypeMethods.toInsertedAfter(self, start, ...)
  return self:clone():insertAfter(start, ...)
end

---
---@param self ArrayInstance
---@param searchItem unknown
---@param fromIndex? integer
---@return integer
---@nodiscard
function prototypeMethods.indexOf(self, searchItem, fromIndex)
  fromIndex = fromIndex or 1

  if math.type(fromIndex) ~= 'integer' or fromIndex < 1 or fromIndex > self.length then
    error("'fromIndex' must be an integer greater than 0 and less than the array length ("..self.length..")")
  end

  for index = fromIndex, self.length, 1 do
    if rawget(self, index) == searchItem then
      return index
    end
  end

  return -1
end

---
---@param self ArrayInstance
---@param searchItem unknown
---@param fromIndex? integer
---@return integer
---@nodiscard
function prototypeMethods.lastIndexOf(self, searchItem, fromIndex)
  fromIndex = fromIndex or self.length

  if math.type(fromIndex) ~= 'integer' or fromIndex < 1 or fromIndex > self.length then
    error("'fromIndex' must be an integer greater than 0 and less than the array length ("..self.length..")")
  end

  for index = fromIndex, 1, -1 do
    if rawget(self, index) == searchItem then
      return index
    end
  end

  return -1
end

---
---@param self ArrayInstance
---@param callback fun(item: unknown, index: integer, array: ArrayInstance): boolean
---@param fromIndex? integer
---@return integer
---@nodiscard
function prototypeMethods.findIndex(self, callback, fromIndex)
  fromIndex = fromIndex or 1

  if math.type(fromIndex) ~= 'integer' or fromIndex < 1 or fromIndex > self.length then
    error("'fromIndex' must be an integer greater than 0 and less than the array length ("..self.length..")")
  end

  for index = fromIndex, self.length, 1 do
    local item = rawget(self, index)

    if callback(item, index, self) then
      return index
    end
  end

  return -1
end

---
---@param self ArrayInstance
---@param callback fun(item: unknown, index: integer, array: ArrayInstance): boolean
---@param fromIndex? integer
---@return integer
---@nodiscard
function prototypeMethods.findLastIndex(self, callback, fromIndex)
  fromIndex = fromIndex or self.length

  if math.type(fromIndex) ~= 'integer' or fromIndex < 1 or fromIndex > self.length then
    error("'fromIndex' must be an integer greater than 0 and less than the array length ("..self.length..")")
  end

  for index = fromIndex, 1, -1 do
    local item = rawget(self, index)

    if callback(item, index, self) then
      return index
    end
  end

  return -1
end

---
---@param self ArrayInstance
---@param callback fun(item: unknown, index: integer, array: ArrayInstance): boolean
---@param fromIndex? integer
---@return unknown | nil
---@nodiscard
function prototypeMethods.find(self, callback, fromIndex)
  fromIndex = fromIndex or 1

  if math.type(fromIndex) ~= 'integer' or fromIndex < 1 or fromIndex > self.length then
    error("'fromIndex' must be an integer greater than 0 and less than the array length ("..self.length..")")
  end

  for index = fromIndex, self.length, 1 do
    local item = rawget(self, index)

    if callback(item, index, self) then
      return item
    end
  end

  return nil
end

---
---@param self ArrayInstance
---@param callback fun(item: unknown, index: integer, array: ArrayInstance): boolean
---@param fromIndex? integer
---@return unknown | nil
---@nodiscard
function prototypeMethods.findLast(self, callback, fromIndex)
  fromIndex = fromIndex or self.length

  if math.type(fromIndex) ~= 'integer' or fromIndex < 1 or fromIndex > self.length then
    error("'fromIndex' must be an integer greater than 0 and less than the array length ("..self.length..")")
  end

  for index = fromIndex, 1, -1 do
    local item = rawget(self, index)

    if callback(item, index, self) then
      return item
    end
  end

  return nil
end

---
---@param self ArrayInstance
---@param value any
---@param from? integer
---@param to? integer
function prototypeMethods.fill(self, value, from, to)
  from = from or 1
  to = to or self.length

  if math.type(from) ~= 'integer' or from < 1 or from > self.length then
    error("'from' must an integer greater than 0 and less than the array length ("..self.length..")")
  end

  if math.type(to) ~= 'integer' or to < 1 or to > self.length then
    error("'to' must an integer greater than 0 and less than the array length ("..self.length..")")
  end

  if from > to then
    error("'from' cannot be bigger than 'to'")
  end

  for index = from, to, 1 do
    rawset(self, index, value)
  end

  return self
end

---
---@param self ArrayInstance
---@param value any
---@param from? integer
---@param to? integer
---@return ArrayInstance
---@nodiscard
function prototypeMethods.toFilled(self, value, from, to)
  from = from or 1
  to = to or self.length

  if math.type(from) ~= 'integer' or from < 1 or from > self.length then
    error("'from' must an integer greater than 0 and less than the array length ("..self.length..")")
  end

  if math.type(to) ~= 'integer' or to < 1 or to > self.length then
    error("'to' must an integer greater than 0 and less than the array length ("..self.length..")")
  end

  if from > to then
    error("'from' cannot be bigger than 'to'")
  end

  local filledArray = Array()

  for index = 1, from, 1 do
    local item = rawget(self, index)
    rawset(filledArray, index, item)
  end

  for index = to, self.length, 1 do
    local item = rawget(self, index)
    rawset(filledArray, index, item)
  end

  for index = from, to, 1 do
    rawset(filledArray, index, value)
  end

  return filledArray
end

---
---@param self ArrayInstance
---@param callback fun(item: unknown, index: integer, array): boolean
---@return boolean
---@nodiscard
function prototypeMethods.some(self, callback)
  for index = 1, self.length, 1 do
    local item = rawget(self, index)
    if callback(item, index, self) then
      return true
    end
  end

  return false
end

---
---@param self ArrayInstance
---@param callback fun(item: unknown, index: integer, array): boolean
---@return boolean
---@nodiscard
function prototypeMethods.every(self, callback)
  if self.length == 0 then
    return false
  end

  for index = 1, self.length, 1 do
    local item = rawget(self, index)
    if not callback(item, index, self) then
      return false
    end
  end

  return true
end

---
---@param self ArrayInstance
---@param offset integer
---@return ArrayInstance
function prototypeMethods.rotate(self, offset)
  if math.type(offset) ~= 'integer' or offset == 0 then
    error("'offset' must be an integer different from 0")
  end

  if math.abs(offset) >= self.length then
    error("Absolute value of 'offset' cannot be equal of bigger than the Array length: "..self.length)
  end

  offset = Number.rotateIfOutOfRange(offset, 1, self.length - 1) + (offset < 0 and 1 or 0)

  local rotateIndex = offset

  local savedItems = Array()

  for index = 1, self.length, 1 do
    rotateIndex = Number.rotateIfOutOfRange(rotateIndex + 1, 1, self.length)

    savedItems:push(rawget(self, rotateIndex))

    if index < offset + 1 then
      local value = rawget(self, index)
      rawset(self, rotateIndex, value)
    else
      rawset(self, rotateIndex, savedItems:shift())
    end
  end

  return self
end

---
---@param self ArrayInstance
---@param offset integer
---@return ArrayInstance
---@nodiscard
function prototypeMethods.toRotated(self, offset)
  if math.type(offset) ~= 'integer' or offset == 0 then
    error("'offset' must be an integer different from 0")
  end

  if math.abs(offset) >= self.length then
    error("Absolute value of 'offset' cannot be equal of bigger than the Array length: "..self.length)
  end

  offset = Number.rotateIfOutOfRange(offset, 1, self.length - 1) + (offset < 0 and 1 or 0)

  local rotatedArray = Array(self.length)

  local rotateIndex = offset

  for index = 1, self.length, 1 do
    rotateIndex = Number.rotateIfOutOfRange(rotateIndex + 1, 1, self.length)

    local value = rawget(self, index)
    rawset(rotatedArray, rotateIndex, value)
  end

  return rotatedArray
end

---
---@param self ArrayInstance
---@return ArrayInstance
function prototypeMethods.shuffle(self)
  for index = 1, self.length, 1 do
    self:swapItems(math.random(1, self.length), math.random(1, self.length))
  end

  return self
end

---
---@param self ArrayInstance
---@return ArrayInstance
---@nodiscard
function prototypeMethods.toShuffled(self)
  local shuffledArray = self:clone():shuffle()

  return shuffledArray
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
