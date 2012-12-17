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
    if e.sprite.image then
      if not e.sprite.hidden then
        love.graphics.drawq(
          e.sprite.image, e.sprite.quad,
          pos.x, pos.y,
          0, 1, 1,
          e.sprite.originX, e.sprite.originY)
      end
    else
      love.graphics.circle("fill", pos.x, pos.y, e.sprite.r*math.abs(camera.xScale),30)
      if e.facing then
        local pos2 = camera.worldToScreen({x = e.position.x + e.facing.x, y = e.position.y + e.facing.y})
        love.graphics.line(pos.x, pos.y, pos2.x, pos2.y)
      end
    end
  end
end

--- Set an entities sprite as hidden or not
-- @param e The entity to hide/unhide
-- @param h (boolean) Hidden?
M.hide = function (e, h)
  if e.sprite then
    e.sprite.hidden = h and true
  else
    error("Entity has no sprite to hide")
  end
end

--- Constructor for a sprite to be added to an entity
-- @param e The entity to add the sprite to
-- @param t (table) A table containing the sprite data to add
M.new = function (e, t)
  e.sprite = {
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

  if t.animations then
    e.animation = {
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
    if e.animation.data[animation] and
        e.animation.playing ~= animation then
      e.animation.playing = animation
      e.animation.frame = 1
      e.animation.timer = 0
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
      if not e.animation.data or not e.animation.playing then
        e.sprite.quad:setViewport(
          0, 0, -- x, y
          e.sprite.width, e.sprite.height -- width, height
        )
        return
      end

      e.animation.timer = e.animation.timer + dt

      local anim = e.animation.data[e.animation.playing]
      local frameCount = #anim.frames

      while e.animation.timer >= 1/(anim.fps) do
        e.animation.frame = e.animation.frame + 1
        e.animation.timer = e.animation.timer - 1/(anim.fps)
      end

      while e.animation.frame > frameCount do
        event.notify(
          "sprite.onAnimationEnd",
          {entity = e, animation = e.animation.playing})
        if anim.goto then
          M.play(e, anim.goto)
        else
          e.animation.frame = e.animation.frame - frameCount
        end
      end

      anim = e.animation.data[e.animation.playing]
      local frame = anim.frames[e.animation.frame]
      local framesPerRow = e.sprite.image:getWidth() / e.sprite.width

      e.sprite.quad:setViewport(
        (frame % framesPerRow) * e.sprite.width,
        math.floor(frame / framesPerRow) * e.sprite.height,
        e.sprite.width, e.sprite.height
      )
    end
  end
end

return M
