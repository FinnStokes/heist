--- Manges loading and accessing game resources.

local M = {}

local resources = {}

local images = {}
M.getImage = function (name)
  if not images[name] then
    local image = love.graphics.newImage(name..".png")
    image:setFilter("nearest", "nearest")
    images[name] = image
  end
  return images[name]
end

local sounds = {}
M.getSound = function (name)
  if not sounds[name] then
    local snd = love.audio.newSource(name..".wav", "static")
    snd:setVolume(0.2)
    sounds[name] = snd
  end
  return sounds[name]
end

local music = {}
M.getMusic = function (name)
  if not music[name] then
    local snd = love.audio.newSource(name..".ogg", "stream")
    snd:setVolume(1)
    snd:setLooping(true)
    music[name] = snd
  end
  return music[name]
end

local scripts = {}
M.getScript = function (name)
  if not scripts[name] then
    local script = love.filesystem.load(name..".lua")
    local success, result = pcall(script)
    if success then 
      scripts[name] = result
    end
  end
  return scripts[name]
end

return M
