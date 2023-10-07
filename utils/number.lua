local Number = {}

---
---@param number number
---@return boolean
---@nodiscard
function Number.isNaN(number)
  return type(number) == 'number' and number ~= number
end

---
---@param number number
---@return boolean
---@nodiscard
function Number.isFinite(number)
  return not Number.isNaN(number) and math.abs(number) ~= math.huge
end

---
---@param number number
---@param from number
---@param to number
---@return number
---@nodiscard
function Number.rotateIfOutOfRange(number, from, to)
  if from >= to then
    error("'from' must be lower than 'to'")
  end

  local result = number

  local normalizedFrom = 0 -- from - from
  local normalizedTo = to - from
  local normalizedNumber = number - from

  if normalizedNumber > normalizedTo then
    result = normalizedNumber % (normalizedTo + 1)
    result = result + from
  elseif normalizedNumber < normalizedFrom then
    result = (normalizedTo + 1) - math.abs(normalizedNumber) % (normalizedTo + 1)

    if result == normalizedTo + 1 then
      result = 0
    end

    result = result + from
  end

  return result
end


return Number
