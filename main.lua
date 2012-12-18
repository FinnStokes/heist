--- The main file for Heist

--Constants
CANVAS_HEIGHT = 128
CANVAS_WIDTH = 240
PORT = "44000"
SPEED = 200

-- GLOBAL
isServer = nil

local entity = require("entity")
local event = require("event")
local goal = require("goal")
local guard = require("guard")
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

local canvas
local ip
local screen
local winner

event.subscribe("win", function ()
  winner = true
end)

--- The draw callback for Love.
love.draw = function ()
  if isServer == nil then
    -- Display setup instructions
    love.graphics.print(
[[To play by yourself or host a game, press F11.
To connect to a hosted game, type the host machine's IP address and then press F10.
IP: ]] .. ip,
    0, 0)
    return
  end

  -- Draw to canvas without scaling
  love.graphics.setCanvas(canvas)
  love.graphics.clear()
  love.graphics.setColor(255, 255, 255)
  system.draw()
  
  -- Draw win screen
  if winner then
    local img = resource.getImage("data/img/winner")
    love.graphics.draw(img, 0, 0)
  end

  -- Draw to screen with scaling
  love.graphics.setCanvas()
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(
    canvas,
    screen.x,
    screen.y,
    0,
    screen.scale,
    screen.scale
  )
end

--- The initialisation for Love.
love.load = function ()
  ip = ""
  winner = false

  -- Find the optimal screen scaling
  local modes = love.graphics.getModes()
  table.sort(modes, function (a, b)
    return a.width * a.height < b.width * b.height
  end)
  local mode = modes[#modes]
  local scale = 1
  while CANVAS_WIDTH * (scale + 1) <= mode.width and
    CANVAS_HEIGHT * (scale + 1) <= mode.height do
    scale = scale + 1
  end
  
  screen = {
    x = math.floor((mode.width - (CANVAS_WIDTH * scale)) / 2),
    y = math.floor((mode.height - (CANVAS_HEIGHT * scale)) / 2),
    width = mode.width,
    height = mode.height,
    scale = scale,
    fullscreen = true,
    vsync = true,
  }
  
  -- Create the window
  love.graphics.setMode(
    screen.width,
    screen.height,
    screen.fullscreen,
    screen.vsync
  )
  love.graphics.setBackgroundColor(0, 0, 0)
  love.mouse.setVisible(false)
  
  -- Create the canvas
  if not love.graphics.newCanvas then
    -- Support love2d versions before 0.8
    love.graphics.newCanvas = love.graphics.newFramebuffer
    love.graphics.setCanvas = love.graphics.setRenderTarget
  end
  canvas = love.graphics.newCanvas(CANVAS_WIDTH, CANVAS_HEIGHT)
  canvas:setFilter("nearest", "nearest")

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
    if key == "f10" or key == "return" then
      -- Client
      isServer = false
      network.start(ip, PORT)
    elseif key == "f11" then
      -- Server
      isServer = true
      system.remove(network)
      entity.update(0)
      server.start()
    elseif key == "backspace" then
      ip = ip:sub(1, -2) -- remove last character
    else
      ip = ip .. key
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
