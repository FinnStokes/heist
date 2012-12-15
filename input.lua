--- The input manager.

local entity = require("entity")

local M = {}

--- The function to call when a key is pressed
-- @param key The key pressed?
M.keypressed = function (key)
  if key == "escape" then
    love.event.push("quit")
    love.event.push("q")
  end

  local player = entity.get("avatar")
  if player and player.position then
    if key == "w" then
      player.velocity.y = -SPEED
    elseif key == "a" then
      player.velocity.x = -SPEED
    elseif key == "s" then
      player.velocity.y = SPEED
    elseif key == "d" then
      player.velocity.x = SPEED
    end
  end
end

--- The function to call when a key is released
-- @param key The key released?
M.keyreleased = function (key)
  local player = entity.get("avatar")
  if player and player.position then
    if key == "w" then
      player.velocity.y = 0
    elseif key == "a" then
      player.velocity.x = 0
    elseif key == "s" then
      player.velocity.y = 0
    elseif key == "d" then
      player.velocity.x = 0
    end
  end
end

return M