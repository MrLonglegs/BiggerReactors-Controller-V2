# BiggerReactors-Controller-V2

A ComputerCraft / CC:Tweaked Lua controller for Bigger Reactors (Big Reactors mod) in Minecraft. Automatically manages reactor control rods and turbine flow rates to maintain stable power output while protecting your reactors from overfilling or draining.

## Features

- **Multi-reactor support** – Controls multiple reactors (passive and active) simultaneously
- **Multi-turbine support** – Manages multiple turbines for optimal RF generation
- **Dual mod compatibility** – Works with both `BigReactors` and `BiggerReactors` peripherals
- **Automatic rod level control** – Adjusts control rods to maintain target energy buffer levels
- **Flow rate regulation** – Adjusts turbine steam flow to target RPM
- **Real-time monitor GUI** – Basalt-based display showing energy levels, rod levels, and controller status
- **Headless mode** – Runs without a monitor if none is connected
- **Emergency shutdown** – Safely disengages all components on error or stop

## Requirements

- **Minecraft** 1.12.2+ (or your pack's supported version)
- **ComputerCraft** or **CC:Tweaked** mod
- **Big Reactors** or **Bigger Reactors** mod
- **Basalt** GUI library (required for monitor display)
- **Monitor** (optional, for GUI display)
- **Cables** (wired modems / cables to connect computer to reactors and turbines)

## Repository Layout

```
BiggerReactors-Controller-V2/
├── .gitignore
├── README.md
└── reactors_controller/
    ├── main.lua              # Entry point
    ├── core/
    │   ├── controller.lua    # Main control logic
    │   └── apihelper.lua     # Peripheral API abstraction layer
    └── gui/
        └── mainframe.lua     # Basalt-based monitor GUI
```

## Installation

1. Copy the `reactors_controller/` folder to your ComputerCraft computer's filesystem
   (e.g., via a disk drive, FTP, or directly in the world save).

2. Ensure the Basalt library is available on the computer if you want the monitor GUI.

3. Wire your reactors and turbines to the computer using wired modems or network cables.

4. Create a `config.lua` file (see [Configuration](#configuration)) or let the controller use defaults.

5. Run the program:
   ```lua
   reactors_controller/main.lua
   ```

## Configuration

All configurable parameters are in `reactors_controller/core/controller.lua` under `Controller.Parameters`:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `Looptime` | `0.2` | Seconds between control loop iterations |
| `ReactorTargetBufferMin` | `33` | Minimum energy buffer % before rods go fully out |
| `ReactorTargetBufferMax` | `90` | Maximum energy buffer % before rods go fully in |
| `TargetRPM` | `3600` | Target turbine rotor speed (RPM) |
| `MaxRPM` | `5000` | Maximum safe turbine RPM |
| `TurbineTargetBufferMin` | `30` | Minimum turbine energy buffer % |
| `TurbineTargetBufferMax` | `70` | Maximum turbine energy buffer % |
| `MaxFlowRate` | `13000` | Maximum fluid flow rate for turbines |

### Important Notes

- `ReactorTargetBufferMax` should not exceed 90 for proper functionality.
- `ReactorTargetBufferMin` should be below `ReactorTargetBufferMax`.
- Flow rate adjustments happen incrementally using `flowRateStep` (calculated automatically).

### Example Custom Configuration

Create `reactors_controller/config.lua`:

```lua
return {
    Looptime = 0.2,
    ReactorTargetBufferMin = 25,
    ReactorTargetBufferMax = 85,
    TargetRPM = 3600,
    MaxRPM = 5000,
    TurbineTargetBufferMin = 30,
    TurbineTargetBufferMax = 70,
    MaxFlowRate = 13000,
}
```

Then in `main.lua`, load it before initializing the controller:

```lua
local Config = require("reactors_controller.config")
-- Merge Config into Controller.Parameters
```

## How It Works

### Control Logic

1. **Setup** – Discovers all connected reactors and turbines via `peripheral.find`, initializes buffer thresholds based on each device's capacity, and sets all components active.

2. **Update Loop** (runs every `Looptime` seconds):
   - **UpdateStats** – Reads current energy stored, rod levels, RPM, and flow rate from all devices.
   - **AdjustFlowRate** – Increases or decreases turbine fluid flow to maintain `TargetRPM`. Engages/disengages turbine coils based on energy buffer levels.
   - **AdjustControlRods** – Calculates the optimal rod level for each reactor based on current buffer vs. target range, then sets control rods accordingly.

### Buffer Calculation

For each reactor:
- `minBuffer` = `ReactorTargetBufferMin`% of total capacity
- `maxBuffer` = `ReactorTargetBufferMax`% of total capacity
- Rod level interpolates between 0 (fully out) and 100 (fully in) based on where the current buffer falls within the target range.

### Turbine Logic

- If RPM < TargetRPM and flow rate < MaxFlowRate → increase flow rate
- If RPM > TargetRPM → decrease flow rate
- If stored energy < minBuffer → engage coil
- If stored energy > maxBuffer → disengage coil

## Peripheral Wiring Guide

### Reactors

Connect each reactor to the computer via wired modem or directly adjacent:

```
[Reactor] --(cable)-- [Computer] --(cable)-- [Turbine]
```

The controller auto-detects:
- `BigReactors-Reactor` / `BigReactors-Turbine` (Big Reactors mod)
- `BiggerReactors_Reactor` / `BiggerReactors_Turbine` (Bigger Reactors mod)

### Monitor (Optional)

Connect a monitor to the computer for the real-time GUI:

```
[Monitor] --(cable)-- [Computer]
```

The GUI shows:
- **Left panel** – Energy buffer progress bar and rod level progress bar
- **Right panel** – Controller status (On/Off toggle), statistics (generating energy)

## Troubleshooting

| Issue | Likely Cause | Fix |
|-------|-------------|-----|
| "peripheral not found" | Reactors/turbines not wired or wrong side | Check cable connections and peripheral names |
| GUI not showing | Basalt not installed or no monitor attached | Install Basalt, attach a monitor, or run headless |
| Rods not adjusting | Controller not running or IsRunning = false | Check controller status, click the toggle button |
| Turbine RPM fluctuating | Flow rate step too large or looptime too short | Adjust `MaxFlowRate` or `Looptime` parameters |
| Energy buffer oscillating | Min/max buffer too close together | Widen the gap between `ReactorTargetBufferMin` and `ReactorTargetBufferMax` |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Test thoroughly in a Creative test world
5. Submit a pull request

## License

This project is open source. Feel free to modify and distribute as needed for your modpack or personal use.