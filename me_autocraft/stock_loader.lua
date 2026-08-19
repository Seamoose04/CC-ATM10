-- me_autocraft/stock_loader.lua

---@type Util
local util = dofile("common/util.lua")

---@class StockLoader
local stockLoader = {}

---@class StockEntry
---@field item string Registry name, e.g. "minecraft:redstone".
---@field target number Quantity to keep in stock.

---@param path string
---@return StockEntry[] tracked Items whose requests are more than 0
---@return string[] untracked Items whose requests are 0
function stockLoader.loadFile(path)
	local raw = util.readFile(path)

	if not raw then
		print("Warning: '" .. path .. "' is empty")
		return {}, {}
	end
	local currentGroup = nil

	---@type StockEntry[]
	local tracked = {}

	---@type string[]
	local untracked = {}
	for line in raw:gmatch("[^\r\n]+") do
		local group = line:match("%[(.*)%]")
		if group then
			currentGroup = group
		else
			if not currentGroup then
				print("Warning: no group found, skipping line '" .. line .. "'")
			else
				local key, value = line:match("(%S+)%s+(%d+)")
				if not key or not value then
					print("Warning: skipping malformed line in '" .. path .. "': " .. line)
				else
					local fullName = currentGroup .. ":" .. key
					local target = tonumber(value)
					if target == 0 then
						table.insert(untracked, fullName)
					else
						table.insert(tracked, { item = fullName, target = target })
					end
				end
			end
		end
	end
	return tracked, untracked
end

return stockLoader
