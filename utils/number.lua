local Number = {}

---
---@param number number
---@return boolean
function Number.isNaN(number)
  return type(number) == 'number' and number ~= number
end

---
---@param number number
---@return boolean
function Number.isFinite(number)
  return not Number.isNaN(number) and math.abs(number) ~= math.huge
end


return Number
