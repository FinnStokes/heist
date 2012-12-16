-- player.lua
-- Entity representing a player character

local entity = require("entity")
local event = require("event")
local action = require("action")

local M = {}

local new = function ()
  local player = entity.new()
  player.sprite = {r = 0.5}
  player.location = {x = 0, y = 0} --Logical integer position
  player.position = { --Fractional measure of your current position
    x = player.location.x,
    y = player.location.y,
  }
  player.facing = {x = 0, y = 1} --Unit vector of players facing direction
  player.velocity = {x = 0, y = 0} --Is this still necessary?
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
