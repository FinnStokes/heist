-- entity.lua
-- Low level manager to handle entities

local M = {}

local nextId = 1
local entitiesById = {}
local entitiesByTag = {}
local entityList = {}
local deleteQueue = {}

M.new = function ()
  local entity = {}
  entity.id = nextId
  nextId = nextId + 1
  entitiesById[entity.id] = entity
  table.insert(entityList, entity)
  return entity
end

M.tag = function(entity, tag)
  entitiesByTag[tag] = entity
end

M.group = function (entity, group)
  if entitiesByGroup[group] == nil then
    entitiesByGroup[group] = {}
  end
  table.insert(entitiesByGroup[group], entity)
end

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

M.get = function (id)
  if type(id) == "number" then
    return entitiesById[id]
  elseif type(id) == "string" then
    return entitiesByTag[id]
  else
    return nil
  end
end

M.all = function ()
  return entityList
end

M.getGroup = function (name)
  return entitiesByGroup[group]
end

M.delete = function (entity)
  table.insert(deleteQueue, entity)
end

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