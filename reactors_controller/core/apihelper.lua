local ApiHelper = {}

-- GETTERS

-- General
function ApiHelper.getReactors()
    local big_reactors = { peripheral.find("BigReactors-Reactor") }
    local bigger_reactors = { peripheral.find("BiggerReactors_Reactor") }

    local all_reactors = {}

    if (big_reactors ~= nil) then
        for _, big_reactor in pairs(big_reactors) do
            big_reactor.Class = "BigReactors-Reactor"
            table.insert(all_reactors, big_reactor)
        end
    end  
    if (bigger_reactors ~= nil) then
        for _, bigger_reactor in pairs(bigger_reactors) do
            bigger_reactor.Class = "BiggerReactors_Reactor"
            table.insert(all_reactors, bigger_reactor)
        end
    end

    return all_reactors
end

function ApiHelper.getTurbines()
    local big_turbines = { peripheral.find("BigReactors-Turbine") }
    local bigger_turbines = { peripheral.find("BiggerReactors_Turbine") }

    local all_turbines = {}

    if (big_turbines ~= nil) then
        for _, big_turbine in pairs(big_turbines) do
            big_turbine.Class = "BigReactors-Turbine"
            table.insert(all_turbines, big_turbine)
        end
    end
    if (bigger_turbines ~= nil) then
        for _, bigger_turbine in pairs(bigger_turbines) do
            bigger_turbine.Class = "BiggerReactors_Turbine"
            table.insert(all_turbines, bigger_turbine)
        end
    end

    return all_turbines
end

function ApiHelper.getEnergyCapacity(o)
    if (o ~= nil) then
        local switch = {
            ["BiggerReactors_Reactor"] = function ()
                return o.battery().capacity()
            end,
            ["BiggerReactors_Turbine"] = function ()
                return o.battery().capacity()
            end,
            ["BigReactors-Reactor"] = function ()
                return o.getEnergyCapacity()
            end,
            ["BigReactors-Turbine"] = function ()
                return o.getEnergyCapacity()
            end
        }
        return switch[o.Class]()
    end
end

function ApiHelper.getAllEnergyCapacity()
    local totalCapacity = 0
    for _, reactor in ipairs(ApiHelper.getReactors()) do
        if (reactor.reactorType == "passive") then
            totalCapacity = totalCapacity + ApiHelper.getEnergyCapacity(reactor)
        end
    end
    for _, turbine in ipairs(ApiHelper.getTurbines()) do
        totalCapacity = totalCapacity + ApiHelper.getEnergyCapacity(turbine)
    end
    return totalCapacity
end

function ApiHelper.getEnergyStored(o)
    if (o ~= nil) then
        local switch = {
            ["BiggerReactors_Reactor"] = function ()
                return o.battery().stored()
            end,
            ["BiggerReactors_Turbine"] = function ()
                return o.battery().stored()
            end,
            ["BigReactors-Reactor"] = function ()
                return o.getEnergyStored()
            end,
            ["BigReactors-Turbine"] = function ()
                return o.getEnergyStored()
            end
        }
        return switch[o.Class]()
    end
end

function ApiHelper.getAllEnergyStored()
    local totalEnergy = 0
    for _, reactor in pairs(ApiHelper.getReactors()) do
        if (reactor.reactorType == "passive") then
            totalEnergy = totalEnergy + ApiHelper.getEnergyStored(reactor)
        end
    end
    for _, turbine in pairs(ApiHelper.getTurbines()) do
        totalEnergy = totalEnergy + ApiHelper.getEnergyStored(turbine)
    end
    return totalEnergy
end

-- Reactor Specific
function ApiHelper.getReactorType(reactor)
    if(reactor ~= nil) then
        local switch = {
            ["BiggerReactors_Reactor"] = function ()
                if (reactor.coolantTank()) then
                    return "active"
                elseif (reactor.battery()) then
                    return "passive"
                end
            end,
            ["BigReactors-Reactor"] = function ()
                if (reactor.isActivelyCooled()) then
                    return "active"
                elseif not (reactor.isActivelyCooled()) then
                    return "passive"
                end
            end
        }
        return switch[reactor.Class]()
    end
end

