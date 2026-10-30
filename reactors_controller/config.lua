-- BiggerReactors-Controller-V2 Configuration File
--
-- Customize reactor and turbine control parameters below.
-- These values will be loaded by the controller at startup.

return {
    -- Control loop timing (in seconds)
    Looptime = 0.2,

    -- Reactor configuration
    ReactorTargetBufferMin = 33,       -- Minimum energy buffer % (0-100)
    ReactorTargetBufferMax = 90,      -- Maximum energy buffer % (0-100)
                                          -- NOTE: Do not exceed 90 for proper functionality

    -- Turbine configuration
    TargetRPM = 3600,                  -- Target turbine rotor speed (RPM)
    MaxRPM = 5000,                     -- Maximum safe turbine RPM
    TurbineTargetBufferMin = 30,       -- Minimum turbine energy buffer % (0-100)
    TurbineTargetBufferMax = 70,       -- Maximum turbine energy buffer % (0-100)
    MaxFlowRate = 13000,               -- Maximum fluid flow rate for turbines

    -- Safety limits
    SafetyShutoffTemperature = 1000,   -- Emergency shutdown temperature (if supported by mod)
    MaxEmergencyShutdownTime = 3600,   -- Maximum time in seconds before emergency shutdown

    -- Debug and logging
    EnableLogging = false,             -- Enable debug logging (may impact performance)
    LogFile = "reactors_controller.log",-- Log file path
    DebugMode = false,                 -- Enable debug mode (extra prints)

    -- GUI configuration
    RefreshRate = 0.5,                 -- GUI refresh rate (seconds)
    ShowAdvancedStats = false,         -- Show advanced statistics in GUI
    EnableParticleEffects = false,     -- Enable particle effects in GUI (performance)

    -- Performance tuning
    SkipInactiveReactors = true,       -- Skip inactive reactors in control calculations
    MaxReactorsPerTick = 20,           -- Maximum reactors to process per loop iteration
    MaxTurbinesPerTick = 20,           -- Maximum turbines to process per loop iteration

    -- Advanced features
    EnableTemperatureMonitoring = true, -- Monitor reactor temperature (if supported)
    TemperatureShutdownThreshold = 800, -- Temperature threshold for shutdown (if supported)
    EnableGradualStartup = true,       -- Enable gradual startup sequence
    StartupTime = 60,                  -- Time in seconds for gradual startup
}
