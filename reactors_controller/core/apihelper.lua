-- BiggerReactors-Controller-V2 API Helper
-- Abstraction layer for BigReactors and BiggerReactors peripheral APIs

local ApiHelper = {}

-- Peripheral type definitions
local PERIPHERAL_TYPES = {
    REACTOR = {
        BIG_REACTORS = "BigReactors-Reactor",
        BIGGER_REACTORS = "BiggerReactors_Reactor",
    },
    TURBINE = {
        BIG_REACTORS = "BigReactors-Turbine",
        BIGGER_REACTORS = "BiggerReactors_Turbine",
    },
}

-- Utility: Get method for a peripheral based on its class
local function getMethod(peripheral, class, method)
    local switch = {
        [PERIPHERAL_TYPES.REACTOR.BIG_REACTORS] = function()
            return peripheral[method]
        end,
        [PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS] = function()
            return peripheral[method]
        end,
        [PERIPHERAL_TYPES.TURBINE.BIG_REACTORS] = function()
            return peripheral[method]
        end,
        [PERIPHERAL_TYPES.TURBINE.BIGGER_REACTORS] = function()
            return peripheral[method]
        end,
    }
    local handler = switch[class]
    if handler then
        return handler()
    end
    return nil
end

-- Utility: Safely call a method with error handling
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        return nil, result
    end
    return result
end

-- === REACTOR DISCOVERY ===

function ApiHelper.getReactors()
    local all_reactors = {}

    local big_reactors = { peripheral.find("BigReactors-Reactor") }
    if big_reactors then
        for _, big_reactor in pairs(big_reactors) do
            big_reactor.Class = PERIPHERAL_TYPES.REACTOR.BIG_REACTORS
            table.insert(all_reactors, big_reactor)
        end
    end

    local bigger_reactors = { peripheral.find("BiggerReactors_Reactor") }
    if bigger_reactors then
        for _, bigger_reactor in pairs(bigger_reactors) do
            bigger_reactor.Class = PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS
            table.insert(all_reactors, bigger_reactor)
        end
    end

    return all_reactors
end

function ApiHelper.getTurbines()
    local all_turbines = {}

    local big_turbines = { peripheral.find("BigReactors-Turbine") }
    if big_turbines then
        for _, big_turbine in pairs(big_turbines) do
            big_turbine.Class = PERIPHERAL_TYPES.TURBINE.BIG_REACTORS
            table.insert(all_turbines, big_turbine)
        end
    end

    local bigger_turbines = { peripheral.find("BiggerReactors_Turbine") }
    if bigger_turbines then
        for _, bigger_turbine in pairs(bigger_turbines) do
            bigger_turbine.Class = PERIPHERAL_TYPES.TURBINE.BIGGER_REACTORS
            table.insert(all_turbines, bigger_turbine)
        end
    end

    return all_turbines
end

-- === ENERGY HELPERS ===

function ApiHelper.getEnergyCapacity(o)
    if o == nil then return nil end

    local methods = {
        batteryCapacity = {
            [PERIPHERAL_TYPES.REACTOR.BIG_REACTORS] = function() return o.getEnergyCapacity end,
            [PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS] = function() return function() return o.battery().capacity() end end,
            [PERIPHERAL_TYPES.TURBINE.BIG_REACTORS] = function() return o.getEnergyCapacity end,
            [PERIPHERAL_TYPES.TURBINE.BIGGER_REACTORS] = function() return function() return o.battery().capacity() end end,
        }
    }

    local methodGetter = methods.batteryCapacity[o.Class]
    if methodGetter then
        local method = methodGetter()
        if method then
            return safeCall(method)
        end
    end
    return nil
end

