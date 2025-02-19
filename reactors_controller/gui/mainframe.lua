local basalt = require("gui.basalt")
local refreshRate = 0.2

local function getControllerStatusColor()
    local switch = {
        [true] = colors.green,
        [false] = colors.red
    }
    return switch[Controller.IsRunning]
end
local function getControllerStatus()
    local switch = {
        [true] = "On",
        [false] = "Off"
    }
    return switch[Controller.IsRunning]
end

local monitor = peripheral.find("monitor")
if monitor == nil then return end
local main = basalt.addMonitor():setMonitor(monitor):setBackground(colors.black)

--#region Main
local flexbox_main =
main:addFlexbox()
    :setWidth("parent.w")
    :setHeight("parent.h")
    :setDirection("row")
    :setSpacing(0)
    :setBackground(main.getBackground())

local flexbox_main_left =
flexbox_main:addFlexbox()
            :setHeight("parent.h")
            :setWidth("parent.w / 2")
            :setDirection("row")
            :setBackground(main.getBackground())

local flexbox_main_right = 
flexbox_main:addFlexbox()
            :setHeight("parent.h")
            :setWidth("parent.w / 2")
            :setDirection("column")
            :setJustifyContent("center")
            :setBackground(main.getBackground())
--#region


--#region Graphs

local flexbox_graphs =
flexbox_main_left:addFlexbox()
    :setWidth("parent.w")
    :setHeight("parent.h")
    :setBorder(colors.red)
    :setBackground(main.getBackground())
    :setDirection("row")
    :setJustifyContent("center")

flexbox_graphs:addLabel()
                    :setText(" Graphs ")
                    :setHeight(1)
                    :setForeground(colors.white)
                    :setBackground(main.getBackground())
                    flexbox_graphs:addBreak()

local flexbox_graphs_sub =
flexbox_graphs:addFlexbox()
                    :setWidth("parent.w - 2")
                    :setHeight("parent.h - 3")
                    :setDirection("row")
                    :setJustifyContent("center")
                    :setBackground(main.getBackground())

local EnergyColumn =
flexbox_graphs_sub:addProgressbar()
                    :setDirection(3)
                    :setWidth(6)
                    :setHeight("parent.h")
                    :setProgressBar(colors.green)
                    :setBackground(colors.red)

local RodLevelColumn = 
flexbox_graphs_sub:addProgressbar()
                    :setDirection(1)
                    :setWidth(6)
                    :setHeight("parent.h")
                    :setProgressBar(colors.orange)
                    :setBackground(colors.red)

--#endregion
--#region Controls

local flexbox_controls =
flexbox_main_right:addFlexbox()
    :setBorder(colors.lightBlue)
    :setBackground(main:getBackground())
    :setDirection("row")
    :setJustifyContent("center")
            
flexbox_controls:addLabel()
                :setText(" Controls ")
                :setHeight(1)
                :setForeground(colors.white)
                :setBackground(main.getBackground())
                flexbox_controls:addBreak()

local ToggleButton =
flexbox_controls:addButton()
                :setText("Controller Status: ")
                :setWidth("parent.w / 1.2")
                :setHeight(1)
                :onClick(function ()
                    Controller:SetAllActive(not Controller.IsRunning)
                end)
                flexbox_controls:addBreak()

--#endregion
--#region Statistics

local flexbox_statistics =
flexbox_main_right:addFlexbox()
    :setBorder(colors.lime)
    :setBackground(main.getBackground())
    :setDirection("row")
    :setJustifyContent("center")

flexbox_statistics:addLabel()
                    :setText(" Statistics ")
                    :setHeight(1)
                    :setForeground(colors.white)
                    :setBackground(main.getBackground())
                    flexbox_statistics:addBreak()

local Label_FE_Generating =
flexbox_statistics:addLabel()
                    :setText("Generating: ")
                    :setWidth("parent.w / 1.2")
                    :setForeground(colors.white)

--#endregion


local RefreshThread = main:addThread()
RefreshThread:start(function ()
    while true do
        ToggleButton:setBackground(getControllerStatusColor())
        ToggleButton:setText("Controller Status: " ..getControllerStatus())

        EnergyColumn:setProgress(Controller.ApiHelper.getAllEnergyStored() / Controller.ApiHelper.getAllEnergyCapacity() * 100)

        RodLevelColumn:setProgress(Controller.AverageRodLevel)

        os.sleep(refreshRate)
    end
end)


main:addThread():start(function ()
    Controller:AutoUpdate()
end)

return basalt