function ApiHelper.getProducedLastTick(reactor)
    if(reactor ~= nil) then
        local switch = {
            ["BiggerReactors_Reactor"] = function ()
                if (ApiHelper.getReactorType(reactor) == "passive") then
                    return reactor.battery().producedLastTick()
                elseif (ApiHelper.getReactorType(reactor) == "active") then
                    return reactor.coolantTank().transitionedLastTick()
                end
            end,
            ["BigReactors-Reactor"] = function ()
                if (ApiHelper.getReactorType(reactor) == "passive") then
                    return reactor.getEnergyProducedLastTick()
                elseif (ApiHelper.getReactorType(reactor) == "active") then
                    return reactor.getHotFluidProducedLastTick()
                end
            end
        }
        return switch[reactor.Class]()
    end
end

function ApiHelper.getRodLevels(reactor)
    if(reactor ~= nil) then
        local switch = {
            ["BiggerReactors_Reactor"] = function ()
                return reactor.getControlRodsLevels()
            end,
            ["BigReactors-Reactor"] = function ()
                return reactor.getControlRodsLevels()
            end
        }
        return switch[reactor.Class]()
    end
end

function ApiHelper.getHotFluidCapacity(reactor)
    if (reactor ~= nil and ApiHelper.getReactorType(reactor) == "active") then
        local switch = {
            ["BiggerReactors_Reactor"] = function ()
                if (reactor.coolantTank()) then
                    return reactor.coolantTank().capacity()
                end
            end,
            ["BigReactors-Reactor"] = function ()
                return reactor.getHotFluidAmountMax()
            end
        }
        return switch[reactor.Class]()
    end
end

function ApiHelper.getHotFluidStored(reactor)
    if (reactor ~= nil) then
        local switch = {
            ["BiggerReactors_Reactor"] = function ()
                if (reactor.coolantTank()) then
                    return reactor.coolantTank().hotFluidAmount()
                end
            end,
            ["BigReactors-Reactor"] = function ()
                return reactor.getHotFluidAmount()
            end
        }
        return switch[reactor.Class]()
    end
end

-- Turbine Specific
function ApiHelper.getRotorSpeed(turbine)
    if(turbine ~= nil) then
        local switch = {
            ["BiggerReactors_Turbine"] = function ()
                return turbine.rotor().RPM()
            end,
            ["BigReactors-Turbine"] = function ()
                return turbine.getRotorSpeed()
            end
        }
        return switch[turbine.Class]()
    end
end

function ApiHelper.getFluidFlowRate(turbine)
    if(turbine ~= nil) then
        local switch = {
            ["BiggerReactors_Turbine"] = function ()
                return turbine.fluidTank().nominalFlowRate()
            end,
            ["BigReactors-Turbine"] = function ()
                return turbine.getFluidFlowRate()
            end
        }
        return switch[turbine.Class]()
    end
end

-- SETTERS

function ApiHelper.setActive(o, value)
    if (value ~= nil and type(value) == "boolean") then
        local switch = {
            ["BiggerReactors_Reactor"] = function ()
                o.setActive(value)
            end,
            ["BiggerReactors_Turbine"] = function ()
                o.setActive(value)
            end,
            ["BigReactors-Reactor"] = function ()
                o.setActive(value)
            end,
            ["BigReactors-Turbine"] = function ()
                o.setActive(value)
            end
        }
        switch[o.Class]()
    end
end

-- Reactor Specific

function ApiHelper.setControlRods(reactor, level)
    if (level ~= nil and type(level) =="number") then
        level = math.max(level, 0)
        level = math.min(level, 100)

        local switch = {
            ["BiggerReactors_Reactor"] = function ()
                reactor.setAllControlRodLevels(level)
            end,
            ["BigReactors-Reactor"] = function ()
                reactor.setAllControlRodLevels(level)
            end
        }
        switch[reactor.Class]()
    end
end

-- Turbine Specific

function ApiHelper.setFluidFlowRate(turbine, value)
    if(turbine ~= nil and type(value) == "number") then
        local switch = {
            ["BiggerReactors_Turbine"] = function ()
                turbine.fluidTank().setNominalFlowRate(value)
            end,
            ["BigReactors-Turbine"] = function ()
                turbine.setFluidFlowRateMax(value)
            end
        }
        switch[turbine.Class]()
    end
end

function ApiHelper.setCoilEngaged(turbine, value)
    if(turbine ~= nil and type(value) == "boolean") then
        local switch = {
            ["BiggerReactors_Turbine"] = function ()
                turbine.setCoilEngaged(value)
            end,
            ["BigReactors-Turbine"] = function ()
                turbine.setInductorEngaged(value)
            end
        }
        switch[turbine.Class]()
    end
end

return ApiHelper