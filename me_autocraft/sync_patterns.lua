-- me_autocraft/sync_patterns.lua

---@type Util
local util = dofile("common/util.lua")

---@type Bridge
local bridge = dofile("me_autocraft/bridge.lua")

---@type StockLoader
local stock_loader = dofile("me_autocraft/stock_loader.lua")

---@type AppConfig
local config = dofile("me_autocraft/config.lua")

---@return table<string, boolean>
local function getExistingItemNames()
	local tracked, untracked = stock_loader.loadFile(config.STOCK_FILE)
	local existingNames = {}

	for _, entry in ipairs(tracked) do
		existingNames[entry.item] = true
	end
	for _, itemName in ipairs(untracked) do
		existingNames[itemName] = true
	end

	return existingNames
end

---@param craftableItems ItemStack[]
---@param existingNames table<string, boolean>
---@return string[] newItemNames
local function findNewItems(craftableItems, existingNames)
	---@type string[]
	local newItems = {}
	for _, item in ipairs(craftableItems) do
		if not existingNames[item.name] then
			table.insert(newItems, item.name)
		end
	end

	return util.dedupe(newItems)
end

---@param itemNames string[]
---@return table<string, string[]> itemsByMod
local function groupByMod(itemNames)
	---@type table<string, string[]>
	local itemsByMod = {}
	for _, name in ipairs(itemNames) do
		local mod = name:match("^(.-):")
		itemsByMod[mod] = itemsByMod[mod] or {}
		table.insert(itemsByMod[mod], name)
	end

	return itemsByMod
end

---@param lines string[]
---@param mod string
---@return number? headerIndex Line index of "[mod], or nil.
local function findSectionHeader(lines, mod)
	for i, line in ipairs(lines) do
		if line:match("%[" .. mod .. "%]") then
			return i
		end
	end
	return nil
end

---@param lines string[]
---@param headerIndex number
---@return number insertIndex
local function findSectionEnd(lines, headerIndex)
	for i = headerIndex + 1, #lines do
		if lines[i]:match("%[.*%]") then
			return i - 1
		end
	end
	return #lines
end

---@param newItemNames string[]
local function appendUnstockedItems(newItemNames)
	if #newItemNames == 0 then
		return
	end
	local itemsByMod = groupByMod(newItemNames)

	local file = fs.open(config.STOCK_FILE, "r")

	---@type string[]
	local lines = {}
	if file then
		local line = file.readLine()
		while line do
			table.insert(lines, line)
			line = file.readLine()
		end
		file.close()
	end

	for mod, items in pairs(itemsByMod) do
		local start = findSectionHeader(lines, mod)
		local last
		if start then
			last = findSectionEnd(lines, start)
		else
			table.insert(lines, "[" .. mod .. "]")
			last = #lines + 1
		end
		for i, item in ipairs(items) do
			table.insert(lines, last + i - 1, item .. " 0")
		end
		if not start then
			table.insert(lines, "")
		end
	end

	file = fs.open(config.STOCK_FILE, "w")
	if not file then
		error("Could not open '" .. config.STOCK_FILE .. "'")
	end
	for _, line in ipairs(lines) do
		file.writeLine(line)
	end
	file.close()
end

local craftableItems = bridge.getCraftableItems()
if not craftableItems then
	return
end
local existingNames = getExistingItemNames()
local newItems = findNewItems(craftableItems, existingNames)

if #newItems == 0 then
	return
end

appendUnstockedItems(newItems)
print(("Added %d new unstocked item(s):"):format(#newItems))
for _, name in ipairs(newItems) do
	print("  " .. name)
end
