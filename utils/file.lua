local File = {}

---
---@param path string
---@return string | nil
function File.readFile(path)
  local file = io.open(path, 'r')

  if file == nil then
    error("FileNotFound: Couldn't find file in '"..path.."'")
  end

  local text = file:read('a')

  file:close()

  return text
end


return File