function ApiHelper.getEnergyStored(o)
    if o == nil then return nil end

    local methods = {
        batteryStored = {
            [PERIPHERAL_TYPES.REACTOR.BIG_REACTORS] = function() return o.getEnergyStored end,
            [PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS] = function() return function() return o.battery().stored() end end,
            [PERIPHERAL_TYPES.TURBINE.BIG_REACTORS] = function() return o.getEnergyStored end,
            [PERIPHERAL_TYPES.TURBINE.BIGGER_REACTORS] = function() return function() return o.battery().stored() end end,
        }
    }

    local methodGetter = methods.batteryStored[o.Class]
    if methodGetter then
        local method = methodGetter()
        if method then
            return safeCall(method)
        end
    end
    return nil
end

function ApiHelper.getAllEnergyCapacity()
    local totalCapacity = 0
    for _, reactor in pairs(ApiHelper.getReactors()) do
        local stored = ApiHelper.getEnergyStored(reactor)
        if stored == nil or reactor.storedThisTick == nil or stored < reactor.capacity then
            local capacity = ApiHelper.getEnergyCapacity(reactor)
            if capacity then
                totalCapacity = totalCapacity + capacity
            end
        end
    end
    for _, turbine in pairs(ApiHelper.getTurbines()) do
        local capacity = ApiHelper.getEnergyCapacity(turbine)
        if capacity then
            totalCapacity = totalCapacity + capacity
        end
    end
    return totalCapacity
end

function ApiHelper.getAllEnergyStored()
    local totalEnergy = 0
    for _, reactor in pairs(ApiHelper.getReactors()) do
        local energy = ApiHelper.getEnergyStored(reactor)
        if energy then
            totalEnergy = totalEnergy + energy
        end
    end
    for _, turbine in pairs(ApiHelper.getTurbines()) do
        local energy = ApiHelper.getEnergyStored(turbine)
        if energy then
            totalEnergy = totalEnergy + energy
        end
    end
    return totalEnergy
end

-- === REACTOR HELPERS ===

function ApiHelper.getReactorType(reactor)
    if reactor == nil then return nil end

    if reactor.Class == PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS then
        if reactor.coolantTank() then
            return "active"
        elseif reactor.battery() then
            return "passive"
        end
    elseif reactor.Class == PERIPHERAL_TYPES.REACTOR.BIG_REACTORS then
        local isActivelyCooled = safeCall(function() return reactor.isActivelyCooled() end)
        if isActivelyCooled then
            return "active"
        else
            return "passive"
        end
    end
    return nil
end

function ApiHelper.getProducedLastTick(reactor)
    if reactor == nil then return nil end

    local reactorType = ApiHelper.getReactorType(reactor)

    if reactor.Class == PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS then
        if reactorType == "passive" then
            return safeCall(function() return reactor.battery().producedLastTick() end)
        elseif reactorType == "active" then
            return safeCall(function() return reactor.coolantTank().transitionedLastTick() end)
        end
    elseif reactor.Class == PERIPHERAL_TYPES.REACTOR.BIG_REACTORS then
        if reactorType == "passive" then
            return safeCall(function() return reactor.getEnergyProducedLastTick() end)
        elseif reactorType == "active" then
            return safeCall(function() return reactor.getHotFluidProducedLastTick() end)
        end
    end
    return nil
end

function ApiHelper.getRodLevels(reactor)
    if reactor == nil then return nil end

    local method = getMethod(reactor, reactor.Class, "getControlRodsLevels")
    return safeCall(function() return reactor.getControlRodsLevels() end)
end

function ApiHelper.setControlRods(reactor, level)
    if reactor == nil or level == nil or type(level) ~= "number" then return end

    level = math.max(0, math.min(100, level))

    if reactor.Class == PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS or 
       reactor.Class == PERIPHERAL_TYPES.REACTOR.BIG_REACTORS then
        safeCall(function() reactor.setAllControlRodLevels(level) end)
    end
end

function ApiHelper.getHotFluidCapacity(reactor)
    if reactor == nil or ApiHelper.getReactorType(reactor) ~= "active" then return nil end

    if reactor.Class == PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS then
        local tank = safeCall(function() return reactor.coolantTank() end)
        if tank then
            return safeCall(function() return tank.capacity() end)
        end
    elseif reactor.Class == PERIPHERAL_TYPES.REACTOR.BIG_REACTORS then
        return safeCall(function() return reactor.getHotFluidAmountMax() end)
    end
    return nil
