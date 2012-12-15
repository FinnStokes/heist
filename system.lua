--- Low level module for managing systems.

local entity = require("entity")

local M = {}

local systems = {}

--- Adds a system to the list of systems
-- @param system (table) The system to add.
M.add = function (system)
  table.insert(systems, system)
end

--- Draws all the systems contained
M.draw = function ()
  local ents = entity.all()

  for _,s in ipairs(systems) do
    if s.draw then
      s.draw(dt, ents)
    end
  end
end

--- Removes a system from the list
-- @param system (table) The system to remove.
M.remove = function (system)
  for i,s in ipairs(systems) do
    if s == system then
      table.remove(systems, i)
      break
    end
  end
end

--- Updates the system, called each tick
-- @param dt The time delta in seconds.
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

return M