
---
---@param value unknown
---@param cases {[unknown]: function}
---@param defaultAction? function
---@return unknown
local function switch(value, cases, defaultAction)
  local caseAction = cases[value]

  local caseActionType = type(caseAction)

  if caseActionType == 'function' then
    return caseAction()
  end

  if caseAction ~= nil then
    error("'cases' must be an object of functions or not specified")
  end

  if type(defaultAction) == 'function' then
    return defaultAction()
  end

  if defaultAction ~= nil then
    error("'defaultAction' must be a function or not specified")
  end

  return nil
end

return switch