end

function ApiHelper.getHotFluidStored(reactor)
    if reactor == nil then return nil end

    if reactor.Class == PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS then
        local tank = safeCall(function() return reactor.coolantTank() end)
        if tank then
            return safeCall(function() return tank.hotFluidAmount() end)
        end
    elseif reactor.Class == PERIPHERAL_TYPES.REACTOR.BIG_REACTORS then
        return safeCall(function() return reactor.getHotFluidAmount() end)
    end
    return nil
end

function ApiHelper.getReactorTemperature(reactor)
    if reactor == nil then return nil end

    -- Try to get temperature from BiggerReactors active reactor
    if reactor.Class == PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS then
        if reactor.coolantTank() then
            return safeCall(function() return reactor.coolantTank().temperature() end)
        end
    end

    -- Temperature monitoring not available for BigReactors (older mod)
    return nil
end

-- === TURBINE HELPERS ===

function ApiHelper.getRotorSpeed(turbine)
    if turbine == nil then return nil end

    if turbine.Class == PERIPHERAL_TYPES.TURBINE.BIGGER_REACTORS then
        local rotor = safeCall(function() return turbine.rotor() end)
        if rotor then
            return safeCall(function() return rotor.RPM() end)
        end
    elseif turbine.Class == PERIPHERAL_TYPES.TURBINE.BIG_REACTORS then
        return safeCall(function() return turbine.getRotorSpeed() end)
    end
    return nil
end

function ApiHelper.getFluidFlowRate(turbine)
    if turbine == nil then return nil end

    if turbine.Class == PERIPHERAL_TYPES.TURBINE.BIGGER_REACTORS then
        local fluidTank = safeCall(function() return turbine.fluidTank() end)
        if fluidTank then
            return safeCall(function() return fluidTank.nominalFlowRate() end)
        end
    elseif turbine.Class == PERIPHERAL_TYPES.TURBINE.BIG_REACTORS then
        return safeCall(function() return turbine.getFluidFlowRate() end)
    end
    return nil
end

-- === SETTERS ===

function ApiHelper.setActive(o, value)
    if value == nil or type(value) ~= "boolean" then return end

    if o.Class == PERIPHERAL_TYPES.REACTOR.BIGGER_REACTORS or 
       o.Class == PERIPHERAL_TYPES.REACTOR.BIG_REACTORS or
       o.Class == PERIPHERAL_TYPES.TURBINE.BIGGER_REACTORS or
       o.Class == PERIPHERAL_TYPES.TURBINE.BIG_REACTORS then
        safeCall(function() o.setActive(value) end)
    end
end

function ApiHelper.setFluidFlowRate(turbine, value)
    if turbine == nil or value == nil or type(value) ~= "number" then return end

    if turbine.Class == PERIPHERAL_TYPES.TURBINE.BIGGER_REACTORS then
        local fluidTank = safeCall(function() return turbine.fluidTank() end)
        if fluidTank then
            safeCall(function() fluidTank.setNominalFlowRate(value) end)
        end
    elseif turbine.Class == PERIPHERAL_TYPES.TURBINE.BIG_REACTORS then
        safeCall(function() turbine.setFluidFlowRateMax(value) end)
    end
end

function ApiHelper.setCoilEngaged(turbine, value)
    if turbine == nil or value == nil or type(value) ~= "boolean" then return end

    if turbine.Class == PERIPHERAL_TYPES.TURBINE.BIGGER_REACTORS then
        safeCall(function() turbine.setCoilEngaged(value) end)
    elseif turbine.Class == PERIPHERAL_TYPES.TURBINE.BIG_REACTORS then
        safeCall(function() turbine.setInductorEngaged(value) end)
    end
end

return ApiHelper