-- common/rednet.lua

-- Shared rednet base type + send/receive wrappers.

---@class Packet
---@field protocol string

---@class RednetUtil
local rednetUtil = {}

local initialized = false

--- Open a modem for rednet use. Call once at startup.
---@return boolean success
function rednetUtil.init()
	---@type ccTweaked.peripheral.Modem?
	local modem = peripheral.find("modem")
	local name = modem and peripheral.getName(modem)
	if not name then
		return false
	end
	rednet.open(name)
	initialized = true
	return true
end

--- Errors if init() hasn't been called yet
local function assertInitialized()
	if not initialized then
		error("rednetUtil: init() must be called before use")
	end
end

--- Sends a packet to a specific computer ID.
---@param recipientId integer
---@param packet Packet
---@return boolean sent
function rednetUtil.send(recipientId, packet)
	assertInitialized()
	rednet.send(recipientId, packet, packet.protocol)
	return false
end

--- Broadcasts a packet to all listening computers.
---@param packet Packet
function rednetUtil.broadcast(packet)
	assertInitialized()
	rednet.broadcast(packet, packet.protocol)
end

--- Blocks until a packet matching the given protocol arrives.
---@param protocol string
---@param timeout? number
---@return Packet? packet
---@return integer? senderId
function rednetUtil.receive(protocol, timeout)
	assertInitialized()
	local senderId, packet = rednet.receive(protocol, timeout)
	---@cast packet Packet?
	return packet, senderId
end

--- Looks up a computer ID by hostname on a given protocol
---@param protocol string
---@param hostname string
---@return integer? recipientId
function rednetUtil.lookup(protocol, hostname)
	assertInitialized()

	local first, second = rednet.lookup(protocol, hostname)
	if not first then
		return nil
	end

	if second then
		print("Warning: rednet lookup found multiple hosts with the name '" .. hostname .. "'")
	end

	return first
end

--- Resolves a hostname to an ID, then sends a packet directly to it.
---@param hostname string
---@param packet Packet
---@return boolean sent
function rednetUtil.sendToHost(hostname, packet)
	assertInitialized()
	local recipientId = rednetUtil.lookup(packet.protocol, hostname)
	if not recipientId then
		return false
	end
	return rednetUtil.send(recipientId, packet)
end

return rednetUtil
