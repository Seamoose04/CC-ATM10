-- tests/args_test.lua

---@type Runner
local runner = dofile("tests/framework.lua")

---@type ArgumentParser
local parser = dofile("common/args.lua")

print("== args: happy paths ==")

runner.describe("positional and flag parsing", function(ctx)
	ctx.it("parsees a positional string", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("input_file")
		local parsed = p:parse({"my_input.txt"})
		ctx.expect(parsed.input_file == "my_input.txt", "'input_file' should equal 'my_input.txt'")
	end)

	ctx.it("coerces a positional number", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("count", { type = "number" })
		local parsed = p:parse({"42"})
		ctx.expect(type(parsed.count) == "number" and parsed.count == 42, "'count' should coerce the number to 42")
	end)

	ctx.it("parses flag=value as string", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("--mode", { type = "string" })
		local parsed = p:parse({ "--mode=fast" })
		ctx.expect(parsed.mode == "fast", "'--mode' should equal 'fast'")
	end)

	ctx.it("falls back to a default when omitted", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("--mode", { type = "string", default = "slow" })
		local parsed = p:parse({})
		ctx.expect(parsed.mode == "slow", "'--mode' should fall back to 'slow'")
	end)

	ctx.it("treats a no-value boolean flag, as true", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("--verbose", { type = "boolean", default = false })
		local parsed = p:parse({ "--verbose" })
		ctx.expect(parsed.verbose == true, "'--verbose' should default to true")
	end)

	ctx.it("parses an explicit --flag=false", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("--verbose", { type = "boolean", default = true })
		local parsed = p:parse({ "--verbose=false" })
		ctx.expect(parsed.verbose == false, "'--verbose' should parse as false")
	end)

	ctx.it("maps multiple positionals in order", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("input_file")
		p:addArgument("chunk_id", { type = "number" })
		local parsed = p:parse({ "src.txt", "16" })
		ctx.expect(parsed.input_file == "src.txt" and parsed.chunk_id == 16, "positionals should map in order")
	end)
end)

print("== args: error paths ==")
runner.describe("strict failures", function(ctx)
	ctx.it("fails on a missing required positional", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("input_file")
		local ok = pcall(function() return p:parse({}) end)
		ctx.expect(not ok, "a required positional should fail when omitted")
	end)

	ctx.it("fails a value flag with no value", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("--mode", { type = "string" })
		local ok = pcall(function() return p:parse({ "--mode" }) end)
		ctx.expect(not ok, "a non-bool flag, requires a value")
	end)

	ctx.it("fails on an incorrect type", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("--count", { type = "number" })
		local ok = pcall(function() return p:parse({ "--count=abc" }) end)
		ctx.expect(not ok, "'--count' should reject a non-numeric value")
	end)

	ctx.it("fails on an invalid choice", function()
		local p = parser.new({ prog = "test" })
		p:addArgument("--mode", { type = "string", choices = { "slow", "fast" } })
		local ok = pcall(function() return p:parse({ "--mode=warp" }) end)
		ctx.expect(not ok, "'--mode' should reject a value that isnt a choice")
	end)
end)

runner.finish("args")
