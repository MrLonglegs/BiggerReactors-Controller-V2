-- BiggerReactors-Controller-V2 GUI
-- Basalt-based monitor display for reactor and turbine monitoring

local basalt = require("basalt")
local refreshRate = 0.5

local function getControllerStatusColor()
    local switch = {
        [true] = colors.green,
        [false] = colors.red
    }
    return switch[Controller.IsRunning] or colors.gray
end

local function getControllerStatus()
    local switch = {
        [true] = "On",
        [false] = "Off"
    }
    return switch[Controller.IsRunning] or "Unknown"
end

local monitor = peripheral.find("monitor")
if monitor == nil then return end

local main = basalt.addMonitor():setMonitor(monitor):setBackground(colors.black)

--#region Layout: Two-column flexbox

local flexbox_main =
main:addFlexbox()
    :setWidth("parent.w")
    :setHeight("parent.h")
    :setDirection("row")
    :setSpacing(1)
    :setBackground(main.getBackground())

-- Left column: Graphs (energy buffer + rod level)
local flexbox_main_left =
flexbox_main:addFlexbox()
            :setHeight("parent.h")
            :setWidth("parent.w / 2")
            :setDirection("column")
            :setBackground(main.getBackground())

-- Right column: Controls + Statistics
local flexbox_main_right =
flexbox_main:addFlexbox()
            :setHeight("parent.h")
            :setWidth("parent.w / 2")
            :setDirection("column")
            :setJustifyContent("center")
            :setBackground(main.getBackground())

--#endregion

--#region Left Panel: Graphs

local flexbox_graphs =
flexbox_main_left:addFlexbox()
    :setWidth("parent.w")
    :setHeight("parent.h * 0.6")
    :setBorder(colors.red)
    :setBackground(main.getBackground())
    :setDirection("column")
    :setJustifyContent("center")

flexbox_graphs:addLabel()
    :setText(" System Status ")
    :setHeight(1)
    :setForeground(colors.white)
    :setBackground(main.getBackground())
    flexbox_graphs:addBreak()

local EnergyColumn =
flexbox_graphs:addProgressbar()
    :setDirection(3)
    :setWidth(8)
    :setHeight("parent.h * 0.5")
    :setProgressBar(colors.lime)
    :setBackground(colors.red)

local EnergyLabel =
flexbox_graphs:addLabel()
    :setText("Energy Buffer: 0%")
    :setHeight(1)
    :setForeground(colors.white)
    :setBackground(main.getBackground())

local RodLevelColumn =
flexbox_graphs:addProgressbar()
    :setDirection(1)
    :setWidth(8)
    :setHeight("parent.h * 0.5")
    :setProgressBar(colors.orange)
    :setBackground(colors.red)

local RodLabel =
flexbox_graphs:addLabel()
    :setText("Rod Level: 0%")
    :setHeight(1)
    :setForeground(colors.white)
    :setBackground(main.getBackground())

--#endregion

--#region Right Panel: Controls

local flexbox_controls =
flexbox_main_right:addFlexbox()
    :setBorder(colors.lightBlue)
    :setBackground(main:getBackground())
    :setDirection("column")
    :setJustifyContent("center")

flexbox_controls:addLabel()
    :setText(" Controls ")
    :setHeight(1)
    :setForeground(colors.white)
    :setBackground(main.getBackground())
    flexbox_controls:addBreak()

local ToggleButton =
flexbox_controls:addButton()
    :setText("Controller Status: Off")
    :setWidth("parent.w / 1.2")
    :setHeight(2)
    :onClick(function ()
        Controller:SetAllActive(not Controller.IsRunning)
    end)
    flexbox_controls:addBreak()

local ResetButton =
flexbox_controls:addButton()
    :setText("Emergency Shutdown")
    :setWidth("parent.w / 1.2")
    :setHeight(2)
    :onClick(function ()
        Controller:EmergencyShutdown("Manual emergency shutdown via GUI")
    end)
    flexbox_controls:addBreak()

