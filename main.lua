--The main file for Heist

local entity = require("entity")
local event = require("event")
local input = require("input")
local physics = require("physics")
local player = require("player")
local server = require("server")
local sprite = require("sprite")
local system = require("system")
local timing = require("timing")

--Constants
SPEED = 200

--- The draw callback for Love.
love.draw = function ()
  system.draw()
end

--- The initialisation for Love.
love.load = function ()
  --server.start()
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
  timing.update(dt)
  input.update(dt)
  event.update(dt)
  entity.update(dt)
  system.update(dt)
  --server.update(dt)
end

local context = input.newContext(true)

context.map = function (raw, map)
  local dir = nil

  if raw.key.down["w"] 
      and not raw.key.down["a"]
      and not raw.key.down["s"]
      and not raw.key.down["d"] then
    dir = {x = 0, y = 1}
  elseif raw.key.down["s"]
      and not raw.key.down["d"] 
      and not raw.key.down["w"] 
      and not raw.key.down["a"] then
    dir = {x = 0, y = -1}
  elseif raw.key.down["a"]
      and not raw.key.down["s"]
      and not raw.key.down["d"]
      and not raw.key.down["w"] then
    dir = {x = -1, y = 0}
  elseif raw.key.down["d"]
      and not raw.key.down["w"] 
      and not raw.key.down["a"]
      and not raw.key.down["s"] then
    dir = {x = 1, y = 0}
  else
    dir = nil
  end

  map.ranges.move = dir

  return map
end
