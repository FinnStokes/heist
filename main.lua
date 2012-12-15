--The main file for Heist

local entity = require("entity")
local event = require("event")
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

love.joystickpressed = function (joystick, button)
  input.joystickPressed(joystick, button)
end

love.joystickreleased = function (joystick, button)
  input.joystickReleased(joystick, button)
end

love.keypressed = function (key)
  input.keyPressed(key)
end

love.keyreleased = function (key)
  input.keyReleased(key)
end

--- The update callback for Love.
love.update = function (dt)
  input.update(dt)
  event.update(dt)
  entity.update(dt)
  system.update(dt)
end

local OORT = 0.70710678118

local context = input.newContext(true)
context.map = function (raw, map)
  local dir = {x = 0, y = 0}
  if raw.key.down["w"] and not raw.key.down["s"] then
    if raw.key.down["a"] and not raw.key.down["d"] then
      dir = {x = -OORT, y = OORT}
    elseif raw.key.down["d"] and not raw.key.down["a"] then
      dir = {x = OORT, y = OORT}
    else
      dir = {x = 0, y = 1}
    end
  elseif raw.key.down["s"] and not raw.key.down["w"] then
    if raw.key.down["a"] and not raw.key.down["d"] then
      dir = {x = -OORT, y = -OORT}
    elseif raw.key.down["d"] and not raw.key.down["a"] then
      dir = {x = OORT, y = -OORT}
    else
      dir = {x = 0, y = -1}
    end
  else
    if raw.key.down["a"] and not raw.key.down["d"] then
      dir = {x = -1, y = 0}
    elseif raw.key.down["d"] and not raw.key.down["a"] then
      dir = {x = 1, y = 0}
    else
      dir = {x = 0, y = 0}
    end
  end
  map.ranges.move = dir
  return map
end
