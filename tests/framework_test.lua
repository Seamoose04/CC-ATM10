-- tests/framework_test.lua
-- Tests the tests, to make sure they work!

---@type TestRunner
local Framework = dofile("tests/framework.lua")

Framework.describe("testing framework", function(ctx)
	ctx.it("passes a true condition", function()
		ctx.expect(true)
	end)

	ctx.it("no asserted case, still passes", function() end)

	ctx.it("accepts a reason, with expects", function()
		ctx.expect(true, "true is true")
	end)

	ctx.it("passes, when all expects succeed", function()
		ctx.expect(true, "true is true")
		ctx.expect(1 == 1, "1 is 1")
	end)

	ctx.it("detects a failing condition", function()
		local ok = pcall(function() ctx.expect(false) end)
		ctx.expect(not ok, "expect should raise on false")
	end)

	ctx.it("shows custom failure message", function()
		local ok, msg = pcall(ctx.expect, false, "boom")
		ctx.expect(msg == "boom", "custom reason should surface")
	end)
end)

Framework.describe("the runner counts failures", function(ctx)
	ctx.it("a failing case is caught, pt1", function()
		ctx.expect(false, "deliberate failure")
	end)
	ctx.it("a failing case is caught, pt2", function()
		local passed, failed = Framework.stats()
		ctx.expect(failed > 0, "previous failure should be caught")
	end)
end)

Framework.finish("tests")
