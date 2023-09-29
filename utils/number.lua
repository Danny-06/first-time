local Number = {}

---
---@param number number
---@return boolean
function Number.isNaN(number)
  return type(number) == 'number' and number ~= number
end


return Number
