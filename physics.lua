--- The physics system.

local system = require("system")

local M = {}

system.add(M)

M.step = function (dt, ents)
  print("Physics Step", dt)
  for _,e in ipairs(ents) do
    if e.position and e.velocity then
      e.position.x = e.position.x + e.velocity.x * dt
      e.position.y = e.position.y + e.velocity.y * dt
    end
  end
end

return M