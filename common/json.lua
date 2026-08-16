-- common/json.lua

---@type Util
local util = dofile("common/util.lua")

---@class Json
local json = {}

---@param path string
---@return table
function json.loadFile(path)
	local ok, raw = pcall(util.readFile, path)
	if not ok then
		error("Failed to open '" .. path .. "'")
	end

	if not raw then
		error("File '" .. path .. "' is empty")
	end

	local ok, result = pcall(textutils.unserialiseJSON, raw)
	if not ok or type(result) ~= "table" then
		error("Could not parse '" .. path .. "'")
	end

	return result
end
