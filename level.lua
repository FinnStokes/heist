--- The level loader

local camera = require("camera")
local entity = require("entity")
local event = require("event")
local system = require("system")

local M = {}

system.add(M)

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

M.getTileProperties = function (arg)
  local e = entity.get("world")

  if arg.x < 1 or arg.y < 1 or
      arg.x > e.level.width or
      arg.y > e.level.height then
    return {}
  end

  local tile_id = e.level.tiledata[arg.x][arg.y]
  local properties = {}

  if e.level.tilesets[tilelayer].tiles[tile_id] then
    for k,v in pairs(e.level.tilesets[tilelayer].tiles[tile_id]) do
      local f = assert(loadstring("return " .. v))
      _,properties[k] = pcall(f)
    end
  end

  return properties
end

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
  for x=1,data.layers[tilelayer].width do
    e.level.tiledata[x] = {}
    for y=1,data.layers[tilelayer].height do
      e.level.tiledata[x][y] = data.layers[tilelayer].data[x + ((y - 1) * data.layers[tilelayer].width)]
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
  e.level.tileset.image = love.graphics.newImage(data.tilesets[1].image) --may need prefix
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

local lastParallaxUpdate = 0
--prerender()
object.prerender = function ()
  if canvas then
    canvas:clear()
    canvas:renderTo(function()
      local camera = state.get().camera.position
      camera.x = math.floor(camera.x)
      camera.y = math.floor(camera.y)
      lastParallaxUpdate = camera.x
      love.graphics.setColor({255,255,255})
      local screen_width = love.graphics.getWidth() --native_mode.width
      local screen_height = love.graphics.getHeight() --native_mode.height
      for i=1,#parallax do
        parallax[i]:setWrap('repeat','repeat')
        local image = parallax[i]
        local width = screen_width
        local height = screen_height
        local x = (i / 20) * (camera.x - (screen_width / 2))
        local y = 0
        if x < screen_width and x + width > 0 then
          love.graphics.drawq(parallax[i],
            love.graphics.newQuad(x,y,screen_width,screen_height,width,height),
            0, -- x
            0, -- y
            0, -- rotation
            1, 1, -- scale_x, scale_y
            0, 0, -- origin_x, origin_y
            0, 0 -- shearing_x, shearing_y
          )
        end
      end
    end)
  end
end

-- render()
object.render = function (lagging)
  local camera = state.get().camera.position
  camera.x = math.floor(camera.x)
  camera.y = math.floor(camera.y)
  love.graphics.setColor({255,255,255})
  local screen_width = love.graphics.getWidth() --native_mode.width
  local screen_height = love.graphics.getHeight() --native_mode.height
 
  if canvas then
    if not lagging and math.abs(lastParallaxUpdate - camera.x) >= 7 then
      object.prerender()
    end
  
    love.graphics.draw(canvas,
      0, 0, -- x, y
      0, -- rotation
      1, 1, -- scale_x, scale_y
      0, 0, -- origin_x, origin_y
      0, 0 -- shearing_x, shearing_y
    )
  else
    for i=1,#parallax do
      parallax[i]:setWrap('repeat','repeat')
      local image = parallax[i]
      -- local width = parallax[i]:getWidth()
      -- local height = parallax[i]:getHeight()
      -- local x = (i / 10) * (camera.x - (screen_width / 2))
      -- local y = (height - (screen_height / 2))
      local width = screen_width
      local height = screen_height
      local x = (i / 20) * (camera.x - (screen_width / 2))
      local y = 0
      if x < screen_width and x + width > 0 then
        love.graphics.drawq(parallax[i],
          -- love.graphics.newQuad(x,y,screen_width,screen_height,width*entity.scale,height*entity.scale),
          love.graphics.newQuad(x,y,screen_width,screen_height,width,height),
          0, -- x
          0, -- y
          0, -- rotation
          1, 1, -- scale_x, scale_y
          0, 0, -- origin_x, origin_y
          0, 0 -- shearing_x, shearing_y
        )
      end
    end
  end
  
  tile_batch:clear()
  local l = math.floor((camera.x - (screen_width / 2))/(data.tilesets[tilelayer].tilewidth*entity.scale))
  local r = math.ceil((camera.x + (screen_width / 2))/(data.tilesets[tilelayer].tilewidth*entity.scale))
  local t = math.floor((camera.y - (screen_height / 2))/(data.tilesets[tilelayer].tileheight*entity.scale))
  local b = math.ceil((camera.y + (screen_height / 2))/(data.tilesets[tilelayer].tileheight*entity.scale))
  if not data.properties['wrap'] then
    if l < 0 then l = 0 end
    if r > data.layers[tilelayer].width-1 then r = data.layers[tilelayer].width-1 end
    if t < 0 then t = 0 end
    if b > data.layers[tilelayer].height-1 then b = data.layers[tilelayer].height-1 end
  end
  for x=l,r do
    for y=t,b do
      normX = (x % data.layers[tilelayer].width) + 1
      normY = (y % data.layers[tilelayer].height) + 1
      if tiledata[normX][normY] > 0 then
        tile_batch:addq(tileset.quads[tiledata[normX][normY]],
                   x*data.tilesets[tilelayer].tilewidth,
                   y*data.tilesets[tilelayer].tileheight)
      end
    end
  end
  love.graphics.setColor({255,255,255})
  love.graphics.draw(tile_batch,
    (screen_width / 2) - camera.x, (screen_height / 2) - camera.y, -- x, y
    0, -- rotation
    entity.scale, entity.scale, -- scale_x, scale_y
    0, 0, -- origin_x, origin_y
    0, 0 -- shearing_x, shearing_y
  )
end

return M