--- The entity manager.

local M = {}

local nextId = 1
local entitiesById = {}
local entitiesByTag = {}
local entitiesByGroup = {}
local entityList = {}
local deleteQueue = {}
local addQueue = {}
local tagQueue = {}
local groupQueue = {}
local templates = {}

--- Add a new template constructor
-- @param type (string) The name of the template
-- @parm f (function) The constructor to call (signature f(entity, args))
-- @see build
M.addTemplate = function (type, f)
  templates[type] = f
end

--- Get a list of all active entities.
-- @return (table) The list of entities.
M.all = function ()
  return entityList
end

---Construct an entity from a template
-- @param type (string) The name of the template
-- @param args (table) The template-specific arguments
-- @return (table) The constructed entity
M.build = function (type, args)
  local template = templates[type]
  local e = M.new()
  if template ~= nil then
    template(e, args)
  else
    error("E: Unknown entity template '"..type.."'")
  end
  return e
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
  if entitiesByGroup[name] then
    return entitiesByGroup[name]
  end
  return {}
end

--- Add an entity to a group for easy access.
-- @param entity (table) The entity.
-- @param group (string) A named group of entities.
M.group = function (entity, group)
  table.insert(groupQueue, {entity, group, true})
end

--- Create a new entity.
-- @return (table) The entity.
M.new = function (depth)
  local entity = {}
  entity.id = nextId
  nextId = nextId + 1
  entity.depth = depth or 0
  table.insert(addQueue, entity)
  return entity
end

--- Tag an entity with a name for easy access.
-- @param entity (table) The entity.
-- @param tag (string) A name to access a single entity.
M.tag = function(entity, tag)
  table.insert(tagQueue, {entity, tag})
end

--- Remove an entity from a group.
-- @param entity (table) The entity.
-- @param group (string) A named group of entities.
M.ungroup = function (entity, group)
  table.insert(groupQueue, {entity, group, false})
end

--- Update the entity manager.
-- @param dt (number) Time delta in seconds.
M.update = function (dt)
  for _,entity in ipairs(addQueue) do
    entitiesById[entity.id] = entity
    local inserted = false
    for k, v in ipairs(entityList) do
      if v.depth < entity.depth then
        table.insert(entityList, k, entity)
        inserted = true
        break
      end
    end
    if not inserted then
      table.insert(entityList, entity)
    end
  end
  for _,t in ipairs(tagQueue) do
    entitiesByTag[t[2]] = t[1]
  end
  for _,t in ipairs(groupQueue) do
    if t[3] then
      if entitiesByGroup[t[2]] == nil then
        entitiesByGroup[t[2]] = {}
      end
      table.insert(entitiesByGroup[t[2]], t[1])
    else
      if entitiesByGroup[t[2]] ~= nil then
        for i,e in ipairs(entitiesByGroup[t[2]]) do
          if e == t[1] then
            table.remove(entitiesByGroup[t[2]], i)
            break
          end
        end
      end
    end
  end
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
  deleteQueue = {}
  addQueue = {}
  tagQueue = {}
  groupQueue = {}
end

return M
