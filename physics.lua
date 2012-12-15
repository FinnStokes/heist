--- The physics system.

local system = require("system")

local M = {}

system.add(M)

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