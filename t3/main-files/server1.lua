local luarpc = require("luarpc")

local porta0 = 8000
local porta1 = 8001
local IP = "127.0.0.1"
local arq_interface = "interface.lua"

local myobj1 = {
  foo = function (a, s, st, n)
    return a*2, string.len(s) + st.idade + n
  end,
  complex_foo = function (a, s, st, n)
    local p = luarpc.createProxy(IP, porta1, arq_interface) -- never enters but never leaves ??
    return p.foo(a*2, s, st, n)
  end,
  dummy = function (n)
    local n2 = n*n
    -- local p = luarpc.createProxy_for_server(IP, porta1, arq_interface) -- never enters but never leaves ??
    local p = luarpc.createProxy(IP, porta1, arq_interface) -- never enters but never leaves ??
    -- print("\n\t     >>> [SVR1] BEFORE P.BOO()", p)
    local r1 = p.boo(n2)
    -- print("\n\t     >>> [SVR1] RETURN OF p.boo(n2) = ", r1, "\n")
    return r1
  end,
  dummy2 = function (n)
    local n2 = n*n
    local p = luarpc.createProxy(IP, porta1, arq_interface) -- never enters but never leaves ??
    -- print("\n\t     >>> [SVR1] BEFORE P.BOO()", p)
    local r1 = p.boo2(n2)
    -- print("\n\t     >>> [SVR1] RETURN OF p.boo(n2) = ", r1, "\n")
    return r1
  end,
  simple_f1 = function (a) return a*10 end,
  simple_f2 = function (a) return a*a end,
  call_yourself = function (a1,a2)
      local p = luarpc.createProxy(IP, porta0, arq_interface) -- never enters but never leaves ??
      local r1 = p.simple_f1(a1)
      local r2 = p.simple_f2(a2)
      return r1+r2
  end
}
luarpc.createServant(myobj1, "interface.lua", porta0)
luarpc.waitIncoming()
