-- BiggerReactors Controller Main Entry Point
-- This is the main entry point for the controller

local controller = require("reactors_controller.core.controller")
local gui = require("reactors_controller.gui.mainframe")

-- Initialize the controller
local function main()
    print("Starting BiggerReactors Controller V2...")
    
    -- Initialize controller core
    local ctrl = controller.new()
    
    -- Initialize GUI
    local frame = gui.new(ctrl)
    
    -- Start main loop
    ctrl:run(frame)
end

main()
