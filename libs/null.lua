---
---@class null
null = setmetatable({}, {
  __tostring = function ()
    return 'null'
  end,

  __index = function (self, key)
    error("Cannot get property '"..tostring(key).."' of null")
  end,

  __newindex = function (self, key, value)
    error("Cannot set property '"..tostring(key).."' of null to value '"..tostring(value).."'")
  end
})
