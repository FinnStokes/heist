--The main file for Heist

local entity = require("entity")
local input = require("input")
local player = require("player")
local sprite = require("sprite")
local system = require("system")
local physics = require("physics")

--Constants
SPEED = 200

--- The draw callback for Love.
love.draw = function ()
  system.draw()
end

--- The initialisation for Love.
love.load = function ()
  player.newLocal()
end

love.keypressed = function (key)
  input.keypressed(key)
end

love.keyreleased = function (key)
  input.keyreleased(key)
end

--- The update callback for Love.
love.update = function (dt)
  event.update(dt)
  entity.update(dt)
  system.update(dt)
end
