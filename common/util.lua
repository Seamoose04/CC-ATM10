-- common/util.lua

---@class Util
local util = {}

---@param t table
---@return number
function util.tableCount(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

---@param path string
---@return string? contents
function util.readFile(path)
	local file = fs.open(path, "r")
	if not file then
		error("Could not open '" .. path .. "'")
	end

	local contents = file.readAll()
	file.close()

	return contents
end

return util
