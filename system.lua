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
    if s.preStep then
      s.preStep(dt)
    end
  end
  for _,s in systems do
    if s.step then
      s.step(dt)
    end
  end
  for _,s in systems do
    if s.postStep then
      s.postStep(dt)
    end
  end
end

M.draw = function ()
  for _,s in systems do
    if s.draw then
      s.draw(dt)
    end
  end
end

return M