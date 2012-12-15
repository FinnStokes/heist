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
      player.position.y = player.position.y - 10
    elseif key == "a" then
      player.position.x = player.position.x - 10
    elseif key == "s" then
      player.position.y = player.position.y + 10
    elseif key == "d" then
      player.position.x = player.position.x + 10
    end
  end
end

--- The function to call when a key is released
-- @param key The key released?
M.keyreleased = function (key)
  
end

return M