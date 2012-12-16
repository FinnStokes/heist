--- The main file for Heist

local entity = require("entity")
local event = require("event")
local input = require("input")
local level = require("level")
local network = require("network")
local physics = require("physics")
local player = require("player")
local resource = require("resource")
local server = require("server")
local sprite = require("sprite")
local system = require("system")
local timing = require("timing")

--Constants
IP = "127.0.0.1"
PORT = "44000"
SPEED = 200

local isServer

--- The draw callback for Love.
love.draw = function ()
  system.draw()
end

--- The initialisation for Love.
love.load = function ()
  local map = resource.getScript("data/img/level")
  local lvl = level.new(map)
end

love.joystickpressed = function (joystick, button)
  input.joystickPressed(joystick, button)
end

love.joystickreleased = function (joystick, button)
  input.joystickReleased(joystick, button)
end

love.keypressed = function (key)
  -- Handle client/server specialisation
  if isServer == nil then
    if key == "f10" then
      -- Client
      isServer = false
      network.start(IP, PORT)
    elseif key == "f11" then
      -- Server
      isServer = true
      system.remove(network)
      server.start()
    end
  end
  
  input.keyPressed(key)
end

love.keyreleased = function (key)
  input.keyReleased(key)
end

--- The update callback for Love.
love.update = function (dt)
  if isServer == nil then
    return
  elseif isServer == true then
    server.update(dt)
  end

  input.update(dt)
  event.update(dt)
  timing.update(dt)
  entity.update(dt)
  system.update(dt)
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
