local luaunit = require("luaunit")

local abs = require("turbobee/abs")
local search = require("turbobee/search")

print "testing resty using resty-cli"

testStuff = {} --class
function testStuff:testAdd()
  luaunit.assertEquals( abs.add(1, 2), 3 )
  luaunit.assertEquals( type(abs.add(1, 2)), "number" )
  luaunit.assertEquals( abs.add(1, 2), search.add(1, 2) )
end

luaunit.LuaUnit.run()
