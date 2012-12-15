--- The physics system.

local system = require("system")

local M = {}

system.add(M)

--- Update position, velocity and/or acceleration of entities where applicable
-- @param dt (number) Time delta in seconds.
-- @param ents (table) A list of entities with sprites (ignored if no sprite).
M.step = function (dt, ents)
  for _,e in ipairs(ents) do
    if e.velocity and e.acceleration then
      e.velocity.x = e.velocity.x + e.acceleration.x * dt
      e.velocity.y = e.velocity.y + e.acceleration.y * dt
    end
    if e.position and e.velocity then
      e.position.x = e.position.x + e.velocity.x * dt
      e.position.y = e.position.y + e.velocity.y * dt
    end
  end
end

return M