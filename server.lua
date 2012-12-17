--- The game server module.

local action = require("action")
local entity = require("entity")
local event = require("event")
local player = require("player")
local socket = require("socket")
local timing = require("timing")
local util = require("util")

local characters = {
  "demo",
  "hacker",
  "killer",
  "scout"
}
local commands = {}
local local2net = {}
local msg_or_ip, port_or_nil
local net2local = {}
local nextEntityId = 1
local players = {
  entities = {},
  id2address = {},
  address2id = {},
  nextId = 1,
}
local sock
local timer

local linkEntity = function (_local, net)
  local2net[_local] = net
  net2local[net] = _local
end

local linkPlayer = function (id, address)
  players.id2address[id] = address
  players.address2id[string.format("%s:%s", address.ip, address.port)] = id
end

-- Send the packet to the player with playerId 
local sendTo = function (packet, playerId)
  local address = players.id2address[playerId]
  sock:sendto(packet, address.ip, address.port)
end

-- Send the packet to all players, except (optionally) playerId
local sendToAll = function (packet, playerId)
  for id, address in pairs(players.id2address) do
    if playerId ~= id then
      sock:sendto(packet, address.ip, address.port)
    end
  end
end

local onNewAction = function (e)
  local netId = local2net[e.id]
  if netId and e.action then
    if e.action.type == "attack" then
      local packet = string.format(
        "atk %f %u %u",
        e.action.timestamp,
        netId,
        local2net[e.action.target.id]
      )
      sendToAll(packet)
    elseif e.action.type == "dead" then
      local packet = string.format(
        "ded %f %u",
        0,
        netId
      )
      sendToAll(packet)
    elseif e.action.type == "turnTo" then
      local packet = string.format(
        "trn %f %u %i %i",
        e.action.timestamp,
        netId,
        e.action.facing.x,
        e.action.facing.y
      )
      sendToAll(packet)
    elseif e.action.type == "moveTo" then
      local packet = string.format(
        "mov %f %u %i %i",
        e.action.timestamp,
        netId,
        e.action.location.x,
        e.action.location.y
      )
      sendToAll(packet)
    end
  end
end

local M = {}

--- Gets the server IP and port.
-- @return (string) The server address.
M.getAddress = function ()
  return sock:getsockname()
end

--- Start the server.
M.start = function ()
  sock = socket.udp()
  sock:settimeout(0)
  sock:setsockname("*", PORT)
  timer = 0
  
  event.subscribe("newAction", onNewAction)
  
  -- Spawn the server's avatar
  local newPlayer = entity.build("player", {character = characters[1]})
  entity.tag(newPlayer, "avatar")
  entity.depth = -1
  newPlayer.network = {}
  linkEntity(newPlayer.id, nextEntityId)
  players.entities[0] = nextEntityId
  nextEntityId = nextEntityId + 1

  -- Link level objects to netIds
  local world = entity.get("world")
  for _, e in ipairs(world.objects) do
    local netId = nextEntityId
    linkEntity(e.id, netId)
    nextEntityId = nextEntityId + 1
  end
end

--- Stop the server.
M.stop = function ()
  sock:close()
  sock = nil
  
  event.unsubscribe("newAction", onNewAction)
end

--- Update the server.
-- @param dt (number) Time delta in seconds.
M.update = function (dt)
  -- Handle network messages
  while true do
    local data
    data, msg_or_ip, port_or_nil = sock:receivefrom()

    if data == nil then
      if msg_or_ip == "timeout" then
        -- No more packets, so finish this update
        break
      else
        -- Something bad happened, print message to error
        error("E: " .. tostring(msg))
      end
    end
    
    -- Expects: "[command] [args...]"
    local cmd = data:match("^(%S*)")
    local args = data:match("^%S* (.*)") or ""
    
    -- Split the arguments into a table
    args = args:split(" ")
    
    -- Call this commands handler
    local address = string.format("%s:%s", msg_or_ip, port_or_nil)
    local playerId = players.address2id[address]
    commands[cmd](playerId, args)
  end
end

-- Acknowledge player connection
commands.hi = function (playerId, args)
  -- A new player is connecting
  local id = players.nextId
  players.nextId = players.nextId + 1
  local address = {
    ip = msg_or_ip,
    port = port_or_nil,
  }
  linkPlayer(id, address)

  -- Determine character (first is taken by server)
  local character = characters[id + 1]

  -- Tell the player they are connected
  local packet = string.format("ok %f %u", timing.getTime(), id)
  sock:sendto(packet, msg_or_ip, port_or_nil)
  
  -- Spawn existing players on the new client
  for pid, netId in pairs(players.entities) do
    local e = entity.get(net2local[netId])
    local packet = string.format(
      "mk %u %u %s %s %i %i %i %i",
      netId,
      pid,
      "player",
      e.character,
      e.location.x,
      e.location.y,
      e.facing.x,
      e.facing.y
    )
    sock:sendto(packet, msg_or_ip, port_or_nil)
  end

  -- Link level objects to net ids on the new client
  local world = entity.get("world")
  for i, e in ipairs(world.objects) do
    local netId = local2net[e.id]
    local packet = string.format(
      "lnk %u %u %i %i",
      netId,
      i,
      e.location.x,
      e.location.y
    )
  end
  
  -- Spawn the new player's avatar on each client
  local packet = string.format("mk %u %u %s %s",
    nextEntityId,
    id,
    "player",
    character
  )
  sendToAll(packet)
  
  local newPlayer = entity.build("player", {character = character})
  newPlayer.network = {}
  linkEntity(newPlayer.id, nextEntityId)
  players.entities[id] = nextEntityId
  nextEntityId = nextEntityId + 1
end

-- Updates an entities position
commands.mov = function (playerId, args)
  local netId = players.entities[playerId]
  local timestamp, x, y = unpack(args)
  timestamp = tonumber(timestamp)
  x = tonumber(x)
  y = tonumber(y)

  -- Update local entity position
  local e = entity.get(net2local[netId])
  action.queue(e, action.newMove({
    x = x,
    y = y,
  }, timestamp))

  -- Notify other players
  local packet = string.format(
    "mov %f %u %i %i",
    timestamp,
    netId,
    x,
    y
  )
  
  sendToAll(packet, playerId)
end

-- Send back our time to sync the client
commands.png = function (playerId, args)
  local packet = string.format("png %u", timing.getTime())
  sendTo(packet, playerId)
end


-- Updates an entities facing
commands.trn = function (playerId, args)
  local netId = players.entities[playerId]
  local timestamp, x, y = unpack(args)
  timestamp = tonumber(timestamp)
  x = tonumber(x)
  y = tonumber(y)

  -- Update local entity position
  local e = entity.get(net2local[netId])
  action.queue(e, action.newTurn({x=x, y=y}, timestamp))

  -- Notify other players
  local packet = string.format(
    "trn %f %u %i %i",
    timestamp,
    netId,
    x,
    y
  )
  
  sendToAll(packet, playerId)
end

return M
