-- https://github.com/LuaLS/lua-language-server/wiki/Annotations
-- http://lua-users.org/wiki/StringInterpolation
-- https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console#answer-42062321
-- https://gist.github.com/oatmealine/655c9e64599d0f0dd47687c1186de99f

-- local fileUtils = require('utils.file')
-- local Iterator = require('libs.iterator')
local Object = require('utils.object')
local Proxy = require('libs.proxy')


-- local function myGenerator()
--   for i = 1, 10 do
--     coroutine.yield(i)
--   end
-- end

-- local iterator = Iterator(myGenerator)

-- for value in iterator do
--   print('Value: ', value)
-- end

-- local proxy = Proxy({}, {
--   get = function (target, property)
--     if property == 'sos' then
--       return 'lal'
--     end

--     return 'not lal'
--   end,
--   call = function ()
--     return 'Elise'
--   end
-- })

-- print(proxy.sos)
-- print(proxy.lel)
-- print(proxy.target)
-- print(proxy())
