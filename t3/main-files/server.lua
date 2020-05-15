local luarpc = require("luarpc")

local porta1 = 8000
local porta2 = 8001
local IP = "127.0.0.1"
local arq_interface = "/home/Marcelo/Documents/puc-tmp/ZeroBraneStudio-1.80/projects-marcelo/t3/interface.lua"

-- local myobj1 = {
--   f1 = function (a, s, st, n)
--     local r1 = a*2
--     local r2 = tring.len(s) + st.idade + n
--     local p = luarpc.createProxy(IP, porta2, arq_interface)
--     local r3 = p.boo(10)
--     return r1, r2, r3
--   end
-- }

local myobj1 = {
  dummy = function (n)
    local n2 = n*n
    print("\t >>>>>>>>> LAST PRINT!!")

    local p = luarpc.createProxy(IP, porta2, arq_interface) -- never enters but never leaves ??

    print("\t >>>>>>>>> NEVER GETS HERE!!")

    local r1 = p.boo(n2)
    return r1
  end
}

local myobj2 = {
  foo = function (a, s, st, n) return a*2, string.len(s) + st.idade + n end,
  boo = function (n) return n end
}

luarpc.createServant(myobj1, "interface.lua", porta1)
luarpc.createServant(myobj2, "interface.lua", porta2)
luarpc.waitIncoming()
