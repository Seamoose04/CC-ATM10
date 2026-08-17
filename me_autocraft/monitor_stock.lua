--- me_autocraft/monitor_stock.lua

---@type Util
local util = dofile("common/util.lua")

---@type RednetUtil
local rednetUtil = dofile("common/rednet.lua")

---@type Protocols
local protocols = dofile("common/protocols.lua")

---@type MonitorUtil
local monitorUtil = dofile("common/monitor.lua")
local monitor = monitorUtil.get()

local TEXT_SCALE = 0.5
local NAME_PERCENT = 0.35
local SPACING = 2
monitor.setTextScale(TEXT_SCALE)
local WIDTH, HEIGHT = monitor.getSize()
local ITEMS_WIDTH = 13 -- longest looks like: 435.2k/500.0k
local NAME_WIDTH = math.floor((WIDTH - ITEMS_WIDTH - SPACING * 2) * NAME_PERCENT)
local BAR_WIDTH = WIDTH - ITEMS_WIDTH - NAME_WIDTH - SPACING * 2

if NAME_WIDTH < 3 or BAR_WIDTH < 3 then
	error("Monitor too small for this layout (need a larger monitor or smaller TEXT_SCALE)")
end

---@alias SortMode "default" | "alphabetical" | "percent_stock"

---@type SortMode
local currentSortMode = "default"
local currentSortReverse = false

---@param snapshot StockSnapshot[]
---@param mode SortMode
---@param reverse boolean
---@return StockSnapshot[]
local function sortSnapshot(snapshot, mode, reverse)
	local sorted = { table.unpack(snapshot) }

	if mode == "alphabetical" then
		table.sort(sorted, function(a, b)
			return a.item < b.item -- A->Z
		end)
	elseif mode == "percent_stock" then
		table.sort(sorted, function(a, b)
			local percentA
			if a.target == 0 then
				percentA = 1
			else
				percentA = a.current / a.target
			end

			local percentB
			if b.target == 0 then
				percentB = 1
			else
				percentB = b.current / b.target
			end

			return percentA > percentB -- high->low
		end)
	end

	if reverse then
		local n = #sorted
		for i = 1, math.floor(n / 2) do
			sorted[i], sorted[n - i + 1] = sorted[n - i + 1], sorted[i]
		end
	end

	return sorted
end

---@param snapshot StockSnapshot[]
local function render(snapshot)
	local sorted = sortSnapshot(snapshot, currentSortMode, currentSortReverse)

	for i, stockSnapshot in ipairs(sorted) do
		-- Clear
		monitor.setCursorPos(1, i)
		monitor.setBackgroundColor(colors.black)
		monitor.clearLine()

		-- Name
		monitor.setCursorPos(1, i)
		local shortenedName = stockSnapshot.item:sub(1, NAME_WIDTH)
		monitor.setBackgroundColor(colors.black)
		monitor.setTextColor(colors.lightGray)
		monitor.write(shortenedName)

		-- Progress bar
		monitor.setCursorPos(NAME_WIDTH + SPACING + 1, i)
		---@type ccTweaked.colors.color
		local color
		if stockSnapshot.crafting then
			color = colors.lightBlue
		elseif stockSnapshot.current >= stockSnapshot.target then
			color = colors.green
		else
			color = colors.red
		end
		monitor.setBackgroundColor(color)
		local progress = util.round(BAR_WIDTH * math.min(1, stockSnapshot.current / stockSnapshot.target))
		monitor.write(string.rep(" ", progress))
		monitor.setBackgroundColor(colors.gray)
		monitor.write(string.rep(" ", BAR_WIDTH - progress))

		-- Numbers
		monitor.setCursorPos(WIDTH - ITEMS_WIDTH, i)
		monitor.setBackgroundColor(colors.black)
		monitor.setTextColor(colors.lightGray)
		local stockAbb = util.abbreviateNumber(stockSnapshot.current, 1)
		local stockPadded = util.padStart(stockAbb, 6)
		local targetAbb = util.abbreviateNumber(stockSnapshot.target, 1)
		local targetPadded = util.padEnd(targetAbb, 6)
		monitor.write(stockPadded .. "/" .. targetPadded)
	end
end

if not rednetUtil.init() then
	error("No modem found")
end

while true do
	local packet = rednetUtil.receive(protocols.ME_STOCK)
	if packet then
		---@cast packet StockPacket
		render(packet.snapshot)
	end
end
