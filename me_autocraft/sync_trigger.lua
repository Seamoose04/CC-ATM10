-- me_autocraft/sync_trigger.lua

---@type RednetUtil
local rednetUtil = dofile("common/rednet.lua")

---@type Protocols
local protocols = dofile("common/protocols.lua")

local RESPONSE_TIMEOUT = 5

rednetUtil.init()

print("Requesting sync...")
rednetUtil.broadcast(protocols.newMESyncPacket())

local packet, senderId = rednetUtil.receive(protocols.ME_SYNC_COMPLETE, RESPONSE_TIMEOUT)

if not packet then
	print("Warning: No response - is the main computer on?")
else
	---@cast packet MESyncCompletePacket
	print(("Added %d new unstocked item(s):"):format(#packet.newItems))
	for _, name in ipairs(packet.newItems) do
		print("  " .. name)
	end
end
