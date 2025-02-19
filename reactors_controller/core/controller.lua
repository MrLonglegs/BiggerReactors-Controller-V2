local Controller = { ApiHelper = require("core/ApiHelper") }

Controller.IsRunning = false --Variable to determine whether the control program should run
Controller.AverageRodLevel = 0

Controller.Parameters = {
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

--Sets Active Status for everything
function Controller:SetAllActive(value)
    for _, reactor in pairs(self.Reactors) do
        self.ApiHelper.setActive(reactor, value)
        self.ApiHelper.setControlRods(self.RodLevel)
    end
    for _, turbine in pairs(self.Turbines) do
        self.ApiHelper.setActive(turbine, value)
        self.ApiHelper.setCoilEngaged(turbine, value)
        self.ApiHelper.setFluidFlowRate(turbine, 0)
    end
    self.IsRunning = value
end

--Initialize static reactor values, which may vary from reactor to reactor.
function Controller:InitializeReactorValues()
    for _, reactor in pairs(self.Reactors) do
        if (self.ApiHelper.getReactorType(reactor) == "passive") then
            reactor.storedThisTick = self.ApiHelper.getEnergyStored(reactor)
            reactor.maxBuffer = self.Parameters.ReactorTargetBufferMax / 100 * self.ApiHelper.getEnergyCapacity(reactor)
            reactor.minBuffer = self.Parameters.ReactorTargetBufferMin / 100 * self.ApiHelper.getEnergyCapacity(reactor)
        elseif (self.ApiHelper.getReactorType(reactor) == "active") then
            reactor.storedThisTick = self.ApiHelper.getHotFluidStored(reactor)
            reactor.maxBuffer = self.Parameters.ReactorTargetBufferMax / 100 * self.ApiHelper.getHotFluidCapacity(reactor)
            reactor.minBuffer = self.Parameters.ReactorTargetBufferMin / 100 * self.ApiHelper.getHotFluidCapacity(reactor)
        end
    end
end

--Initialize static turbine values, which may vary from turbine to turbine.
function Controller:InitializeTurbineValues()
    for _, turbine in pairs(self.Turbines) do
        turbine.maxBuffer = self.Parameters.TurbineTargetBufferMax / 100 * self.ApiHelper.getEnergyCapacity(turbine)
        turbine.minBuffer = self.Parameters.TurbineTargetBufferMin / 100 * self.ApiHelper.getEnergyCapacity(turbine)
        turbine.storedThisTick = self.ApiHelper.getEnergyStored(turbine)
    end
end

--Adjust the control rods according to need.
function Controller:AdjustControlRods()
    for _, reactor in pairs(self.Reactors) do
        local currentBuffer = reactor.storedThisTick
        local diffb = self.Parameters.ReactorTargetBufferMax - self.Parameters.ReactorTargetBufferMin
        reactor.diffRF = diffb / 100 * reactor.capacity
        local diffr = diffb / 100
        local targetBufferT = reactor.bufferLost
        local currentBufferT = reactor.producedLastTick
        local diffBufferT = currentBufferT / targetBufferT
        local targetBuffer = reactor.diffRF / 2 + reactor.minBuffer

        currentBuffer = math.min(currentBuffer, reactor.maxBuffer)
        local equation1 = math.min((currentBuffer - reactor.minBuffer)/reactor.diffRF, 1)
        equation1 = math.max(equation1, 0)

        local rodLevel = reactor.rod
        if (reactor.storedThisTick < reactor.minBuffer) then
            rodLevel = 0
        elseif ((reactor.storedThisTick < reactor.maxBuffer and reactor.storedThisTick > reactor.minBuffer)) then
            equation1 = equation1 * (currentBuffer / targetBuffer) --^ 2
            equation1 = equation1 * diffBufferT --^ 5
            equation1 = equation1 * 100

            rodLevel = equation1
        elseif (reactor.storedThisTick > reactor.maxBuffer) then
            rodLevel = 100
        end

        self.ApiHelper.setControlRods(reactor, rodLevel)
    end
end

--Adjust the flowrate to achieve set RPM
function Controller:AdjustFlowRate()
    for _, turbine in pairs(self.Turbines) do
        if turbine.RPM < self.Parameters.TargetRPM and turbine.flowRate < self.Parameters.MaxFlowRate then
            self.ApiHelper.setFluidFlowRate(turbine, turbine.flowRate + turbine.flowRateStep)
        end
        if turbine.RPM > self.Parameters.TargetRPM then
            self.ApiHelper.setFluidFlowRate(turbine, turbine.flowRate - (turbine.flowRateStep * -1))
        end
        if turbine.storedThisTick < turbine.minBuffer then
            self.ApiHelper.setCoilEngaged(turbine, true)
        end
        if turbine.storedThisTick > turbine.maxBuffer then
            self.ApiHelper.setCoilEngaged(turbine, false)
        end
    end
end

--Update the Stats of the reactors and turbines for further use in the script.
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

        reactor.rod = self.ApiHelper.getRodLevels(reactor)[0]
        table.insert(rodLevels, reactor.rod)

        reactor.bufferLost = reactor.producedLastTick + reactor.storedLastTick - reactor.storedThisTick
    end
    for _, turbine in pairs(self.Turbines) do
        turbine.storedLastTick = turbine.storedThisTick
        turbine.storedThisTick = self.ApiHelper.getEnergyStored(turbine)
        turbine.RPM = self.ApiHelper.getRotorSpeed(turbine)
        turbine.flowRate = self.ApiHelper.getFluidFlowRate(turbine)
        turbine.flowRateStep = (self.Parameters.TargetRPM - turbine.RPM) * 1
    end

    local rodLevelsSum = 0
    for _, rodLevel in pairs(rodLevels) do
        rodLevelsSum = rodLevelsSum + rodLevel
    end
    self.AverageRodLevel = (rodLevelsSum / #rodLevels)
end

function Controller:Setup()
    self.Reactors = self.ApiHelper.getReactors()
    self.Turbines = self.ApiHelper.getTurbines()

    self:InitializeReactorValues()
    self:InitializeTurbineValues()

    self:SetAllActive(true)
    
    self:Update()
end

function Controller:Update()
    self:UpdateStats()
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
    end
end

function Controller.new()
    local newController = {}
    setmetatable(newController, Controller)
    Controller.__index = Controller

    newController:Setup()

    return newController
end

return Controller