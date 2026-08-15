-- me_autocraft/autocraft.lua

---@type Bridge
local bridge = dofile("me_autocraft/bridge.lua")

---@type StockEntry[]
local requiredStocks = dofile("me_autocraft/stock.lua")

---@type AppConfig
local config = dofile("me_autocraft/config.lua")

---@param entry StockEntry
---@return boolean needsRestock
---@return number amount
---@return boolean craftable
local function needsRestock(entry)
	local amount, craftable = bridge.getItemInfo(entry.item)
	return amount < entry.target, amount, craftable
end

local alreadyWarned = {}

while true do
	for _, entry in ipairs(requiredStocks) do
		local restock, stock, craftable = needsRestock(entry)
		if not bridge.isItemCrafting(entry.item) then
			if craftable then
				alreadyWarned[entry.item] = false
				local success = bridge.craftItem(entry.item, entry.target - stock)
				if not success then
					print("Craft for '" .. entry.item .. "' was not accepted.")
				end
			else
				if not alreadyWarned[entry.item] then
					print("'" .. entry.item .. "' is not craftable")
					alreadyWarned[entry.item] = true
				end
			end
		end
	end

	sleep(config.POLLING_RATE)
end
