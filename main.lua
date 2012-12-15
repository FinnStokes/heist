--The main file for Heist

local event = require("event")
local entity = require("entity")
local system = require("system")

love.draw = function ()
  system.draw()
end

love.update = function (dt)
  event.update(dt)
  entity.update(dt)
end

love.init = function ()
  print("Initialisation!!")
end