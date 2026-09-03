-- install.lua
-- Generic installer for apps in this repo. Reads manifest.json from root,
-- then fetches every file listed for the requested app.
--
-- Usage (from CC shell, once file is on the computer):
--   install <app_name>
--   	installs app
--   install 
--   	lists available apps

-- ----Configuration----

---@type string The repo to pull from. (Format: User/Repo)
local REPO = "Seamoose04/CC-ATM10"

---@type string The repo branch to pull from
local BRANCH = "main"

---@type string Base URL for raw GitHub content fetches
local RAW_BASE = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/"

-- ----Fetch helpers----

---Fetches a file as text
---@param url string Must be a valid, reachable HTTP(S) URL.
---@return string|nil contents # The file's contents, or nil if the request failed.
local function fetchText(url)
	local response, err = http.get(url)
	if not response then
		error("Failed to fetch " .. url .. ": " .. tostring(err))
	end
	local content = response.readAll()
	response.close()
	return content
end

---Processes a manifest. string -> table
---@param raw string
---@return table manifest
local function processManifest(raw)
	local ok, manifest = pcall(textutils.unserialiseJSON, raw)
	if not ok or type(manifest) ~= "table" then
		error("Could not parse manifest.")
	end
	return manifest
end

---Fetches the manifest file, as a table
---@return table manifest
local function fetchManifest()
	local raw = fetchText(RAW_BASE .. "manifest.json")
	if not raw then
		error(("manifest.json could not be found in repo %q"):format(REPO))
	end
	return processManifest(raw)
end

-- ----Install logic----

---Installs a file to a relative path on the CC-Machine,
---creating directories if needed. Installed relative to
---the shells cwd at runtime.
---@param relativePath string Path relative to the repo root
local function installFile(relativePath)
	local url = RAW_BASE .. relativePath
	local destDir = fs.getDir(relativePath)
	if destDir ~= "" and not fs.exists(destDir) then
		fs.makeDir(destDir)
	end

	print("  fetching " .. relativePath)
	local content = fetchText(url)

	local file = fs.open(relativePath, "w")
	if not file then
		error ("Failed to open file: " .. relativePath)
	end
	file.write(content)
	file.close()
end

---Lists apps available in manifest
---@param manifest table Manifest to read from
---@return table names # Sorted names of apps from the manifest
local function listManifest(manifest)
	local names = {}
	for name, _ in pairs(manifest) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

---Prints manifest apps
---@param manifest table
local function printManifestHelp(manifest)
	local names = listManifest(manifest)
	if #names == 0 then
		print("(manifest is currently empty)")
	else
		print("Available apps:")
		for _, name in ipairs(names) do
			print("  " .. name)
		end
	end
end


---Installs a specific app by name
---@param appName string App to download
---@param manifest table The manifest to read from
local function installApp(appName, manifest)
	local files = manifest[appName]

	if not files then
		print("No app named '" .. appName .. "' in manifest.")
		printManifestHelp(manifest)
		return
	end

	print("Installing '" .. appName .. "' (" .. #files .. " files)...")
	for _, relativePath in ipairs(files) do
		local ok, err = pcall(installFile, relativePath)
		if not ok then
			print("FAILED on " .. relativePath .. ": " .. tostring(err))
			print("Install aborted.")
			return
		end
	end
	print("Done. '" .. appName .. "' installed.")
end

---@param args string[]
local function runFullInstaller(args)
	---@class Util
	local util = dofile("common/util.lua")

	local appManifest = fetchManifest()

	---@class ArgumentParser
	local parser = dofile("common/args.lua").new({
		prog = fs.getName(shell.getRunningProgram())
	})

	parser:addArgument("app-name", { required=true, help="The app to install" })
	parser:addArgument("--autostart", { help="The app's startup script to autorun" })
	parser:addArgument("--list", { type="boolean", default=false, help="Lists startup scripts if app is provided, otherwise lists apps" })
	local parsed = parser:parse(args)

	if parsed.app_name then
		installApp(parsed.app_name, appManifest)

		local autostartManifestRaw = util.readFile("startup.json")
		if not autostartManifestRaw then
			error("Could not read 'startup.json'")
		end
		local autostartManifest = processManifest(autostartManifestRaw)

		if parsed.autostart then
			installApp(parsed.autostart, autostartManifest)
		elseif parsed.list then
			printManifestHelp(autostartManifest)
		end
	elseif parsed.list then
		printManifestHelp(appManifest)
	end
end

---Runs the minimal/initial installer
---@param args string[]
local function runLiteInstaller(args)
	local appName = args[1]

	local manifest = fetchManifest()
	if appName then
		installApp(appName, manifest)
	else
		print("Usage: install <app_name>")
		printManifestHelp(manifest)
	end
end

-- ----Entry point----

local args = { ... }
if fs.exists("common/args.lua") then
	runFullInstaller(args)
else
	runLiteInstaller(args)
end
