--- The input manager.

local M = {}

--- The function to call when a key is pressed
-- @param key The key pressed?
M.keypressed = function (key)
  if key == "escape" then
    love.event.push("quit")
    love.event.push("q")
  end
end

--- The function to call when a key is released
-- @param key The key released?
M.keyreleased = function (key)
  
end

return M