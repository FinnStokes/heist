--The main file for Heist

local event = require("event")
local entity = require("entity")
local system = require("system")
local input = require("input")

--- The draw callback for Love.
love.draw = function ()
  system.draw()
end

--- The update callback for Love.
love.update = function (dt)
  event.update(dt)
  entity.update(dt)
end

--- The initialisation for Love.
love.init = function ()
  print("Initialisation!!")
end

love.keypressed = function (key)
  input.keypressed(key)
end

love.keyreleased = function (key)
  input.keyreleased(key)
end