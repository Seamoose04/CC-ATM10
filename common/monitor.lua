-- common/monitor.lua

-- Shared monitor functions

---@class MonitorUtil
local monitorUtil = {}

--- Finds the monmior peripheral, erroring if not found.
---@return ccTweaked.peripheral.Monitor
function monitorUtil.get()
	---@type ccTweaked.peripheral.Monitor?
	local monitor = peripheral.find("monitor")
	if not monitor then
		error("Cannot find monitor")
	end
	return monitor
end

return monitorUtil
