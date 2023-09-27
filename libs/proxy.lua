local Constructor = require('utils.object').Constructor

---
---@class ProxyClass
---@overload fun(target: table, handler: Handler): ProxyInstance
---@field private constructor fun(self: ProxyInstance, target: table, handler: Handler): ProxyInstance
---@field private instancesPropertiesMap {[ProxyInstance]: {target: table, handler: Handler}}
local Proxy = setmetatable({}, Constructor)

---
Proxy.instancesPropertiesMap = {}

---
---@class ProxyInstance
---@overload fun(...: any): any
---@field [any] any
---#end

---
---@param self ProxyInstance
---@return string
function Proxy.__tostring(self)
  local target = Proxy.getTarget(self)
  local targetStringified = tostring(target)

  return 'Proxy('..targetStringified..')'
end

---
---@class Handler
---@field get? fun(target: table, property: any): any
---@field set? fun(target: table, property: any, value: any)
---@field call? fun(target: table, ...: any): any
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

---
---@param proxy ProxyInstance
---@return table
function Proxy.getTarget(proxy)
  return Proxy.instancesPropertiesMap[proxy].target
end

---
---@param target table
---@param property any
---@return any
function Proxy.get(target, property)
  return target[property]
end

---
---@param target table
---@param property any
---@param value any
function Proxy.set(target, property, value)
  target[property] = value
end

---
---@param target table
---@param ... any
---@return any
function Proxy.call(target, ...)
  return target(...)
end

------- # Handle Proxy access -------

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
