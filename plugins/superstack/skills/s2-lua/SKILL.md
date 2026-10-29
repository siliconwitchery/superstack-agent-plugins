---
name: s2-lua
description: >-
  Writes and reviews Lua code for the Silicon Witchery S2 Module (nRF9151-based
  LTE-M and GNSS cellular module) running on Superstack. Covers digital and
  analog IO on PORTA-PORTF, I2C, SPI, UART, PWM, GPS, power and battery,
  temporary files, REST calls from the device, messages from the user's own
  project, sleep and timing, and writing I2C sensor drivers from datasheets.
  Use when the user mentions the S2 Module, Superstack device code or Lua,
  wiring sensors to an S2, or IoT code for Silicon Witchery hardware.
license: Apache-2.0
compatibility: >-
  No toolchain needed. Code reaches the device over cellular through the
  Superstack CLI (see the superstack-cli skill). This skill needs no network
  access itself.
metadata:
  vendor: siliconwitchery
  docs: https://docs.siliconwitchery.com/pages/superstack/lua
  examples: https://github.com/siliconwitchery/s2-lua-examples
---

# Writing Lua for the S2 Module

## What the S2 runtime is

The S2 Module runs the user's Lua inside signed firmware, managed by
Superstack. These facts shape all code:

- **Code is a bundle.** `main.lua` is the entry point. Other `.lua` files in
  the bundle load with `require("name")`, which runs `name.lua` and returns
  its first value. A file runs once, and later calls return the same value.
  Code files are read-only.
- Standard libraries: basic, `math`, `string`, `table`, `utf8`, `coroutine`,
  plus a built-in `json` with `json.encode` and `json.decode`. **There is no
  `io`, `os`, `debug` or `package`.** Use `storage.*`, `time.*` and `device.*`
  instead.
- New code **starts from the top of `main.lua`**. So does a restart and a
  reboot. Globals and temporary files never survive into the next run.
- There is no debugger. `print()` sends one log, which the user reads with
  `superstack tail`. The loop is: edit, upload, read the log. An upload
  usually lands within seconds, unless PSM is on (see the traps).
- Hardware calls take required positional arguments first, then one optional
  table of named options: `f(a, b, { opt = 1 })`, or `f{ opt = 1 }` when only
  options are passed.

## Canonical program shape

Every S2 program follows this shape (full version:
`assets/program-template.lua`):

```lua
-- 1. Config constants
local SEND_INTERVAL_S = 600

-- 2. One-time setup
device.power.set_vout(3.3)          -- ports boot at 1.8 V; raise before sensor use

-- 3. Optional event handlers
-- network.assign_message_event(function(content) ... end)

-- 4. Main loop, which always sleeps
while true do
    -- read sensors, send data
    device.sleep(SEND_INTERVAL_S)
end
```

Never write a busy loop without `device.sleep()`, because it wastes power. It
won't break the device: Lua runs at the lowest priority, so connectivity,
uploads and stops keep working through a stuck loop.

## Critical rules

These are the most common failures. Full explanations and recovery recipes are
in [references/footguns.md](references/footguns.md).

1. **Pins**: use only pin names from
   [references/pinout.md](references/pinout.md). 18 pins exist:
   `A0-A1, B0-B1, C0-C4, D0-D4, E0-E1, F0-F1`. Analog input works **only** on
   `C2-C4` and `D0-D4`. Do not invent pins.
2. **Units**: `time.get_unix_time()` returns **milliseconds**, and returns
   uptime until the first network time sync. Wait for valid time before
   timestamping. `device.sleep()` takes **seconds**.
3. **I2C `port` shortcut** works only for `PORTA/B/E/F`, in Qwiic order: pin 3
   is SDA, pin 4 is SCL. On PORTC and PORTD pass `scl_pin` and `sda_pin`.
   `port` and explicit pins cannot be combined.
4. **PSM trap**: `location.enable{}` turns on LTE Power Saving Mode, so
   uploads, stops and messages wait for the next check-in, up to **15
   minutes** away. Recovery needs `location.disable()` **and**
   `network.low_power_mode(false)`, then waiting. The device is not bricked.
   Never suggest re-flashing: a JTAG erase permanently destroys the SIM and
   the module's Superstack identity.
