--- The entity manager.

local M = {}

local nextId = 1
local entitiesById = {}
local entitiesByTag = {}
local entityList = {}
local deleteQueue = {}

--- Get a list of all active enemies.
-- @return (table) The list of entities.
M.all = function ()
  return entityList
end

--- Delete an entity.
-- @param entity (table) The entity.
M.delete = function (entity)
  table.insert(deleteQueue, entity)
end

--- Get an entity by either its id or tag.
-- @param id The id (number) or tag (string) of an entity.
-- @return (table) The entity.
M.get = function (id)
  if type(id) == "number" then
    return entitiesById[id]
  elseif type(id) == "string" then
    return entitiesByTag[id]
  else
    return nil
  end
end

--- Get the list of entities in a group.
-- @param name (string) The group.
-- @return (table) The list of entities.
M.getGroup = function (name)
  return entitiesByGroup[group]
end

--- Add an entity to a group for easy access.
-- @param entity (table) The entity.
-- @param group (string) A named group of entities.
M.group = function (entity, group)
  if entitiesByGroup[group] == nil then
    entitiesByGroup[group] = {}
  end
  table.insert(entitiesByGroup[group], entity)
end

--- Create a new entity.
-- @return (table) The entity.
M.new = function ()
  local entity = {}
  entity.id = nextId
  nextId = nextId + 1
  entitiesById[entity.id] = entity
  table.insert(entityList, entity)
  return entity
end

--- Tag an entity with a name for easy access.
-- @param entity (table) The entity.
-- @param tag (string) A name to access a single entity.
M.tag = function(entity, tag)
  entitiesByTag[tag] = entity
end

--- Remove an entity from a group.
-- @param entity (table) The entity.
-- @param group (string) A named group of entities.
M.ungroup = function (entity, group)
  if entitiesByGroup[group] ~= nil then
    for i,e in ipairs(entitiesByGroup[group]) do
      if e == entity then
        table.remove(entitiesByGroup[group], i)
        break
      end
    end
  end
end

--- Update the entity manager.
-- @param dt (number) Time delta in seconds.
M.update = function (dt)
  for _,entity in ipairs(deleteQueue) do
    entitiesById[entity.id] = nil
    for i,e in ipairs(entiyList) do
      if e == entity then
        table.remove(entityList,i)
        break
      end
    end
    for t,e in pairs(entitiesByTag) do
      if e == entity then
        entitiesByTag[t] = nil
        break
      end
    end
    for _,group in pairs(entitiesByGroup) do
      for i,e in ipairs(group) do
        if e == entity then
          table.remove(group, i)
          break
        end
      end
    end
  end
end

return M
