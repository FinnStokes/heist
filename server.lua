--- The game server module.

local LISTEN_PORT = 44000
local UPDATE_TIME = 0.1

local socket = require "socket"

local commands = {}
local local2net = {}
local net2local = {}
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
    local cmd, netId, args = data:match("^(%S*) (%S*) (.*)")
    
    if cmd == "connect" then
      -- A new player is connecting
      local id = players.nextId
      nextId = nextId + 1
      
      local address = {
        ip = msg_or_ip,
        port = port_or_nil,
      }
      
      players.id2address[id] = address
      players.address2id[tostring(ip) .. tostring(port)] = id
      
      -- Tell the player they are connected
      sock:sendto("connected " .. id, msg_or_ip, port_or_nil)
    else
      -- Call this commands handler
      commands[cmd](tonumber(netId), args)
    end
  end
  
  timer = timer + dt
  if timer >= UPDATE_TIME then
    timer = 0
    
    -- Compose update packet
    local packet = ""
    for _, e in ipairs(entity.all()) then
      local netId = local2id[e.id]
      packet = packet .. netId .. " "
      if e.network then
        if e.position then
          packet = packet .. tostring(e.position.x) .. " "
          packet = packet .. tostring(e.position.y) .. " "
        end
      end
      packet = packet .. ";"
    end
    
    -- Send packet to all players
    for id,address in pairs(players.id2address)
      sock:sendto(packet, address.ip, address.port)
    end
  end
end

-- Updates the player position
commands.pos = function (netId, args)
  local x, y = args:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
  assert(x and y)
  x, y = tonumber(x), tonumber(y)
  local e = entity.get(net2local[netId])
  e.position.x, e.position.y = x, y
end

return M
