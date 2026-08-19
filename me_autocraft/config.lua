-- me_autocraft/config.lua

---@class AppConfig
---@field POLLING_RATE number Seconds between full passes over the tracked item list.
---@field MAX_CONCURRENT_CRAFTS number Max number of simultaneous crafts which this script can trigger.
---@field MAX_CALCULATION_WAIT number Max number of seconds to wait for a crafting calculation to succeed, before cancelling.
---@field STOCK_FILE string

---@type AppConfig
return {
	POLLING_RATE = 1,
	MAX_CONCURRENT_CRAFTS = 2,
	MAX_CALCULATION_WAIT = 3,
	STOCK_FILE = "me_autocraft/stock.txt"
}
