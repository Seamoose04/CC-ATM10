-- common/protocols.lua

-- Shared rednet protocols

---@class Protocols
local protocols = {}

protocols.ME_STOCK = "me_stock"
protocols.ME_SYNC = "me_sync"
protocols.ME_SYNC_COMPLETE = "me_sync_complete"

---@class MEStockPacket : Packet
---@field protocol "me_stock"
---@field snapshot StockSnapshot[]

--- Builds an MEStockPacket with the protocol pre-filled
---@param snapshot StockSnapshot[]
---@return MEStockPacket packet
function protocols.newMEStockPacket(snapshot)
	return {
		protocol = protocols.ME_STOCK,
		snapshot = snapshot
	}
end

---@class MESyncPacket : Packet
---@field protocol "me_sync"

--- Builds an MESyncPacket
---@return MESyncPacket packet
function protocols.newMESyncPacket()
	return {
		protocol = protocols.ME_SYNC
	}
end

---@class MESyncCompletePacket : Packet
---@field protocol "me_sync_complete"
---@field newItems string[]

--- Builds an MESyncCompletePacket
---@param newItems string[]
---@return MESyncCompletePacket packet
function protocols.newMESyncCompletePacket(newItems)
	return {
		protocol = protocols.ME_SYNC_COMPLETE,
		newItems = newItems
	}
end

return protocols
