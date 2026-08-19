---@meta

---@class ItemFilter
---@field name string? Item/tag name. Prefix with # for tags.
---@field type string? Force "item" | "fluid" | "chemical".
---@field count number? Amount.
---@field nbt string? NBT match, MC 1.20.4 and older only.
---@field components table? Data component match, MC 1.20.5+ (replaces nbt).
---@field fingerprint string? MD5 hash identifying one exact item; overrides name/nbt if set.
---@field toSlot number? Target inventory slot (import/export only).
---@field fromSlot number? Source inventory slot (import/export only).

---@class ItemStack
---@field name string Registry key of the item.
---@field tags table List of item tags.
---@field count number Amount of items in the stack.
---@field displayName string
---@field maxStackSize number
---@field components table NBT/component data.
---@field fingerprint string
---@field slot number? Slot number when in an inventory.
---@field isCraftable boolean Whether a pattern exists for this item.

---@class CraftingJob
---@field cpu AE2CraftingCPU? The crafting CPU assigned to this job. Nil for RS Bridge
local CraftingJob = {}
---@return number
function CraftingJob:getId() end
---@return boolean
function CraftingJob:isDone() end
---@return boolean
function CraftingJob:isCanceled() end
---@return boolean
function CraftingJob:isCraftingStarted() end
---@return boolean
function CraftingJob:isCalculationStarted() end
---@return boolean
function CraftingJob:isCalculationNotSuccessful() end
---@return boolean
function CraftingJob:hasErrorOccurred() end
---@return string
function CraftingJob:getDebugMessage() end
---@return ItemStack
function CraftingJob:getRequestedItem() end
---@return number
function CraftingJob:getElapsedTime() end
---@return number
function CraftingJob:getTotalItems() end
---@return number
function CraftingJob:getItemProgress() end
---@return table
function CraftingJob:getEmittedItems() end
---@return table
function CraftingJob:getUsedItems() end
---@return table
function CraftingJob:getMissingItems() end
---@return boolean
function CraftingJob:hasMultiplePaths() end
---@return ItemStack
function CraftingJob:getFinalOutput() end
---@return boolean
function CraftingJob:cancel() end
---@return number
function CraftingJob:getUsedBytes() end

---@class AE2CraftingCPU
---@field storage number Available storage in bytes.
---@field coProcessors number Available co-processing units.
---@field isBusy boolean Whether the CPU is currently performing a task.
---@field craftingJob CraftingJob? The job it currently performs, if any.
---@field name string "Unnamed" if not named, otherwise the CPU's given name.
---@field selectionMode string CPU selection mode: ANY | PLAYER_ONLY | MACHINE_ONLY.

---@class MeBridge
local me_bridge = {}

---@param filter ItemFilter
---@return ItemStack? result
---@return string? err
function me_bridge.getItem(filter) end

---@param filter ItemFilter
---@return boolean?
function me_bridge.isCraftable(filter) end

---@param filter ItemFilter
---@return boolean?
function me_bridge.isCrafting(filter) end

---@param filter ItemFilter
---@return CraftingJob? job
---@return string? err
function me_bridge.craftItem(filter) end

---@param filter ItemFilter
---@return ItemStack[]? result
---@return string? err
function me_bridge.getCraftableItems(filter) end
