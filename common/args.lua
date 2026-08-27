-- common/args.lua
-- Cmdline "args" api

---@type Util
local util = dofile("common/util.lua")

---@class ArgumentSpec
---@field name string Exact call string
---@field dest string Key used to store argument
---@field kind "positional"|"flag"
---@field type "string"|"number"|"boolean"
---@field required boolean
---@field default any
---@field help string?
---@field choices any[]?

---@class ArgumentParserOpts
---@field prog string? -- autofilled if left out

---@class ArgumentParser
---@field prog string
---@field description string?
---@field specs ArgumentSpec[]
local ArgumentParser = {}
ArgumentParser.__index = ArgumentParser

---@param opts ArgumentParserOpts?
function ArgumentParser.new(opts)
	local self = {
		prog = opts and opts.prog or fs.getName(shell.getRunningProgram()),
		specs = {}
	}
	return setmetatable(self, ArgumentParser)
end

---@class ArgumentOpts
---@field dest string?
---@field type "string"|"number"|"boolean"?
---@field required boolean?
---@field default any
---@field help string?
---@field choices any[]?

---@param name string
---@param opts ArgumentOpts
function ArgumentParser:addArgument(name, opts)
	---@type string?
	local flagName = name:match("^%-%-(.+)$")

	local dest = opts.dest
	if not dest then
		dest = (flagName or name):gsub("-", "_")
	end

	for _, spec in ipairs(self.specs) do
		if spec.name == name then
			error(("Spec already exists with name %q"):format(name))
		end
		if spec.dest == dest then
			error(("Spec already exists with dest %q"):format(dest))
		end
	end

	local required
	if flagName then
		required = opts.required or false
	else
		if opts.required == false then
			error(("Argument %q is positional. It must be required"):format(name))
		end
		required = true
	end

	local expectedType = opts.type or "string"
	local default = opts.default
	local choices = opts.choices

	if default ~= nil then
		if required then
			error(("addArgument(%q): required arguments should not have a default"):format(name))
		end
		if type(default) ~= expectedType then
			error(("addArgument(%q): default value is %s, expected %s"):format(
				name, type(default), expectedType))
		end
	end

	if choices then
		if #choices == 0 then
			error(("Argument %q has no choices"):format(name))
		end
		if expectedType == "boolean" then
			error(("addArgument(%q): giving choices for a boolean does not make sense..."):format(name))
		end
		for _, choice in ipairs(choices) do
			if type(choice) ~= expectedType then
				error(("addArgument(%q): choice of %s is not a %s"):format(
					name, tostring(choice), expectedType))
			end
		end
	end

	---@type ArgumentSpec
	local spec = {
		name = name,
		dest = dest,
		kind = (flagName and "flag") or "positional",
		type = expectedType,
		required = required,
		default = default,
		help = opts.help, -- TODO: default for unspecified help
		choices = choices,
	}

	table.insert(self.specs, spec)
end

---@param args string[]
---@return table<string, any>
function ArgumentParser:parse(args)
	---@param pos integer
	---@return ArgumentSpec? spec
	local function getPositionalSpec(pos)
		for _, spec in ipairs(self.specs) do
			if spec.kind == "positional" then
				pos = pos - 1
				if pos == 0 then
					return spec
				end
			end
		end
		return nil
	end

	---@param spec ArgumentSpec
	---@param raw string
	---@return any converted
	local function convertSpecValue(spec, raw)
		if spec.type == "string" then
			return raw
		elseif spec.type == "number" then
			return tonumber(raw)
		elseif spec.type == "boolean" then
			return util.toboolean(raw)
		end
		return nil
	end

	---@param spec ArgumentSpec
	---@param value any
	local function assertChoices(spec, value)
		if spec.choices and not util.contains(spec.choices, value) then
			self:fail(("Invalid value for flag %q. Choices are: [%s]"):format(spec.name, table.concat(spec.choices, ", ")))
		end
	end

	---@type table<string, any>
	local parsed = {}

	local positionalsCount = 0
	for _, arg in ipairs(args) do
		local flagKey, flagValue = arg:match("^%-%-([^=]+)=(.*)$")
		if not flagKey then
			flagKey = arg:match("^%-%-([^=]+)$")
		end

		if flagKey then
			local found = false
			for _, spec in ipairs(self.specs) do
				if spec.name == "--" .. flagKey then
					local value
					if flagValue == nil then
						if spec.type == "boolean" then
							value = true
						else
							self:fail(("Flag %q needs a value."):format(arg))
						end
					else
						local converted = convertSpecValue(spec, flagValue)
						if converted == nil then
							self:fail(("Incorrect type for flag %q. Expected %q."):format(arg, spec.type))
						end
						value = converted
						assertChoices(spec, value)
					end
					parsed[spec.dest] = value
					found = true
					break
				end
			end
			if not found then
				print(("Warning: %q does not match any flags, skipping."):format(arg))
				print(("  Run '%s --help' for Help"):format(self.prog))
			end
		else
			positionalsCount = positionalsCount + 1
			local spec = getPositionalSpec(positionalsCount)
			if not spec then
				self:fail(("Unexpected positional argument %q"):format(arg))
			end
			---@cast spec ArgumentSpec
			local value = convertSpecValue(spec, arg)
			if value == nil then
				self:fail(("Incorrect type for argument %q. Expected %q"):format(arg, spec.type))
			end
			assertChoices(spec, value)
			parsed[spec.dest] = value
		end
	end

	for _, spec in ipairs(self.specs) do
		if parsed[spec.dest] == nil then
			if spec.default ~= nil then
				parsed[spec.dest] = spec.default
			else
				if spec.required then
					self:fail(("Argument %q is missing. It is required"):format(spec.name))
				end
			end
		end
	end

	return parsed
end

---@param message string
function ArgumentParser:fail(message)
	print(message)
	print()
	print(self:getUsage())
	error(nil, 0)
end

---@param flag ArgumentSpec
---@return string Formatted
local function formatFlagPiece(flag)
	local piece
	if flag.type == "boolean" then
		piece = flag.name
	else
		piece = flag.name .. "=" .. flag.dest:upper()
	end
	if not flag.required then
		piece = "[" .. piece .. "]"
	end
	return piece
end

function ArgumentParser:printHelp()
	local lines = {}
	table.insert(lines, self:getUsage())
	table.insert(lines, "")

	local flags = {}
	table.insert(flags, "")
	table.insert(flags, "flags:")
	table.insert(flags, "positional arguments:")
	for _, spec in ipairs(self.specs) do
		if spec.kind == "positional" then
			table.insert(lines, "  " .. spec.name .. "  " .. (spec.help or ""))
		else
			table.insert(flags, "  " .. formatFlagPiece(spec) .. "  " .. (spec.help or ""))
		end
	end

	print(table.concat({ table.unpack(lines), table.unpack(flags) }, "\n"))
end

---@return string
function ArgumentParser:getUsage()
	local parts = { "usage:", self.prog }

	---@type ArgumentSpec[]
	local flags = {}
	for _, spec in ipairs(self.specs) do
		if spec.kind == "positional" then
			table.insert(parts, spec.name)
		elseif spec.required then
			table.insert(flags, formatFlagPiece(spec))
		end
	end

	return table.concat({ table.unpack(parts), table.unpack(flags) }, " ")
end

return ArgumentParser
