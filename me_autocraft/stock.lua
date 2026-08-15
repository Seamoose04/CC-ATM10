-- me_autocraft/stock.lua

---@class StockEntry
---@field item string Registry name, e.g. "minecraft:redstone".
---@field target number Quantity to keep in stock.

---@type StockEntry[]
return {
	{ item = "minecraft:redstone", target = 512 },
	{ item = "minecraft:iron_ingot", target = 1024 },
}
