-- BiggerReactors-Controller-V2 Core Controller
-- Main control logic for reactor and turbine management

local Controller = { ApiHelper = require("reactors_controller.core.apihelper") }

Controller.IsRunning = false -- Variable to determine whether the control program should run
Controller.AverageRodLevel = 0
Controller.Version = "2.1.0"
Controller.LastError = nil
Controller.StartTime = 0

-- Default parameters (can be overridden by config)
Controller.DefaultParameters = {
    -- General
    Looptime = 0.2,

    -- Reactor
    ReactorTargetBufferMin = 33,
    ReactorTargetBufferMax = 90, -- For proper functionality, this value should not exceed 90

    -- Turbine
    TargetRPM = 3600,
    MaxRPM = 5000,
    TurbineTargetBufferMin = 30,
    TurbineTargetBufferMax = 70,
    MaxFlowRate = 13000,

    -- Safety
    SafetyShutoffTemperature = 1000,
    MaxEmergencyShutdownTime = 3600,
    TemperatureShutdownThreshold = 800,

    -- Advanced
    EnableGradualStartup = true,
    StartupTime = 60,
}

-- Sets Active Status for everything
function Controller:SetAllActive(value)
    for _, reactor in pairs(self.Reactors) do
        self.ApiHelper.setActive(reactor, value)
        self.ApiHelper.setControlRods(reactor, 0)
    end
    for _, turbine in pairs(self.Turbines) do
        self.ApiHelper.setActive(turbine, value)
        self.ApiHelper.setCoilEngaged(turbine, value)
        self.ApiHelper.setFluidFlowRate(turbine, 0)
    end
    self.IsRunning = value
end

-- Initialize static reactor values, which may vary from reactor to reactor.
function Controller:InitializeReactorValues()
    for _, reactor in pairs(self.Reactors) do
        if (self.ApiHelper.getReactorType(reactor) == "passive") then
            reactor.storedThisTick = self.ApiHelper.getEnergyStored(reactor)
            reactor.capacity = self.ApiHelper.getEnergyCapacity(reactor)
            reactor.maxBuffer = self.Parameters.ReactorTargetBufferMax / 100 * reactor.capacity
            reactor.minBuffer = self.Parameters.ReactorTargetBufferMin / 100 * reactor.capacity
        elseif (self.ApiHelper.getReactorType(reactor) == "active") then
            reactor.storedThisTick = self.ApiHelper.getHotFluidStored(reactor)
            reactor.capacity = self.ApiHelper.getHotFluidCapacity(reactor)
            reactor.maxBuffer = self.Parameters.ReactorTargetBufferMax / 100 * reactor.capacity
            reactor.minBuffer = self.Parameters.ReactorTargetBufferMin / 100 * reactor.capacity
        end
        reactor.diffRF = (self.Parameters.ReactorTargetBufferMax - self.Parameters.ReactorTargetBufferMin) / 100 * reactor.capacity
    end
end

-- Initialize static turbine values, which may vary from turbine to turbine.
function Controller:InitializeTurbineValues()
    for _, turbine in pairs(self.Turbines) do
        turbine.capacity = self.ApiHelper.getEnergyCapacity(turbine)
        turbine.maxBuffer = self.Parameters.TurbineTargetBufferMax / 100 * turbine.capacity
        turbine.minBuffer = self.Parameters.TurbineTargetBufferMin / 100 * turbine.capacity
        turbine.storedThisTick = self.ApiHelper.getEnergyStored(turbine)
    end
end

-- Adjust the control rods according to need.
function Controller:AdjustControlRods()
    for _, reactor in pairs(self.Reactors) do
        local currentBuffer = reactor.storedThisTick
        local diffb = self.Parameters.ReactorTargetBufferMax - self.Parameters.ReactorTargetBufferMin
        local diffr = diffb / 100
        local targetBufferT = reactor.bufferLost
        local currentBufferT = reactor.producedLastTick
        local diffBufferT = 1.0

        -- Avoid division by zero
        if targetBufferT and targetBufferT > 0 and currentBufferT then
            diffBufferT = currentBufferT / targetBufferT
        end

        local targetBuffer = reactor.diffRF / 2 + reactor.minBuffer

        currentBuffer = math.min(currentBuffer, reactor.maxBuffer)
        local equation1 = math.min((currentBuffer - reactor.minBuffer) / reactor.diffRF, 1)
        equation1 = math.max(equation1, 0)

        local rodLevel = reactor.rod
        if (reactor.storedThisTick < reactor.minBuffer) then
            rodLevel = 0
        elseif (reactor.storedThisTick < reactor.maxBuffer and reactor.storedThisTick > reactor.minBuffer) then
            equation1 = equation1 * (currentBuffer / targetBuffer)
            equation1 = equation1 * diffBufferT
            equation1 = equation1 * 100
            rodLevel = equation1
        elseif (reactor.storedThisTick > reactor.maxBuffer) then
            rodLevel = 100
        end

        -- Clamp rod level to valid range
        rodLevel = math.max(0, math.min(100, rodLevel))

        self.ApiHelper.setControlRods(reactor, rodLevel)
    end
end

-- Adjust the flowrate to achieve set RPM
function Controller:AdjustFlowRate()
    for _, turbine in pairs(self.Turbines) do
        -- Adjust flow rate based on RPM difference
        if turbine.RPM < self.Parameters.TargetRPM and turbine.flowRate < self.Parameters.MaxFlowRate then
            local newFlowRate = turbine.flowRate + turbine.flowRateStep
            newFlowRate = math.min(newFlowRate, self.Parameters.MaxFlowRate)
            self.ApiHelper.setFluidFlowRate(turbine, newFlowRate)
        end
        if turbine.RPM > self.Parameters.TargetRPM then
            local newFlowRate = turbine.flowRate - turbine.flowRateStep
            newFlowRate = math.max(newFlowRate, 0)
            self.ApiHelper.setFluidFlowRate(turbine, newFlowRate)
        end

        -- Manage coil engagement based on energy buffer
        if turbine.storedThisTick < turbine.minBuffer then
            self.ApiHelper.setCoilEngaged(turbine, true)
        end
        if turbine.storedThisTick > turbine.maxBuffer then
            self.ApiHelper.setCoilEngaged(turbine, false)
        end
    end
