--sprite.lua

local system = require("system")

local M = {}

system.add(M)

M.draw = function (dt, ents)
  for _,e in ipairs(ents)
    if e.sprite and e.position then
      love.graphics.circle(e.position.x, e.position.y, e.sprite.r)
    end
  end
end

return M