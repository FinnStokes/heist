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
        frames = {5},
        fps = 1,
      },
      idle_left = {
        frames = {9},
        fps = 1,
      },
      idle_up = {
        frames = {13},
        fps = 1,
      },
      down = {
        frames = {0,1,2,3},
        fps = 5,
      },
      right = {
        frames = {4,5,6,7},
        fps = 5,
      },
      left = {
        frames = {8,9,10,11},
        fps = 5,
      },
      up = {
        frames = {12,13,14,15},
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
    if map.ranges.move and not player.action then
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
      end
    end
  end
end)

return M
