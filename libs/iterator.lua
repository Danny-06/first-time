local Constructor = require('utils.object').Constructor

---
---@class IteratorClass
---@overload fun(func: function | string): IteratorInstance
---@field private constructor fun(self: IteratorInstance, func: function | string): IteratorInstance
local Iterator = setmetatable({}, Constructor)

---Turn Iterator instances into callable objects
---to be able to use it in `for in` loops
---to iterate them
---```lua
---for value in iterator do
---  print('Value: ', value)
---end
---```
---@param self IteratorInstance
---@return any ...
function Iterator.__call(self)
  return self:next()
end

---
---@class IteratorPrototype
Iterator.prototype = {}

function Iterator.__index(self, key)
  return Iterator.prototype[key]
end

---
---@class IteratorInstance: IteratorPrototype
---@overload fun(...?: any): any -- Equivalent to `iterator.next()`
---@field func function
---@field thread thread
---#end


---
---@param self IteratorInstance
---@param funcOrString function | string
---@return IteratorInstance
function Iterator.constructor(self, funcOrString)
  if type(funcOrString) == 'string' then
    self.func = function()
      for index = 1, #funcOrString, 1 do
        local char = funcOrString[index]
        coroutine.yield(char, index)
      end
    end
    self.thread = coroutine.create(self.func)
  elseif type(funcOrString) == 'function' then
      self.func = funcOrString
      self.thread = coroutine.create(funcOrString)
  end

  return self
end

---
---@param self IteratorInstance
---@param ... any
---@return any ...
---@nodiscard
function Iterator.prototype.next(self, ...)
  local returnValues = {coroutine.resume(self.thread, ...)}
  return table.unpack(returnValues, 2)
end

---
---@param self IteratorInstance
---@return 'dead' | 'normal' | 'running' | 'suspended'
function Iterator.prototype.getThreadStatus(self)
  return coroutine.status(self.thread)
end

---
---@param self IteratorInstance
---@return boolean
function Iterator.prototype.isDone(self)
  return self:getThreadStatus() == 'dead'
end


return Iterator
