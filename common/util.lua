-- common/util.lua

---@class Util
local util = {}

---@param n number
---@return number rounded
function util.round(n)
	return math.floor(n + 0.5)
end

---@param n number Must be positive
---@param decimals integer
---@return string abbreviated
function util.abbreviateNumber(n, decimals)
	local shorthands = { "k", "m", "b", "t" }
	local shortened = n
	local degree = 0
	local precision = 10 ^ decimals

	while shortened / 1000 >= 1 do
		shortened = shortened / 1000
		degree = degree + 1
	end

	if degree == 0 then
		return tostring(util.round(shortened * precision) / precision)
	end

	if degree > #shorthands then
		print("Warning: number too large to abbreviate.")
		return tostring(util.round(shortened * precision) / precision) .. "?"
	end
	return tostring(util.round(shortened * precision) / precision) .. shorthands[degree]
end

---@param str string
---@param width integer
---@return string padded
function util.padStart(str, width)
	local padding = width - #str
	if padding <= 0 then
		return str
	end
	return string.rep(" ", padding) .. str
end

---@param str string
---@param width integer
---@return string padded
function util.padEnd(str, width)
	local padding = width - #str
	if padding <= 0 then
		return str
	end
	return str .. string.rep(" ", padding)
end

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