end

-- Check safety conditions (temperature, etc.)
function Controller:CheckSafety()
    -- TODO: Add safety checks when mod APIs are available
    -- For now, just return true
    return true
end

-- Emergency shutdown procedure
function Controller:EmergencyShutdown(reason)
    self.LastError = reason or "Emergency shutdown triggered"
    self:Log("ERROR: " .. self.LastError)
    self:SetAllActive(false)
    self.IsRunning = false
end

-- Gradual startup sequence
function Controller:GradualStartup()
    if not self.Parameters.EnableGradualStartup then
        self:SetAllActive(true)
        return
    end

    self:Log("Starting gradual startup sequence...")
    local startTime = os.clock()
    local startupTime = self.Parameters.StartupTime or 60

    -- Start with rods fully inserted, then gradually lower
    for _, reactor in pairs(self.Reactors) do
        self.ApiHelper.setControlRods(reactor, 100)
    end

    while os.clock() - startTime < startupTime do
        local progress = (os.clock() - startTime) / startupTime
        local rodLevel = math.floor(100 * (1 - progress))

        for _, reactor in pairs(self.Reactors) do
            self.ApiHelper.setControlRods(reactor, rodLevel)
        end

        self:UpdateStats()
        os.sleep(self.Parameters.Looptime)
    end

    self:SetAllActive(true)
    self:Log("Gradual startup complete")
end

-- Update the Stats of the reactors and turbines for further use in the script.
function Controller:UpdateStats()
    local rodLevels = {}

    for _, reactor in pairs(self.Reactors) do
        reactor.storedLastTick = reactor.storedThisTick
        reactor.producedLastTick = self.ApiHelper.getProducedLastTick(reactor)
        reactor.capacity = self.ApiHelper.getEnergyCapacity(reactor)

        if (self.ApiHelper.getReactorType(reactor) == "passive") then
            reactor.storedThisTick = self.ApiHelper.getEnergyStored(reactor)
        elseif (self.ApiHelper.getReactorType(reactor) == "active") then
            reactor.storedThisTick = self.ApiHelper.getHotFluidStored(reactor)
        end

        local rodLevelsTable = self.ApiHelper.getRodLevels(reactor)
        if rodLevelsTable and #rodLevelsTable > 0 then
            reactor.rod = rodLevelsTable[0] or rodLevelsTable[1] or 0
        else
            reactor.rod = 0
        end
        table.insert(rodLevels, reactor.rod)

        reactor.bufferLost = reactor.producedLastTick + reactor.storedLastTick - reactor.storedThisTick
    end

    for _, turbine in pairs(self.Turbines) do
        turbine.storedLastTick = turbine.storedThisTick
        turbine.storedThisTick = self.ApiHelper.getEnergyStored(turbine)
        turbine.RPM = self.ApiHelper.getRotorSpeed(turbine)
        turbine.flowRate = self.ApiHelper.getFluidFlowRate(turbine)
        turbine.flowRateStep = math.max(1, math.abs(self.Parameters.TargetRPM - turbine.RPM) * 0.5)
    end

    local rodLevelsSum = 0
    for _, rodLevel in pairs(rodLevels) do
        rodLevelsSum = rodLevelsSum + rodLevel
    end
    if #rodLevels > 0 then
        self.AverageRodLevel = (rodLevelsSum / #rodLevels)
    else
        self.AverageRodLevel = 0
    end
end

function Controller:Setup()
    self.Reactors = self.ApiHelper.getReactors()
    self.Turbines = self.ApiHelper.getTurbines()

    self:InitializeReactorValues()
    self:InitializeTurbineValues()

    self:GradualStartup()
    self.StartTime = os.clock()

    self:Update()
end

function Controller:Update()
    self:UpdateStats()

    -- Check safety before making adjustments
    if not self:CheckSafety() then
        return
    end

    if (self.IsRunning) then
        self:AdjustFlowRate()
        self:AdjustControlRods()
    end
end

function Controller:AutoUpdate()
    while true do
        self:Update()
        os.sleep(self.Parameters.Looptime)
    end
end

function Controller:SetRunning(value)
    if (value ~= nil) then
        self.IsRunning = value
        if not value then
            self:SetAllActive(false)
        end
    end
end

function Controller:Log(message)
    if self.Parameters and self.Parameters.EnableLogging then
        local logFile = self.Parameters.LogFile or "reactors_controller.log"
        local file = fs.open(logFile, "a")
        if file then
            file.writeLine(os.date("[%Y-%m-%d %H:%M:%S] ") .. message)
            file.close()
        end
    end
    if self.Parameters and self.Parameters.DebugMode then
        print("[Controller] " .. message)
    end
end

function Controller.new(params)
    local newController = {}
    setmetatable(newController, Controller)
    Controller.__index = Controller

    -- Merge default parameters with provided ones
    newController.Parameters = {}
    for key, value in pairs(Controller.DefaultParameters) do
        newController.Parameters[key] = value
    end
    if params then
        for key, value in pairs(params) do
            if value ~= nil then
                newController.Parameters[key] = value
            end
        end
    end

    newController:Setup()

    return newController
end

return Controller