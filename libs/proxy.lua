local Constructor = require('utils.object').Constructor

---
---@class ProxyClass
---@overload fun(target: unknown, handler: Handler): ProxyInstance
---@field private constructor fun(self: ProxyInstance, target: unknown, handler: Handler): ProxyInstance
local Proxy = setmetatable({}, Constructor)

---
---@class ProxyPrototype
---@overload fun(self: ProxyInstance, key: string): unknown
Proxy.__index = {}

---
---@class ProxyInstance: {[string]: unknown}
---@overload fun(...: unknown): unknown
---@field private __index {target: table, handler: Handler}
---#end

---
---@class Handler
---@field get? fun(target: table | function, property: string): unknown
---@field set? fun(target: table | function, property: string, value: unknown)
---@field call? fun(target: table | function, ...: unknown): unknown
---#end

---
---@param self ProxyInstance
---@param target unknown
---@param handler Handler
---@return ProxyInstance
function Proxy.constructor(self, target, handler)
  ---@diagnostic disable

  -- Store ProxyInstance properties in `__index`
  -- as a way to hide them.
  -- `rawset()` is used to avoid triggering `Proxy.__newindex()`
  rawset(self, '__index', {})

  self.__index.target = target
  self.__index.handler = handler

  return self
end

---Handle getters
---@param self ProxyInstance
---@param key string
---@return unknown
function Proxy.__index(self, key)
  local target = self.__index.target
  local handler = self.__index.handler

  if handler.get then
    return handler.get(target, key)
  end

  return target[key]
end

---Handle setters
---@param self ProxyInstance
---@param key string
---@param value unknown
function Proxy.__newindex(self, key, value)
  local target = self.__index.target
  local handler = self.__index.handler

  if handler.set then
    handler.set(target, key, value)
    return
  end

  target[key] = value
end

---Handle calling object
---@param self ProxyInstance
---@param ... unknown
function Proxy.__call(self, ...)
  local target = self.__index.target
  local handler = self.__index.handler

  if handler.get then
    return handler.call(target, ...)
  end

  return target(...)
end

return Proxy
