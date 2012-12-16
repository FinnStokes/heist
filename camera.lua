--- Helper functions to transform between screen nd world coordiantes

local M = {}

M.xScale = 16
M.yScale = -16
M.x = 0
M.y = 5

M.worldToScreen = function (pos)
  return {
    x = (pos.x - M.x)*M.xScale,
    y = (pos.y - M.y)*M.yScale,
  }
end

M.screenToWorld = function (pos)
  return {
    x = (pos.x/M.xScale) + M.x,
    y = (pos.y/M.yScale) + M.y,
  }
end

return M