-- system.lua
-- Low level module for managing systems

local entity = require("entity")

local M = {}

local systems = {}

M.add = function (system)
  table.insert(systems, system)
end

M.remove = function (system)
  for i,s in ipairs(systems) do
    if s == system then
      table.remove(systems, i)
      break
    end
  end
end

M.update = function (dt)
  local ents = entity.all()

  for _,s in systems do
    if s.preStep then
      s.preStep(dt, ents)
    end
  end
  for _,s in systems do
    if s.step then
      s.step(dt, ents)
    end
  end
  for _,s in systems do
    if s.postStep then
      s.postStep(dt, ents)
    end
  end
end

M.draw = function ()
  local ents = entity.all()

  for _,s in systems do
    if s.draw then
      s.draw(dt, ents)
    end
  end
end

return M