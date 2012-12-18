--- The sprite manager.

local camera = require("camera")
local event = require("event")
local system = require("system")

local M = {}

system.add(M)

--- Draw a sprite from the given list of entities
-- @param ents (table) A list of entities with sprites (ignored if no sprite).
M.draw = function (e)
  if e.sprite and e.position then
    local pos = camera.worldToScreen(e.position)
    for _,s in ipairs(e.sprite) do
      if s.image then
        if not s.hidden then
          love.graphics.drawq(
            s.image, s.quad,
            pos.x, pos.y,
            0, 1, 1,
            s.originX, s.originY)
        end
      end
    end
  end
end

--- Set an entities sprite as hidden or not
-- @param e The entity to hide/unhide
-- @param h (boolean) Hidden?
M.hide = function (e, h)
  if e.sprite then
    for _,s in ipairs(e.sprite) do
      s.hidden = h and true
    end
  else
    error("Entity has no sprite to hide")
  end
end

--- Constructor for a sprite to be added to an entity
-- @param e The entity to add the sprite to
-- @param t (table) A table containing the sprite data to add
M.new = function (e, t)
  local sprite = {
    image = t.image,
    width = t.width,
    height = t.height,
    originX = t.originX or 0,
    originY = t.originY or 0,
    hidden = false,
    quad = love.graphics.newQuad(
      0, 0,
      t.width, t.height,
      t.image:getWidth(), t.image:getHeight()
    ),
  }
  if not e.sprite then
    e.sprite = {}
  end
  table.insert(e.sprite, sprite)

  if t.animations then
    if not e.animation then
      e.animation = {}
    end
    e.animation[#e.sprite] = {
      data = t.animations,
      playing = t.playing or nil,
      frame = 1,
      timer = 0,
    }
  end
end

--- Play an entities animation
-- @param e The entity to work on
-- @param animation (key) The animation to play
M.play = function (e, animation)
  if e.animation then
    for _,a in ipairs(e.animation) do
      if a.data[animation] and
        a.playing ~= animation then
        a.playing = animation
        a.frame = 1
        a.timer = 0
      end
    end
  else
    error("Entity has no animation to play")
  end
end

--- The system step method
-- @param dt The time delta in seconds
-- @param ents (table) A list of entities to update
M.step = function (dt, ents)
  for _,e in ipairs(ents) do
    if e.sprite and e.animation then
      for i,a in ipairs(e.animation) do
        if e.sprite[i] then
          local s = e.sprite[i]
          if not a.data or not a.playing then
            s.quad:setViewport(
              0, 0, -- x, y
              s.width, s.height -- width, height
            )
          else
            a.timer = a.timer + dt
            
            local anim = a.data[a.playing]
            local frameCount = #anim.frames
            
            while a.timer >= 1/(anim.fps) do
              a.frame = a.frame + 1
              a.timer = a.timer - 1/(anim.fps)
            end
            
            while a.frame > frameCount do
              event.notify(
                "sprite.onAnimationEnd",
                {entity = e, animation = a.playing})
              if anim.goto then
                M.play(e, anim.goto)
              else
                a.frame = a.frame - frameCount
              end
            end
            
            anim = a.data[a.playing]
            local frame = anim.frames[a.frame]
            local framesPerRow = s.image:getWidth() / s.width
            
            s.quad:setViewport(
              (frame % framesPerRow) * s.width,
              math.floor(frame / framesPerRow) * s.height,
              s.width, s.height
            )
          end
        end
      end
    end
  end
end

return M
