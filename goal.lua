--- Handles the game goal.

local entity = require("entity")
local event = require("event")
local resource = require("resource")
local sprite = require("sprite")
local system = require("system")

local M = {}

entity.addTemplate("goal", function (e, args)
  e.goal = true
  e.location = {
    x = args.x,
    y = args.y,
  }
  e.position = {
    x = args.x,
    y = args.y,
  }
  sprite.new(e, {
    image = resource.getImage("data/img/goal"),
    width = 16,
    height = 16,
    animations = {
      idle = {
        frames = {0,1,2,3,4,5,6,7,8,9,10,11},
        fps = 5,
      },
    },
    playing = "idle",
  })
  return e
end)

system.add(M)

M.step = function (dt, entities)
  if isServer then
    for _,e in ipairs(entities) do
      if e.goal then
        for _,p in ipairs(entity.getGroup("players")) do
          if p.location.x <= e.location.x + 1 and
              p.location.y <= e.location.y + 1 and
              p.location.x >= e.location.x - 1 and
              p.location.y >= e.location.y - 1 then
            -- Winner
            event.notify("win")
          end
        end
      end
    end
  end
end

return M

