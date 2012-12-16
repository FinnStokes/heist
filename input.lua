--- The input manager.

local entity = require("entity")
local event = require("event")

local M = {}

local contexts = {}
local raw = {
  key = {
    down = {},
    pressed = {},
    released = {}
  },
  joystick = {
    down = {},
    pressed = {},
    released = {},
    axis = {}
  }
}

--- The function to call when a joystick button is pressed
-- @param joystick (number) The id of the joystick on which the button was pressed
-- @param button (number) The id of the button that was pressed
M.joystickPressed = function(joystick, button)
  raw.joystick.down[button] = true
  raw.joystick.pressed[button] = true
end

--- The function to call when a joystick button is released
-- @param joystick (number) The id of the joystick on which the button was released
-- @param button (number) The id of the button that was released
M.joystickReleased = function(joystick, button)
  raw.joystick.down[button] = nil
  raw.joystick.released[button] = true
end

--- The function to call when a key is pressed
-- @param key (string) The key pressed
M.keyPressed = function (key)
  if key == "escape" then
    love.event.push("quit")
    love.event.push("q")
  end

  raw.key.down[key] = true
  raw.key.pressed[key] = true
end

--- The function to call when a key is released
-- @param key (string) The key released
M.keyReleased = function (key)
  raw.key.down[key] = nil
  raw.key.released[key] = true
end

--- Create a new input context, to map raw inputs to logical inputs
-- @param active (boolean) Whether or not the context is initially active. Defaults to false.
-- @param priority (number) Determines the order in which the active contexts are applied. Higher priority results in later appliction. Defaults to 0.
M.newContext = function (active, priority)
  local self = {
    active = active or false,
    priority = priority or 0
  }
  
  local object = {}
  
  object.active = function (active)
    self.active = active or self.active
    return self.active
  end
  
  object.priority = function (priority)
    self.priority = priority or self.priority
    return self.priority
  end

  object.map = function (raw_input, map_input)
    return raw_input, map_input
  end
  
  table.insert(contexts, object)
  table.sort(contexts,
    function (a, b)
      return a.priority() < b.priority()
    end
  )
  return object
end

--- Map raw inputs to logical inputs using active input contexts
-- @param dt (number) Time delta in seconds.
M.update = function (dt)
  local map = {
    actions = {},
    states = {},
    ranges = {}
  }
  
  if love.joystick.getNumJoysticks() > 0 then
    for i=1,love.joystick.getNumAxes(1) do
      raw.joystick.axis[i] = love.joystick.getAxis(1, i)
    end
  end

  for _,context in ipairs(contexts) do
    if context.active() then
      map = context.map(raw, map)
    end
  end
  
  raw.key.pressed = {}
  raw.key.released = {}
  raw.joystick.pressed = {}
  raw.joystick.released = {}

  if next(map.actions) == nil and
      next(map.states) == nil and
      next(map.ranges) == nil then
    return
  end

  event.notify("input", map)
end

return M
