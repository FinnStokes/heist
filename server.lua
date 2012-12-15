--- The game server module.

local LISTEN_PORT = 44000
local UPDATE_TIME = 0.1

local entity = require("entity")
local player = require("player")
local socket = require("socket")

local commands = {}
local local2net = {}
local net2local = {}
local nextEntityId = 1
local players = {
  id2address = {},
  address2id = {},
  nextId = 1,
}
local sock
local timer

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
    
    if cmd == "connect" then
      -- A new player is connecting
      local id = players.nextId
      players.nextId = players.nextId + 1
      
      local address = {
        ip = msg_or_ip,
        port = port_or_nil,
      }
      
      players.id2address[id] = address
      players.address2id[tostring(ip) .. tostring(port)] = id
      
      -- Tell the player they are connected
      sock:sendto("connected " .. id, msg_or_ip, port_or_nil)
      
      local packet = string.format("makePlayer %s %s",id, nextEntityId)
      local newPlayer = player.newRemote()
      newPlayer.network = {}
      local2net[newPlayer.id] = nextEntityId
      net2local[nextEntityId] = newPlayer.id
      nextEntityId = nextEntityId + 1
      for id,address in pairs(players.id2address) do
        sock:sendto(packet, address.ip, address.port)
      end
    else
      local args = data:match("^%S* (.*)")
      
      -- Call this commands handler
      local address = tostring(msg_or_ip) .. tostring(port_or_nil)
      local playerId = players.address2id[address]
      commands[cmd](playerId, args)
    end
  end
  
  timer = timer + dt
  if timer >= UPDATE_TIME then
    timer = 0
    
    -- Compose update packet
    local packet = ""
    for _, e in ipairs(entity.all()) do
      if e.network then
        local netId = local2net[e.id]
        packet = packet .. netId .. " "
        if e.position then
          packet = packet .. tostring(e.position.x) .. " "
          packet = packet .. tostring(e.position.y) .. " "
        end
        packet = packet .. ";"
      end
    end
    
    -- Send packet to all players
    for id,address in pairs(players.id2address) do
      sock:sendto(packet, address.ip, address.port)
    end
  end
end

-- Updates the player position
commands.pos = function (playerId, args)
  local id, x, y = args:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%-?[%d.e]*)$")
  assert(id and x and y)
  id, x, y = tonumber(id), tonumber(x), tonumber(y)
  local e = entity.get(net2local[id])
  e.position.x, e.position.y = x, y
end

return M
