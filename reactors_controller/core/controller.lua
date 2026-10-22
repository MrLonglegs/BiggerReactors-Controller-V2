-- Core Controller Module
-- Manages reactor state, control logic, and API communication

local apihelper = require("reactors_controller.core.apihelper")

local Controller = {}
Controller.__index = Controller

function Controller.new()
    local self = setmetatable({}, Controller)
    self.reactors = {}
    self.running = false
    self.config = {
        update_interval = 1, -- seconds
        safety_threshold = 0.9 -- 90% capacity
    }
    return self
end

function Controller:add_reactor(reactor_data)
    table.insert(self.reactors, reactor_data)
end

function Controller:get_reactor_status(index)
    if self.reactors[index] then
        return apihelper.fetch_status(self.reactors[index].address)
    end
    return nil
end

function Controller:update_all()
    for i, reactor in ipairs(self.reactors) do
        local status = apihelper.fetch_status(reactor.address)
        if status then
            self.reactors[i].status = status
        end
    end
end

function Controller:run(frame)
    self.running = true
    print("Controller running...")
    
    while self.running do
        self:update_all()
        
        if frame then
            frame:render(self.reactors)
        end
        
        os.sleep(self.config.update_interval)
    end
end

function Controller:stop()
    self.running = false
end

return Controller
