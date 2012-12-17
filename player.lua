--- Entity representing a player character

local action = require("action")
local entity = require("entity")
local event = require("event")
local resource = require("resource")
local sprite = require("sprite")

local M = {}

entity.addTemplate("player", function (self, args)
  self.location = { --Logical integer position
    x = 0,
    y = 0,
  }
  if args.x and args.y then
    self.location = {
      x = args.x,
      y = args.y,
    }
  else
    local spawner = entity.get("spawner")
    if spawner then
      self.location = {
        x = spawner.location.x,
        y = spawner.location.y,
      }
    end
  end

  self.character = args.character
  self.position = { --Fractional measure of your current position
    x = self.location.x,
    y = self.location.y,
  }
  self.facing = args.facing or {x = 0, y = 1} --Unit vector of players facing direction
  self.action = {type = "idle"}
  sprite.new(self, {
    image = resource.getImage("data/img/"..args.character),
    width = 16,
    height = 16,
    animations = {
      idle_down = {
        frames = {1},
        fps = 1,
      },
      idle_right = {
        frames = {33},
        fps = 1,
      },
      idle_left = {
        frames = {65},
        fps = 1,
      },
      idle_up = {
        frames = {97},
        fps = 1,
      },
      down = {
        frames = {0,1,2,3},
        fps = 5,
      },
      right = {
        frames = {32,33,34,35},
        fps = 5,
      },
      left = {
        frames = {64,65,66,67},
        fps = 5,
      },
      up = {
        frames = {96,97,98,99},
        fps = 5,
      },
    },
    playing = "idle_" .. action.facing[self.facing.x][self.facing.y],
  })
  entity.group(self, "players")
  return self
end)

entity.addTemplate("spawner", function (self, args)
  self.location = { --Logical integer position
    x = args.x or 0,
    y = args.y or 0,
  }
  entity.tag(self, "spawner")
  return self
end)

event.subscribe("input", function (map)
  local player = entity.get("avatar")
  if player and player.position then
    if map.ranges.move and player.action and player.action.type == "idle" then
      if map.ranges.move.x ~= 0 or map.ranges.move.y ~= 0 then
        if map.ranges.move.x == player.facing.x and
            map.ranges.move.y == player.facing.y then
          player.action = action.newMove({
            x = player.location.x + map.ranges.move.x,
            y = player.location.y + map.ranges.move.y,
          })
        else
          player.action = action.newTurn({
            x = map.ranges.move.x,
            y = map.ranges.move.y,
          })
        end
        event.notify("newAction", player)
      end
    end
  end
end)

return M
