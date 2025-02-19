Controller = require("core.controller").new()

--Create the main frame which shall be portrayed on an Monitor
--If no valid Monitor is connected, the script will run headless.
local gui = require("gui.mainframe")
if (gui ~= nil) then
    gui.autoUpdate()
else
    Controller:AutoUpdate()
end