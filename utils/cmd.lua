-- https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797

local cmd = {}

cmd.ESC = '\u{001b}'

cmd.colors = {
  black   = 30,
  red     = 31,
  green   = 32,
  yellow  = 33,
  blue    = 34,
  magenta = 35,
  cyan    = 36,
  white   = 37,
}

cmd.backgrounds = {
  black   = 40,
  red     = 41,
  green   = 42,
  yellow  = 43,
  blue    = 44,
  magenta = 45,
  cyan    = 46,
  white   = 47,
}

cmd.fontStyles = {
  bold          = 1,
  italic        = 3,
  underline     = 4,
  inverse       = 7,
  invisible     = 8,
  strikethrough = 9,
}

---
---@class ANSIStyleOptions
---@field color? number
---@field background? number
---@field isBold? boolean
---@field isItalic? boolean
---@field isUnderline? boolean
---@field isStrikeThrough? boolean
---@field isInvisible? boolean
---@field isBlinking? boolean
---@field isInverse? boolean
---#end

---
---@param str any
---@param options ANSIStyleOptions
---@return string
---@diagnostic disable
function cmd.setStringANSIStyle(str, options)
  str = tostring(str)

  local codes = ''

  options.isBold = options.isBold and cmd.fontStyles.bold or nil
  options.isItalic = options.isItalic and cmd.fontStyles.italic or nil
  options.isUnderline = options.isUnderline and cmd.fontStyles.underline or nil
  options.isStrikeThrough = options.isStrikeThrough and cmd.fontStyles.strikethrough or nil
  options.isInvisible = options.isInvisible and cmd.fontStyles.invisible or nil
  options.isInverse = options.isInverse and cmd.fontStyles.isInverse or nil

  for key, value in pairs(options) do
    codes = codes..value..';' --[[@as string]]
  end

  codes = codes:sub(1, #codes - 1)

  return cmd.ESC..'['..codes..'m'..str..cmd.ESC..'[0m'
end


return cmd
