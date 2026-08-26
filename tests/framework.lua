-- tests/framework.lua
-- Test framwork for offline, CC-Tweaked, Lua 5.2 testing.

---@class TestRunner
local Runner = {}

local _passed, _failed = 0, 0

--- Fail the current case unless cond is "true"
---@param cond boolean
---@param msg string? Message for failure
function Runner.expect(cond, msg)
	if not cond then
		error(msg or "unexpected condition", 3)
	end
end

--- Run a single test inside a describe block; Print pass/fail
---@param fullName string Test name
---@param fn fun(): nil The callback
local function _runCase(fullName, fn)
	local ok, err = pcall(fn)
	if ok then
		_passed = _passed + 1
		print(("  \226\156\147 PASS %s"):format(fullName))
	else
		_failed = _failed + 1
		print(("  \226\156\151 FAIL %s\n        %s"):format(fullName, tostring(err)))
	end
end

---@class TestContext
---@field it fun(name: string, fn: fun(): nil): nil
---@field expect fun(cond: boolean, msg?: string): nil

---@param title string
---@param body fun(ctx: TestContext): nil
function Runner.describe(title, body)
	print(("\n%s"):format(title))
	local ctx = {}

	---@param name string
	---@param fn fun(): nil
	function ctx.it(name, fn)
		_runCase(title .. " > " .. name, fn)
	end

	---@param cond boolean
	---@param msg string?
	function ctx.expect(cond, msg)
		Runner.expect(cond, msg)
	end

	body(ctx)
end

---@param label string?
function Runner.finish(label)
	local total = _passed + _failed
	print(("\n%s - %d/%d passed (failed: %d)"):format(
		label or "Summary", _passed, total, _failed
	))
	if _failed > 0 then
		os.exit(1)
	end
end

---@return number passed
---@return number failed
function Runner.stats()
	return _passed, _failed
end

return Runner
