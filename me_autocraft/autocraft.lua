-- me_autocraft/autocraft.lua

---@type StockLoader
local stockLoader = dofile("me_autocraft/stock_loader.lua")

---@type Util
local util = dofile("common/util.lua")

---@type RednetUtil
local rednetUtil = dofile("common/rednet.lua")
rednetUtil.init()

---@type Protocols
local protocols = dofile("common/protocols.lua")

---@type Bridge
local bridge = dofile("me_autocraft/bridge.lua")

---@type StockEntry[]
local requiredStocks = stockLoader.loadFile("me_autocraft/stock.txt")

---@type AppConfig
local config = dofile("me_autocraft/config.lua")

---@type table<string, CraftingJob>
local currentJobs = {}

---@type table<string, boolean>
local alreadyWarned = {}

---@class StockSnapshot
---@field item string
---@field current integer
---@field target integer
---@field crafting boolean

while true do
	for item, job in pairs(currentJobs) do
		if job:isDone() then
			currentJobs[item] = nil
		end
	end

	local jobCount = util.tableCount(currentJobs)

	---@type { entry: StockEntry, needed: number, ratio: number }[]
	local candidates = {}

	---@type StockSnapshot[]
	local snapshots = {}

	for _, entry in ipairs(requiredStocks) do
		local stock, craftable = bridge.getItemInfo(entry.item)
		if craftable then
			alreadyWarned[entry.item] = false
		end
		if stock < entry.target then
			if craftable then
				table.insert(candidates, {
					entry = entry,
					needed = entry.target - stock,
					ratio = stock / entry.target
				})
			else
				if not alreadyWarned[entry.item] then
					print("Warning: '" .. entry.item .. "' is not craftable")
					alreadyWarned[entry.item] = true
				end
			end
		end

		---@type StockSnapshot
		local snapshot = {
			item = entry.item,
			current = stock,
			target = entry.target,
			crafting = currentJobs[entry.item] ~= nil
		}

		table.insert(snapshots, snapshot)
	end

	table.sort(candidates, function(a, b)
		return a.ratio < b.ratio
	end)

	for _, candidate in ipairs(candidates) do
		if jobCount >= config.MAX_CONCURRENT_CRAFTS then
			break
		end

		if not bridge.isItemCrafting(candidate.entry.item) then
			local job = bridge.craftItem(candidate.entry.item, candidate.needed)
			if not job then
				print("Craft for '" .. candidate.entry.item .. "' was not accepted.")
			else
				currentJobs[candidate.entry.item] = job
				jobCount = jobCount + 1
			end
		end
	end

	local packet = protocols.newMEStockPacket(snapshots)
	rednetUtil.broadcast(packet)

	sleep(config.POLLING_RATE)
end
