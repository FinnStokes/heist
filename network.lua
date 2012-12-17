--- Synchronises entities over the network.

local action = require("action")
local entity = require("entity")
local event = require("event")
local player = require("player")
local socket = require("socket")
local system = require("system")
local timing = require("timing")
local util = require("util")

local address
local commands = {}
local playerId
local local2net = {}
local net2local = {}
local port
local sock
local timeOfLastPacket
local latency

local linkEntity = function (_local, net)
  local2net[_local] = net
  net2local[net] = _local
end

local onNewAction = function (player)
  if player.action then
    if player.action.type == "turnTo" then
      local packet = string.format(
        "trn %f %i %i",
        player.action.timestamp,
        player.action.facing.x,
        player.action.facing.y
      )
      sock:send(packet)
    elseif player.action.type == "moveTo" then
      local packet = string.format(
        "mov %f %i %i",
        player.action.timestamp,
        player.action.location.x,
        player.action.location.y
      )
      sock:send(packet)
    end
  end
end

local M = {}

system.add(M)

--- Start client networking.
M.start = function (address, port)
  sock = socket.udp()
  sock:settimeout(0)
  sock:setpeername(address, port)
  
  event.subscribe("newAction", onNewAction)
  
  -- Connect to server
  timeOfLastPacket = socket.gettime()
  
  sock:send("hi")
end

--- Stop the client networking.
M.stop = function ()
  sock:close()
  sock = nil
  event.unsubscribe("newAction", onNewAction)
end

--- Handle server messages and send our network updates.
M.step = function (dt, entities)

  -- Handle server messages
  while true do
    local data = sock:receive()

    if data == nil then
      -- no more messages, stop this update step
      break
    end
    
    -- Expects: "[cmd] [args...]"
    local cmd = data:match("^(%S*)")
    local args = data:match("^%S* (.*)") or ""
    
    -- Split the arguments into a table
    args = args:split(" ")

    commands[cmd](args)
  end
end

-- Change facing of a networked entity
commands.trn = function (args)
  local timestamp, netId, x, y = unpack(args)
  timestamp = tonumber(timestamp)
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)
  
  -- Update local entity
  local e = entity.get(net2local[netId])
  action.queue(e, action.newTurn({
    x = x,
    y = y,
  }, timestamp))
end

-- Server acknowledge
commands.ok = function (args)
  latency = (socket.gettime() - timeOfLastPacket)
  local netTime = tonumber(args[1]) + (latency / 2)
  timing.setOffset(netTime - timing.getTime())
  timing.update()
  playerId = tonumber(args[2])
end

-- Make a new networked entity
commands.mk = function (args)
  local netId, pid, type, character, x, y, fx, fy = unpack(args)
  netId = tonumber(netId)
  pid = tonumber(pid)
  x, y = tonumber(x), tonumber(y)
  fx, fy = tonumber(fx), tonumber(fy)
  local facing
  if fx and fy then
    facing = {x = fx, y = fy}
  end
  local newPlayer = entity.build("player", {
    x = x, y = y,
    facing = facing,
    character = character
  })
  if pid == playerId then
    entity.tag(newPlayer, "avatar")
  end
  linkEntity(newPlayer.id, netId)
end

-- Move a networked entity
commands.mov = function (args)
  local timestamp, netId, x, y = unpack(args)
  timestamp = tonumber(timestamp)
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)
  
  -- Update local entity
  local e = entity.get(net2local[netId])
  action.queue(e, action.newMove({
    x = x,
    y = y,
  }, timestamp))
end

return M