--#endregion

--#region Right Panel: Statistics

local flexbox_statistics =
flexbox_main_right:addFlexbox()
    :setBorder(colors.lime)
    :setBackground(main.getBackground())
    :setDirection("column")
    :setJustifyContent("center")

flexbox_statistics:addLabel()
    :setText(" Statistics ")
    :setHeight(1)
    :setForeground(colors.white)
    :setBackground(main.getBackground())
    flexbox_statistics:addBreak()

local Label_RPM =
flexbox_statistics:addLabel()
    :setText("RPM: 0")
    :setHeight(1)
    :setForeground(colors.white)

local Label_Generated =
flexbox_statistics:addLabel()
    :setText("Generated: 0 RF/t")
    :setHeight(1)
    :setForeground(colors.white)

local Label_Reactors =
flexbox_statistics:addLabel()
    :setText("Reactors: 0")
    :setHeight(1)
    :setForeground(colors.white)

local Label_Turbines =
flexbox_statistics:addLabel()
    :setText("Turbines: 0")
    :setHeight(1)
    :setForeground(colors.white)

local Label_RodLevel =
flexbox_statistics:addLabel()
    :setText("Avg Rod Level: 0%")
    :setHeight(1)
    :setForeground(colors.white)

local Label_Status =
flexbox_statistics:addLabel()
    :setText("Status: Initializing...")
    :setHeight(1)
    :setForeground(colors.white)

--#endregion

--#region Refresh Thread

local function getReactorCount()
    local reactors = Controller.ApiHelper.getReactors()
    return #reactors
end

local function getTurbineCount()
    local turbines = Controller.ApiHelper.getTurbines()
    return #turbines
end

local function getTotalRPM()
    local total = 0
    local turbines = Controller.ApiHelper.getTurbines()
    for _, turbine in pairs(turbines) do
        local rpm = Controller.ApiHelper.getRotorSpeed(turbine)
        if rpm then total = total + rpm end
    end
    return math.floor(total)
end

local function getTotalGenerated()
    local total = 0
    local reactors = Controller.ApiHelper.getReactors()
    for _, reactor in pairs(reactors) do
        local produced = Controller.ApiHelper.getProducedLastTick(reactor)
        if produced then total = total + produced end
    end
    return math.floor(total)
end

local RefreshThread = main:addThread()
RefreshThread:start(function ()
    while true do
        -- Update button state
        ToggleButton:setBackground(getControllerStatusColor())
        ToggleButton:setText("Controller Status: " .. getControllerStatus())

        -- Update energy buffer progress
        local stored = Controller.ApiHelper.getAllEnergyStored()
        local capacity = Controller.ApiHelper.getAllEnergyCapacity()
        local bufferPct = 0
        if capacity and capacity > 0 then
            bufferPct = math.floor((stored / capacity) * 100)
        end
        EnergyColumn:setProgress(bufferPct)
        EnergyLabel:setText("Energy Buffer: " .. bufferPct .. "%")

        -- Update rod level progress
        RodLevelColumn:setProgress(Controller.AverageRodLevel)
        RodLabel:setText("Rod Level: " .. math.floor(Controller.AverageRodLevel) .. "%")

        -- Update statistics
        local rpm = getTotalRPM()
        Label_RPM:setText("RPM: " .. rpm)

        local generated = getTotalGenerated()
        Label_Generated:setText("Generated: " .. generated .. " RF/t")

        local reactorCount = getReactorCount()
        Label_Reactors:setText("Reactors: " .. reactorCount)

        local turbineCount = getTurbineCount()
        Label_Turbines:setText("Turbines: " .. turbineCount)

        Label_RodLevel:setText("Avg Rod Level: " .. math.floor(Controller.AverageRodLevel) .. "%")

        Label_Status:setText("Status: " .. getControllerStatus())

        os.sleep(refreshRate)
    end
end)

-- Start controller loop in background thread
main:addThread():start(function ()
    Controller:AutoUpdate()
end)

return basalt

--#endregion