--- Entity representing a player character

local action = require("action")
local entity = require("entity")
local event = require("event")
local resource = require("resource")
local sprite = require("sprite")

local M = {}

local new = function ()
  local player = entity.new()
  player.location = {x = 0, y = 0} --Logical integer position
  player.position = { --Fractional measure of your current position
    x = player.location.x,
    y = player.location.y,
  }
  player.facing = {x = 0, y = 1} --Unit vector of players facing direction
  player.velocity = {x = 0, y = 0} --Is this still necessary?
  player.action = {type = "idle"}
  sprite.new(player, {
    image = resource.getImage("data/img/killer"),
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
    playing = "idle_" .. action.facing[player.facing.x][player.facing.y],
  })
  entity.group(player, "players")
  return player
end

M.newLocal = function ()
  local player = new()
  player.network = {}
  entity.tag(player, "avatar")
  return player
end

M.newRemote = function ()
  local player = new()
  return player
end

event.subscribe("input", function (map)
  local player = entity.get("avatar")
  if player and player.position then
    if map.ranges.move and player.action and player.action.type == "idle" then
      if map.ranges.move.x ~= 0 or map.ranges.move.y ~= 0 then
        if map.ranges.move.x == player.facing.x and
            map.ranges.move.y == player.facing.y then
          player.action = action.newMove({
            x = map.ranges.move.x,
            y = map.ranges.move.y,
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
