--- Helper functions to transform between screen and world coordiantes

local entity = require("entity")
local system = require("system")

local xOffset = 0.5 - (CANVAS_WIDTH/32)
local yOffset = (CANVAS_HEIGHT/32) - 0.5

local M = {}

system.add(M)

M.xScale = 16
M.yScale = -16
M.x = 0
M.y = 12

--- A method to convert screen coords to world coords
-- @param pos (table) The screen coords to convert
-- @return (table) The corresponding world coords
M.screenToWorld = function (pos)
  return {
    x = (pos.x/M.xScale) + M.x,
    y = (pos.y/M.yScale) + M.y,
  }
end

--- Update the camera position to follow the player.
-- @param dt (number) Time delta in seconds.
-- @param entities (table) The entity list.
M.step = function (dt, entities)
  local avatar = entity.get("avatar")
  if avatar and avatar.location then
    M.x = math.floor((avatar.position.x + xOffset)*16)/16
    M.y = math.floor((avatar.position.y + yOffset)*16)/16
  end
end

--- A method to convert world coords to screen coords
-- @param pos (table) The world coords to convert
-- @return (table) The corresponding screen coords
M.worldToScreen = function (pos)
  return {
    x = (pos.x - M.x)*M.xScale,
    y = (pos.y - M.y)*M.yScale,
  }
end

return M
