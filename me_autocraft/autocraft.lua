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
local alreadyWarnedNotCraftable = {}

---@type table<string, boolean>
local alreadyWarnedCraftFailed = {}

---@class StockSnapshot
---@field item string
---@field current integer
---@field target integer
---@field crafting boolean

---@param job CraftingJob
---@param timeout number
---@return boolean success
local function waitForCalculation(job, timeout)
	local startTime = os.clock()

	local function timedOut()
		return os.clock() - startTime > timeout
	end

	while not job:isCalculationStarted() do
		if timedOut() then
			job:cancel()
			return false
		end
		sleep(0)
	end

	while not (job:isCalculationNotSuccessful() or job:isCraftingStarted()) do
		if timedOut() then
			job:cancel()
			return false
		end
		sleep(0)
	end

	return not job:isCalculationNotSuccessful()
end

while true do
	for item, job in pairs(currentJobs) do
		if job:isDone() then
			if job:hasErrorOccurred() or job:isCanceled() or job:isCalculationNotSuccessful() then
				if not alreadyWarnedCraftFailed[item] then
					print("Warning: craft for '" .. item .. "' failed - " .. job:getDebugMessage())
					alreadyWarnedCraftFailed[item] = true
				end
			else
				alreadyWarnedCraftFailed[item] = false
			end
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
			alreadyWarnedNotCraftable[entry.item] = false
		end
		if stock < entry.target then
			if craftable then
				table.insert(candidates, {
					entry = entry,
					needed = entry.target - stock,
					ratio = stock / entry.target
				})
			else
				if not alreadyWarnedNotCraftable[entry.item] then
					print("Warning: '" .. entry.item .. "' is not craftable")
					alreadyWarnedNotCraftable[entry.item] = true
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
			elseif waitForCalculation(job, config.MAX_CALCULATION_WAIT) then
				currentJobs[candidate.entry.item] = job
				jobCount = jobCount + 1
				alreadyWarnedCraftFailed[candidate.entry.item] = false
			else
				if not alreadyWarnedCraftFailed[candidate.entry.item] then
					print("Warning: craft for '" .. candidate.entry.item .. "' failed calculation - " .. job:getDebugMessage())
					alreadyWarnedCraftFailed[candidate.entry.item] = true
				end
			end
		end
	end

	local packet = protocols.newMEStockPacket(snapshots)
	rednetUtil.broadcast(packet)

	sleep(config.POLLING_RATE)
end
