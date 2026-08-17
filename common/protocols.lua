-- common/protocols.lua

-- Shared rednet protocols

---@class Protocols
local protocols = {}

protocols.ME_STOCK = "me_stock"

---@class StockPacket : Packet
---@field protocol "me_stock"
---@field snapshot StockSnapshot[]

--- Builds a StockPacket with the protocol pre-filled
---@param snapshot StockSnapshot[]
---@return StockPacket packet
function protocols.newStockPacket(snapshot)
	return {
		protocol = protocols.ME_STOCK,
		snapshot = snapshot
	}
end

return protocols
