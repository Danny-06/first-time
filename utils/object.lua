local Object = {}


---Abstract class to extend other classes
---allowing an OOP prototype based pattern like in JavaScript
---@class Constructor
Object.Constructor = {}

---comment
---@param self { constructor: fun(...:unknown): table }
---@param ... unknown
---@return table
function Object.Constructor:__call(...)
  local instance = setmetatable({}, self)
  return self.constructor(instance, ...)
end

function Object.print(object)
  print(Object.stringify(object))
end

function Object.stringify(object, initalIdentation)
  if type(object) ~= 'table' then
    return tostring(object)
  end

  local identation = '  '

  if type(initalIdentation) == 'string' then
    identation = initalIdentation
  end

  local emptyObjectString = '{\n'..identation:sub(1, identation:len() - 2)..'}'

  local objectString = '{\n'

  local function increaseIndentation()
    identation = identation..'  '
  end

  local function dicreaseIndentation()
    identation = identation:sub(1, identation:len() - 2)
  end

  local key, value = nil, nil

  while true do
    key, value = next(object, key)

    if key == nil then
      break
    end

    local stringifiedValue = value

    if value == object then
      stringifiedValue = '[[Self]]'
    elseif type(value) == 'table' then
      stringifiedValue = Object.stringify(value, identation..'  ')
    elseif type(value) == 'string' then
      stringifiedValue = "'"..value.."'"
    end

    objectString = objectString..identation.."['"..key.."']: "..tostring(stringifiedValue)..',\n'
  end

  local metatable = getmetatable(object)
  if metatable ~= nil then
    objectString = objectString..'\n'..identation.."[[MetaTable]]: "..Object.stringify(metatable, identation..'  ')..',\n'
  end

  local debugMetatable = debug.getmetatable(object)
  if debugMetatable ~= nil then
    objectString = objectString..identation.."[[Debug: MetaTable]]: "..Object.stringify(debugMetatable, identation..'  ')..',\n'
  end

  dicreaseIndentation()
  objectString = objectString..identation..'}'
  increaseIndentation()

  if objectString == emptyObjectString then
    return '{}'
  end

  return objectString
end

return Object
