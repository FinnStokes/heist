--- The sprite manager.

local system = require("system")

local M = {}

system.add(M)

--- Draw a sprite from the given list of entities
-- @param dt (number) Time delta in seconds.
-- @param ents (table) A list of entities with sprites (ignored if no sprite).
M.draw = function (dt, ents)
  for _,e in ipairs(ents)
    if e.sprite and e.position then
      love.graphics.circle(e.position.x, e.position.y, e.sprite.r)
    end
  end
end

return M