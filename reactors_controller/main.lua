-- BiggerReactors-Controller-V2
-- Main entry point for the Bigger Reactors Controller

-- Load configuration (falls back to defaults if config.lua is not present)
local config = require("config")

-- Default controller parameters
local defaultParams = {
    --General
    Looptime = 0.2,

    --Reactor
    ReactorTargetBufferMin = 33,
    ReactorTargetBufferMax = 90, --For proper functionality, this value should not exceed 90

    --Turbine
    TargetRPM = 3600,
    MaxRPM = 5000,
    TurbineTargetBufferMin = 30,
    TurbineTargetBufferMax = 70,
    MaxFlowRate = 13000,
}

-- Merge user configuration with defaults
local params = {}
for key, value in pairs(defaultParams) do
    params[key] = value
end
if config ~= nil then
    for key, value in pairs(config) do
        if value ~= nil then
            params[key] = value
        end
    end
end

-- Initialize the controller
Controller = require("core.controller").new(params)

--Create the main frame which shall be portrayed on an Monitor
--If no valid Monitor is connected, the script will run headless.
local gui = require("gui.mainframe")
if (gui ~= nil) then
    gui.autoUpdate()
else
    Controller:AutoUpdate()
end