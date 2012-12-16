--- The level loader

local camera = require("camera")
local entity = require("entity")
local event = require("event")
local system = require("system")

local M = {}

system.add(M)

--- The draw function for levels
-- @param ents (table) A list of entities to draw (if it has a level)
M.draw = function (ents)
  for _,e in ipairs(ents) do
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

  if e.level.tilesets[tilelayer].tiles[tile_id] then
    for k,v in pairs(e.level.tilesets[tilelayer].tiles[tile_id]) do
      local f = assert(loadstring("return " .. v))
      _,properties[k] = pcall(f)
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

  e.level.properties = data.properties

  -- tileset properties
  for _,tileset in ipairs(data.tilesets) do
    local tiles = {}

    for _,tile in ipairs(tileset.tiles) do
      tiles[tile.id + 1] = tile.properties
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
  
  -- for _,object in ipairs(data.layers[objectgroup].objects) do
  --   local position = { x = object.x, y = object.y }
  --   object.position = position
  --   entity.new(object)
  -- end
  
  -- render info
  e.level.tileset = {}
  e.level.tileset.image = love.graphics.newImage("data/img/"..data.tilesets[1].image) --may need prefix
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