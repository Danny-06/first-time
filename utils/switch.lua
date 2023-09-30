
---
---@param value any
---@param cases {[any]: function}
---@param defaultAction? function
---@return any
local function switch(value, cases, defaultAction)
  local caseAction = cases[value]

  local caseActionType = type(caseAction)

  if caseActionType == 'function' then
    return caseAction()
  elseif caseAction == nil then
    if type(defaultAction) == 'function' then
      return defaultAction()
    elseif caseAction ~= nil then
      error("'cases' must be a function or not specified")
    end
  else
    error("'cases' must be an object of functions")
  end
end

return switch
