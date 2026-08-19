-- me_autocraft/config.lua

---@class AppConfig
---@field POLLING_RATE number Seconds between full passes over the tracked item list.
---@field MAX_CONCURRENT_CRAFTS number Max number of simultaneous crafts which this script can trigger.
---@field STOCK_FILE string

---@type AppConfig
return {
	POLLING_RATE = 1,
	MAX_CONCURRENT_CRAFTS = 2,
	STOCK_FILE = "me_autocraft/stock.txt"
}
