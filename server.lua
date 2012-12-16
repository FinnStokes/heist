--- The game server module.

local entity = require("entity")
local player = require("player")
local socket = require("socket")

local commands = {}
local local2net = {}
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
  players.address2id[string.format("%S:%S", address.ip, address.port)] = id
end

local sendTo = function (packet, player)
  local address = players.id2address[player]
  sock:sendto(packet, address.ip, address.port)
end

local sendToAll = function (packet)
  for id, address in pairs(players.id2address) do
    sock:sendto(packet, address.ip, address.port)
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
  sock:setsockname("*", LISTEN_PORT)
  timer = 0
end

--- Stop the server.
M.stop = function ()
  sock:close()
  sock = nil
end

--- Update the server.
-- @param dt (number) Time delta in seconds.
M.update = function (dt)
  -- Handle network messages
  while true do
    local data, msg_or_ip, port_or_nil = sock:receivefrom()

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
    local _, args = data:match("^%S* (.*)")
    
    -- Call this commands handler
    local address = string.format("%S:%S", msg_or_ip, port_or_nil)
    local playerId = players.address2id[address]
    commands[cmd](playerId, args)
  end
end

-- Updates an entities facing
commands.fac = function (playerId, args)
  local netId, x, y = args:match("^(%S*) (%S*) (%S*)$")
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)

  -- Update local entity position
  local e = entity.get(net2local[netId])
  e.position.x, e.position.y = x, y

  -- Notify other players
  local packet = string.format("fac %u %u %f %f",
    netTime,
    netId,
    x,
    y
  )
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
  
  -- Tell the player they are connected
  local packet = string.format("ok %u %u", netTime, id)
  sock:sendto(packet, msg_or_ip, port_or_nil)
  
  -- Spawn existing players on the new client
  for playerId, netId in pairs(players.entities) do
    local packet = string.format("mk %u %u %s", nextEntityId, id, "player")
    sock:sendto(packet, msg_or_ip, port_or_nil)
  end
  
  -- Spawn the new player's avatar on each client
  local packet = string.format("mk %u %u %s", nextEntityId, id, "player")
  local newPlayer = player.newRemote()
  newPlayer.network = {}
  linkEntity(newPlayer.id, nextEntityId)
  players.entities[id] = nextEntityId
  nextEntityId = nextEntityId + 1
  sendToAll(packet)
end

-- Updates an entities position
commands.mov = function (playerId, args)
  local netId, x, y = args:match("^(%S*) (%S*) (%S*)$")
  netId = tonumber(netId)
  x = tonumber(x)
  y = tonumber(y)

  -- Update local entity position
  local e = entity.get(net2local[netId])
  e.position.x, e.position.y = x, y

  -- Notify other players
  local packet = string.format("mov %u %u %f %f",
    netTime,
    netId,
    x,
    y
  )
  
end

-- Send back our netTime to sync the client
commands.png = function (playerId, args)
  local packet = string.format("png %u", netTime)
  sendTo(packet, playerId)
end

return M
