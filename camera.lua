--- Helper functions to transform between screen nd world coordiantes

local M = {}

M.xScale = 16
M.yScale = -16
M.x = 0
M.y = 5

--- A method to convert world coords to screen coords
-- @param pos (table) The world coords to convert
-- @return (table) The corresponding screen coords
M.worldToScreen = function (pos)
  return {
    x = (pos.x - M.x)*M.xScale,
    y = (pos.y - M.y)*M.yScale,
  }
end

--- A method to convert screen coords to world coords
-- @param pos (table) The screen coords to convert
-- @return (table) The corresponding world coords
M.screenToWorld = function (pos)
  return {
    x = (pos.x/M.xScale) + M.x,
    y = (pos.y/M.yScale) + M.y,
  }
end

return M