5. **Data out is a REST call**: `network.post(url, body, options)` and its
   siblings call the user's own HTTPS endpoint through Superstack. Each returns
   `response, error`. Always handle `error`, which is `no network`, `timeout`,
   `connection failed`, `too large` or `no credit`. Bodies and responses are at
   most 4096 bytes. **Only one request may wait at a time**; a second raises.
6. **Data in is a message**: the user's project sends a message with a fleet
   key, and `network.assign_message_event(function(content) ... end)` receives
   it. Use messages for remote configuration instead of uploading new code.
   A message arriving with no handler assigned is discarded.
7. **User data spends credit** at €1 per MB: every log, every network call and
   response, every message, and every upload (changed files × target devices).
   Batch readings, and strip debug prints before a fleet upload. A fleet with
   no credit sends no logs, and network calls return `no credit`.
8. **`print` joins its arguments with tabs into one log.** A log over about
   2 KB, or one that arrives while the send queue is full, is dropped without
   notice. Log lightly.
9. **Error models differ**: I2C calls return `{ success = boolean, ... }`, so
   always check it. SPI, UART, analog and digital calls raise on failure, so
   wrap risky sections in `pcall`. Handlers cannot yield, and an error inside
   one crashes the program.
10. **Temporary files die with the run**: `storage.open()` returns a handle to
    a new temporary file, deleted on close and whenever the code starts,
    stops, crashes or is replaced. Nothing on the device survives a restart,
    so keep durable state on the user's server.
11. **Power**: ports boot **live at 1.8 V**, so a 3.3 V sensor on an
    unconfigured port half-works rather than failing cleanly. Call
    `device.power.set_vout(3.3)` in setup. It sets **all** ports at once (1.8 to
    3.3 V), with 100 mA per rail (VOUT1: ports A/B/C, VOUT2: ports D/E/F).
    5 V sensors go on VSYS. Charger voltages have **no valid values between
    3.65 and 4.00 V**, and the charger resets to 3.50 V / 32 mA at every boot,
    so set it in setup.
12. **Some settings outlive the run**: PSM, VOUT, the charger and driven pin
    levels carry into new code until a reboot. Set each one explicitly in
    setup.

## Where to look things up

- Exact signatures, parameters and return shapes for every Lua API:
  [references/lua-api.md](references/lua-api.md)
- Pin names, analog capability, port and rail map, Qwiic order:
  [references/pinout.md](references/pinout.md)
- Writing a driver for a new I2C or SPI sensor from its datasheet:
  [references/sensor-drivers.md](references/sensor-drivers.md)
- Complete worked programs: sensor loop, GPS tracker, remote configuration:
  [references/examples.md](references/examples.md)
- Traps, recovery recipes and confirmed runtime facts. Check here when a
  symptom looks like a hardware fault:
  [references/footguns.md](references/footguns.md)

## Workflow for sensor-driver requests

When the user names a sensor part number, such as "read a BMP280 on PORTA":

1. Check [references/sensor-drivers.md](references/sensor-drivers.md) and the
   examples repo (github.com/siliconwitchery/s2-lua-examples) for an existing
   driver for that part or family.
2. If none exists, follow the raw-register method in sensor-drivers.md: find
   the I2C address and key registers in the datasheet, read registers with
   `device.i2c.write_read`, handle endianness and two's complement explicitly,
   and check `success` on every transfer.
3. State the sensor's supply voltage and confirm the wiring (which port, which
   VOUT setting) before the code.

## Validation checklist

Before delivering S2 Lua code, verify:

- [ ] Every pin name exists, and analog pins are analog-capable (pinout.md)
- [ ] Every API call matches a signature in lua-api.md or footguns.md, with no
      invented functions
- [ ] Units: sleep in seconds, Unix time in ms, voltages from the valid lists
- [ ] Every I2C result checks `.success`. Fragile sections and handlers that
      parse outside input are wrapped in `pcall`
- [ ] Every network call handles `error`, and no second call can start while
      one waits
- [ ] The main loop calls `device.sleep()`. No busy waiting
- [ ] `set_vout` is called in setup if a port-powered sensor is used
- [ ] The credit cost of the chosen send and log frequency is stated
- [ ] If GPS or PSM is used, the 15-minute delay for uploads and messages is
      called out
