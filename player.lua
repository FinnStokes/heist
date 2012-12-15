-- player.lua
-- Entity representing a player character

local entity = require("entity")
local event = require("event")

local M = {}

local new = function ()
  local player = entity.new()
  player.sprite = {r = 20}
  player.position = {x = 100, y = 100}
  player.velocity = {x = 0, y = 0}
  entity.group(player, "players")
  return player
end

M.newLocal = function ()
  local player = new()
  player.input = {}
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
    if map.ranges.move then
      player.velocity.x = SPEED*map.ranges.move.x
      player.velocity.y = SPEED*map.ranges.move.y
    end
  end
end)

return M