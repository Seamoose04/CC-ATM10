-- me_autocraft/config.lua

---@class AppConfig
---@field POLLING_RATE number Seconds between full passes over the tracked item list.
---@field MAX_CONCURRENT_CRAFTS number Max number of simultaneous crafts which this script can trigger.

---@type AppConfig
return {
	POLLING_RATE = 10,
	MAX_CONCURRENT_CRAFTS = 2,
}
