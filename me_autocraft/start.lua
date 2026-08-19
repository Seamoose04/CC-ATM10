-- me_autocraft/start.lua
-- Entrypoint of the "me_autocraft" app.

local function runAutocraft()
	dofile("me_autocraft/autocraft.lua")
end

local function runSyncPatterns()
	dofile("me_autocraft/sync_patterns.lua")
end

-- Start
parallel.waitForAll(runAutocraft, runSyncPatterns)
