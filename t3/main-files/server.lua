local luarpc = require("luarpc")

local porta1 = 8000
local porta2 = 8001
local IP = "127.0.0.1"
local arq_interface = "interface.lua"

-- AppendEntries RPC
-- RequestVote RPC

local myobj1 = {
  dummy = function (n)
    local n2 = n*n
    local p = luarpc.createProxy_for_server(IP, porta2, arq_interface) -- never enters but never leaves ??
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
