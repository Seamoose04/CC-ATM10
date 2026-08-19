-- me_autocraft/bridge.lua

---@type MeBridge
local meBridge = peripheral.find("me_bridge")

---@class Bridge
local bridge = {}

---@param itemName string
---@return number amount
---@return boolean isCraftable
function bridge.getItemInfo(itemName)
	local filter = { name = itemName }

	local ok, result = pcall(meBridge.getItem, filter)
	local count = (ok and result and result.count) or 0

	local craftOk, craftable = pcall(meBridge.isCraftable, filter)
	local isCraftable = (craftOk and craftable) or false

	return count, isCraftable
end

---@param itemName string
---@param count number
---@return CraftingJob? job
function bridge.craftItem(itemName, count)
	local ok, result, err = pcall(meBridge.craftItem, { name = itemName, count = count })
	if not ok then
		return nil
	end
	return result
end

---@param itemName string
---@param craftingCpu string?
---@return boolean success
function bridge.isItemCrafting(itemName, craftingCpu)
	local ok, result, err = pcall(meBridge.isCrafting, { name = itemName }, craftingCpu)
	if not ok then
		return false
	end
	return result or false
end

---@return ItemStack[]
function bridge.getCraftableItems()
	local ok, items, err = pcall(meBridge.getCraftableItems, {})
	if not ok then
		return {}
	end

	return items or {}
end

return bridge
