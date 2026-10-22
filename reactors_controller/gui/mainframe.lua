-- GUI Main Frame Module
-- Handles the user interface for reactor monitoring and control

local MainFrame = {}
MainFrame.__index = MainFrame

function MainFrame.new(controller)
    local self = setmetatable({}, MainFrame)
    self.controller = controller
    self.width = 80
    self.height = 25
    self.selected_reactor = 1
    return self
end

function MainFrame:render(reactors)
    -- Clear screen
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Header
    print("═══════════════════════════════════════")
    print("   BIGGER REACTORS CONTROLLER V2")
    print("═══════════════════════════════════════")
    print("")
    
    -- Reactor list
    for i, reactor in ipairs(reactors) do
        local prefix = (i == self.selected_reactor) and "> " or "  "
        local status = reactor.status and "ONLINE" or "OFFLINE"
        local energy = reactor.status and reactor.status.energy_stored or 0
        local capacity = reactor.status and reactor.status.energy_capacity or 0
        local pct = capacity > 0 and math.floor((energy / capacity) * 100) or 0
        
        print(string.format("%s[%d] %s - %s - %d%% (%d/%d RF)",
            prefix, i, reactor.name or "Unknown", status, pct, energy, capacity))
    end
    
    print("")
    print("Controls: [↑/↓] Select  [SPACE] Toggle  [Q] Quit")
end

function MainFrame:handle_input(key)
    if key == "up" and self.selected_reactor > 1 then
        self.selected_reactor = self.selected_reactor - 1
    elseif key == "down" and self.selected_reactor < #self.controller.reactors then
        self.selected_reactor = self.selected_reactor + 1
    elseif key == "space" then
        local reactor = self.controller.reactors[self.selected_reactor]
        if reactor then
            self.controller:toggle_reactor(self.selected_reactor)
        end
    elseif key == "q" then
        self.controller:stop()
    end
end

return MainFrame
