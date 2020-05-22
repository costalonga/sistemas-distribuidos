local luarpc = require("luarpc")

local porta0 = 8000
local porta1 = 8001
local porta2 = 8002
local IP = "127.0.0.1"
local arq_interface = "interface.lua"

local myobj2 = {
  foo = function (a, s, st, n) return a*2, string.len(s) + st.idade + n end,
  boo = function (n)
    print("\n\t     >>> [SVR2] INSIDE BOO = ", n, "\n")
    return n
    -- return 25
  end,
  boo2 = function (n)
    local p = luarpc.createProxy(IP, porta2, arq_interface) -- never enters but never leaves ??
    local r1 = p.easy(n)
    return r1
  end
}

luarpc.createServant(myobj2, "interface.lua", porta1)
luarpc.waitIncoming()
