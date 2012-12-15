--- Helper functions to transform between screen nd world coordiantes

local M = {}

M.xScale = 1
M.yScale = -1
M.x = 0
M.y = 500

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