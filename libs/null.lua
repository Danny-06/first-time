---
---@class null
null = setmetatable({}, {
  __tostring = function ()
    return 'null'
  end
})
