-- player.lua
-- Entity representing a player character

local entity = require("entity")

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

return M