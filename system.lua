-- system.lua
-- Low level module for managing systems

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
  for _,s in systems do
    s.preStep(dt)
  end
  for _,s in systems do
    s.step(dt)
  end
  for _,s in systems do
    s.postStep(dt)
  end
end

M.draw = function ()
  for _,s in systems do
    s.draw(dt)
  end
end

return M