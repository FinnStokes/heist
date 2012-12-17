--- The level loader

local camera = require("camera")
local entity = require("entity")
local event = require("event")
local system = require("system")
local util = require("util")

local M = {}

system.add(M)

local parseProperty = function (val)
  if val == "true" then
    return true
  end
  if val == "false" then
    return false
  end
  local num = tonumber(val)
  if num ~= nil then
    return num
  end
  return val
end

--- The draw function for levels
-- @param ents (table) A list of entities to draw (if it has a level)
M.draw = function (e)
  if e.level then
    for x = 1, e.level.width do
      for y = 1, e.level.height do
        local tile_id = e.level.tiledata[x][y]
        local quad = e.level.tileset.quads[tile_id]
        local pos = camera.worldToScreen({x = x, y = y})

        love.graphics.drawq(
          e.level.tileset.image,
          quad, pos.x, pos.y)
      end
    end
  end
end

--- A getter method for the properties of a tile
-- @param pos (table) The position given as {x = blah, y = blah}
M.getTileProperties = function (pos)
  local e = entity.get("world")

  if pos.x < 1 or pos.y < 1 or
      pos.x > e.level.width or
      pos.y > e.level.height then
    return {}
  end

  local tile_id = e.level.tiledata[pos.x][pos.y]
  local properties = {}

  if e.level.tilesets[1].tiles[tile_id] then
    for k,v in pairs(e.level.tilesets[1].tiles[tile_id]) do
      properties[k] = v
    end
  end

  return properties
end

--- The constructor for the level
-- @param data (table) The data for the level to construct
M.new = function (data)
  local e = entity.new(10)
  e.level = {}

  local tileLayer
  local objectGroup

  for i, layer in ipairs(data.layers) do
    if layer.type == "tilelayer" then
      tileLayer = i
    elseif layer.type == "objectgroup" then
      objectGroup = i
    end
  end

  for k, v in pairs(data.properties) do
    e.level.properties = parseProperty(v)
  end

  -- tileset properties
  for _,tileset in ipairs(data.tilesets) do
    local tiles = {}

    for _,tile in ipairs(tileset.tiles) do
      tiles[tile.id + 1] = {}
      for k,v in pairs(tile.properties) do
        tiles[tile.id + 1][k] = parseProperty(v)
      end
    end

    tileset.tiles = tiles
  end

  e.level.tilesets = data.tilesets
  
  -- tile data
  e.level.tiledata = {}
  for x=1,data.layers[tileLayer].width do
    e.level.tiledata[x] = {}
    for y=1,data.layers[tileLayer].height do
      e.level.tiledata[x][data.layers[tileLayer].height - y + 1] = data.layers[tileLayer].data[x + ((y - 1) * data.layers[tileLayer].width)]
      event.notify("tileCreation", {x=x, y=y})
    end
  end

  -- Object layer
  e.objects = {}
  if objectGroup then
    for i,object in ipairs(data.layers[objectGroup].objects) do
      object.properties.x = 1 + math.floor(object.x/data.tilewidth)
      object.properties.y = data.layers[tileLayer].height - math.floor(object.y/data.tilewidth)
      if object.polygon then
        object.properties.polygon = {}
        for _,pos in ipairs(object.polygon) do
          table.insert(object.properties.polygon, {x = math.floor(pos.x/data.tilewidth), y = -math.floor(pos.y/data.tilewidth)})
        end
      end
      object.properties.width = object.width
      object.properties.height = object.height
      local o = entity.build(object.type, object.properties)
      o.mapId = i
      e.objects[i] = o
      if object.name then
        entity.tag(o, object.name)
      end
      if object.properties.groups then
        local groups = object.properties.groups:split(",")
        for _,g in ipairs(groups) do
          object.group(o,g:trim())
        end
      end
    end
  end
  
  -- render info
  e.level.tileset = {}
  e.level.tileset.image = love.graphics.newImage("data/img/"..data.tilesets[1].image)
  e.level.tileset.quads = {}
  local max_tiles = data.tilesets[1].tilewidth * data.tilesets[1].tileheight
  local tiles_x = data.tilesets[1].imagewidth / data.tilesets[1].tilewidth
  for i=1,max_tiles do
    e.level.tileset.quads[i] = love.graphics.newQuad(
      ((i - 1) % tiles_x) * data.tilesets[1].tilewidth,
      math.floor((i - 1) / tiles_x) * data.tilesets[1].tileheight,
      data.tilesets[1].tilewidth, data.tilesets[1].tileheight,
      data.tilesets[1].imagewidth,
      data.tilesets[1].imageheight
    )
  end
  e.level.tileset.image:setFilter("nearest","linear")
  
  e.level.width = data.width
  e.level.height = data.height
  e.level.tileWidth = data.tilewidth
  e.level.tileHeight = data.tileheight

  entity.tag(e, "world")

  return e
end

return M
