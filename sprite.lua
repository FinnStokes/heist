--- The sprite manager.

local system = require("system")
local camera = require("camera")

local M = {}

system.add(M)

--- Draw a sprite from the given list of entities
-- @param dt (number) Time delta in seconds.
-- @param ents (table) A list of entities with sprites (ignored if no sprite).
M.draw = function (ents)
  for _,e in ipairs(ents) do
    if e.sprite and e.position then
      local pos = camera.worldToScreen(e.position)
      love.graphics.circle("fill", pos.x, pos.y, e.sprite.r*math.abs(camera.xScale),30)
      if e.facing then
        local pos2 = camera.worldToScreen({x = e.position.x + e.facing.x, y = e.position.y + e.facing.y})
        love.graphics.line(pos.x, pos.y, pos2.x, pos2.y)
      end
    end
  end
end

return M
