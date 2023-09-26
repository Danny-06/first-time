local Constructor = require('utils.object').Constructor

---
---@class IteratorClass
---@overload fun(func: function): IteratorInstance
---@field private constructor fun(self: IteratorInstance, func: function): IteratorInstance
local Iterator = setmetatable({}, Constructor)

---
---@class IteratorPrototype
Iterator.__index = {}

---
---@class IteratorInstance: IteratorPrototype
---@field func function
---@field thread thread
---#end

---Turn Iterator instances into callable objects  
---to be able to use it in `for in` loops  
---to iterate them
---```lua
---for value in iterator do
---  print('Value: ', value)
---end
---```
---@param self IteratorInstance
---@overload fun(...?: unknown): unknown -- Equivalent to `iterator.next()`
---@return unknown
function Iterator.__call(self)
  return self:next()
end

---
---@param self IteratorInstance
---@param func function
---@return IteratorInstance
function Iterator.constructor(self, func)
  self.func = func
  self.thread = coroutine.create(func)

  return self
end

---
---@param self IteratorInstance
---@param ... unknown
---@return unknown
---@nodiscard
function Iterator.__index.next(self, ...)
  local resumeData = {coroutine.resume(self.thread, ...)}
  return table.unpack(resumeData, 2)
end

---
---@param self IteratorInstance
---@return 'dead' | 'normal' | 'running' | 'suspended'
function Iterator.__index.getThreadStatus(self)
  return coroutine.status(self.thread)
end

---
---@param self IteratorInstance
---@return boolean
function Iterator.__index.isDone(self)
  return self:getThreadStatus() == 'dead'
end


return Iterator
