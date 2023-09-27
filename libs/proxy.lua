local Constructor = require('utils.object').Constructor

---
---@class ProxyClass
---@overload fun(target: unknown, handler: Handler): ProxyInstance
---@field private constructor fun(self: ProxyInstance, target: table, handler: Handler): ProxyInstance
---@field private instancesPropertiesMap {[ProxyInstance]: {target: table, handler: Handler}}
local Proxy = setmetatable({}, Constructor)

---
Proxy.instancesPropertiesMap = {}

---
---@class ProxyPrototype
---@overload fun(self: ProxyInstance, key: string): any
Proxy.__index = {}

---
---@class ProxyInstance: {[any]: any}
---@overload fun(...: any): any
---#end

---
---@class Handler
---@field get? fun(target: table | function, property: any): any
---@field set? fun(target: table | function, property: any, value: any)
---@field call? fun(target: table | function, ...: any): any
---#end

---
---@param self ProxyInstance
---@param target table
---@param handler Handler
---@return ProxyInstance
function Proxy.constructor(self, target, handler)
  Proxy.instancesPropertiesMap[self] = {
    target = target,
    handler = handler
  }

  return self
end

---Handle getters
---@param self ProxyInstance
---@param key any
---@return any
function Proxy.__index(self, key)
  local target = Proxy.instancesPropertiesMap[self].target
  local handler = Proxy.instancesPropertiesMap[self].handler

  if handler.get then
    return handler.get(target, key)
  end

  return target[key]
end

---Handle setters
---@param self ProxyInstance
---@param key any
---@param value any
function Proxy.__newindex(self, key, value)
  local target = Proxy.instancesPropertiesMap[self].target
  local handler = Proxy.instancesPropertiesMap[self].handler

  if handler.set then
    handler.set(target, key, value)
    return
  end

  target[key] = value
end

---Handle calling object
---@param self ProxyInstance
---@param ... any
function Proxy.__call(self, ...)
  local target = Proxy.instancesPropertiesMap[self].target
  local handler = Proxy.instancesPropertiesMap[self].handler

  if handler.get then
    return handler.call(target, ...)
  end

  return target(...)
end

return Proxy
