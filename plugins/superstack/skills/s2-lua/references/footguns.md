# S2 Lua: traps, quirks and recovery recipes

Behaviour that commonly produces broken-looking code or a device that looks
bricked. Each item is checked against the firmware source or the S2 datasheet.

## Contents

- [Time is in milliseconds; sleep is in seconds](#time-is-in-milliseconds-sleep-is-in-seconds)
- [The PSM and GPS trap](#the-psm-and-gps-trap)
- [GPS acquisition vs network activity](#gps-acquisition-vs-network-activity)
- [User data spends credit](#user-data-spends-credit)
- [Network calls](#network-calls)
- [Messages from the user's project](#messages-from-the-users-project)
- [Error handling differs per bus](#error-handling-differs-per-bus)
- [Handlers cannot yield, and their errors crash the code](#handlers-cannot-yield-and-their-errors-crash-the-code)
- [Temporary files die with the run](#temporary-files-die-with-the-run)
- [Retry pattern for a dropped connection](#retry-pattern-for-a-dropped-connection)
- [Battery charger voltage list has a gap](#battery-charger-voltage-list-has-a-gap)
- [Ports boot at 1.8 V; VOUT applies to all ports at once](#ports-boot-at-18-v-vout-applies-to-all-ports-at-once)
- [Some settings outlive the run](#some-settings-outlive-the-run)
- [JTAG erase permanently destroys the module's identity](#jtag-erase-permanently-destroys-the-modules-identity)
- [LED states worth knowing when debugging](#led-states-worth-knowing-when-debugging)
- [Confirmed runtime behaviour](#confirmed-runtime-behaviour)

## Time is in milliseconds; sleep is in seconds

The two time units differ, and mixing them is the most common bug:

- `time.get_unix_time()` returns **milliseconds** since the Unix epoch. Before
  the first network time sync it returns **device uptime in milliseconds**.
- `time.get_time_date{ unix_epoch = ms }` also takes **milliseconds**, and
  raises `current time unknown` before the first sync when `unix_epoch` is
  left out.
- `device.sleep(t)` takes **seconds**, with fractions allowed, such as `1.5`.
- `device.sleep_ms(ms)` takes 0 to 1000 milliseconds, and event handlers wait
  until it returns.

```lua
-- WRONG: waits 30 milliseconds, not 30 seconds
local t = time.get_unix_time()
while t + 30 > time.get_unix_time() do ... end

-- RIGHT
local t = time.get_unix_time()
while t + 30000 > time.get_unix_time() do ... end
```

**Wait for valid time** before timestamping data. A device that hasn't synced
returns uptime, which is near zero, so a threshold works:

```lua
-- Unix ms for 2024-01-01; anything below this is uptime, not wall time
local TIME_VALID_THRESHOLD = 1704067200000

local function wait_for_valid_time()
    while time.get_unix_time() < TIME_VALID_THRESHOLD do
        device.sleep(1)
    end
end
```

## The PSM and GPS trap

Symptom: *"my device ignores code updates, or seems bricked, after I enabled
GPS."*

Cause:

1. `location.enable{}` **turns on PSM** (LTE Power Saving Mode), because GPS
   only runs while LTE sleeps. `network.low_power_mode(true)` turns it on
   explicitly.
2. Under PSM, the device picks up new code, start and stop requests, and
   messages only at its next check-in, up to **15 minutes** away, instead of
   within seconds.
3. `location.disable()` does **not** turn PSM off.
4. PSM stays on after new code replaces the old, until
   `network.low_power_mode(false)` or a reboot. Code that calls
   `location.enable` turns it on again at the next start.

Recovery, to get responsive updates back:

```lua
location.disable()
network.low_power_mode(false)
```

This recovery code is itself an upload, so it can take up to 15 minutes to
land on a device in PSM. The device is not bricked. It is sleeping. Never
suggest re-flashing firmware for this (see the JTAG section).

In generated code, avoid `location.enable` and `low_power_mode(true)` while
the user is iterating. Add them once the code is stable and in the field.

## GPS acquisition vs network activity

GPS and LTE share the radio. While waiting for a fix, avoid network calls,
because they delay acquisition. Enable GPS, sleep, then read
`location.get_latest()` and check `valid` before using the coordinates. When
the fix is lost, `valid` is `false` but the coordinates still hold the last
good fix. Time to first fix ranges from 1.3 s to 30.5 s with a clear view of
the sky.

`location.enable()` without a table raises. Pass `location.enable{}`.

## User data spends credit

Credit costs €1 per MB of user data, counted on the data itself. User data is:

- every log, which includes every `print()`
- every network call and its response
- every message from the user's project
- every upload, which sends only the files that changed, to every target
  device

Managing the device is free: check-ins, pairing, unpairing, starting,
stopping, restarting and firmware updates.

So in generated code:

- no `print()` in tight loops, and remove debug prints before a fleet upload
- batch readings into one network call instead of many small ones
- one 100-byte reading every 15 minutes is about 0.3 MB a month, or €0.30

A fleet with no credit sends no logs, and its network calls return
`nil, "no credit"` at once without raising. Lua keeps running.

## Network calls

`network.get/delete(url, options)` and `network.post/put/patch(url, body,
options)` make a REST request through Superstack to any public HTTPS or HTTP
address.

- Without `callback`, the call blocks and returns `response, error`. With
  `options.callback = function(response, error)`, it returns at once and the
  callback receives the result.
- `response` is `{ status = 200, content = "..." }`. A 404 or 500 is a
  response, not an error.
- `error` is one of `no network`, `timeout`, `connection failed`, `too large`
  or `no credit`. Always handle it.
- **One request can wait at a time.** A second call while one waits, with or
  without a callback, raises `too many network requests are waiting`.
- The body is at most 4096 bytes, otherwise the call raises. The URL and
  headers fit in about 980 bytes beside a 4096-byte body.
- A response longer than 4096 bytes returns `too large` instead of the
  content.
- The outside service has 8 seconds to answer.
- Private, loopback and link-local addresses are refused with
  `connection failed`, so the device cannot reach a server on the user's LAN.
- Encode tables with the built-in `json.encode` and set the header:

```lua
local response, err = network.post(
    "https://example.com/readings",
    json.encode{ temperature_c = 21.4 },
    { headers = { ["Content-Type"] = "application/json" } }
)
if err then
    print("send failed: " .. err)
elseif response.status >= 300 then
    print("server answered " .. response.status)
end
```

## Messages from the user's project

The user's own software can send a message to a device with a fleet key (see
the `superstack-cli` skill). Lua receives it through a handler:

```lua
network.assign_message_event(function(content)
    local message = json.decode(content)
    if message.interval_s then
        interval_s = message.interval_s
    end
end)
```

- `content` holds exactly the bytes the user sent, up to 4096.
- A message that arrives while no handler is assigned, or while Lua is
  stopped, is discarded.
- The device receives messages at its check-ins. Under PSM that can be 15
  minutes away, and a message expires after 1 hour unless the sender sets
  `expires_in`.

Use this for remote configuration instead of uploading new code.

## Error handling differs per bus

| API | Failure surface |
|---|---|
| `device.i2c.read/write/write_read` | returns a table with a `success` boolean. **Always check it** |
| `device.spi.*`, `device.uart.*`, `device.analog.*`, `device.digital.*` | no success flag. Bad arguments and failures raise |
| `device.i2c.scan` | returns nil. Each result line is a separate log |
| network calls | return `response, error`. Bad URLs, headers and oversized bodies raise |

Wrap fragile sections, such as sensor setup or a device that might be absent,
in `pcall`, so one failure doesn't crash the code:

```lua
local ok, err = pcall(function()
    local r = device.i2c.write_read(0x76, "\xD0", 1, { port = "PORTA" })
    if not r.success then
        print("sensor not responding")
    end
end)
if not ok then
    print("i2c error: " .. tostring(err))
end
```

`pcall` cannot catch a stop. `superstack device stop` always ends the code.

## Handlers cannot yield, and their errors crash the code

This applies to `device.digital.assign_input_event`,
`device.uart.assign_read_event`, network callbacks and
`network.assign_message_event`:

- A handler runs between instructions of the main code and during
  `device.sleep`, then the main code resumes.
- A handler that yields raises an error.
- An error inside a handler crashes the whole program. Wrap handler bodies in
  `pcall` when they parse input from outside, such as a message.
- Any other digital or analog use of a pin cancels its input event.

## Temporary files die with the run

`storage.open()` creates a temporary file and returns its handle. There are no
named files.

- `handle:write(data)` replaces the contents. `handle:append(data)` adds to
  them.
- `handle:read()` with no options returns **line 1 only**. Use
  `handle:read{ line = n }` for line `n` (negative counts from the end), or
  `handle:read{ length = n, offset = o }` for bytes.
- `handle:close()` deletes the file.
- **Every temporary file is deleted when the code starts, stops, restarts or
  crashes, when new code arrives, and at reboot.** Nothing survives the run
  that created it.
- Storage is shared with the code bundle. A write that does not fit raises
  `there is not enough storage`.

Code files in the bundle are read-only. Load one with `require("name")`, which
runs `name.lua` and returns its first value. `require` has no cache and runs
the file again on every call, and the name is a path: `require("lib/sensor")`
loads `lib/sensor.lua`.

## Retry pattern for a dropped connection

Network calls fail with `no network` while the device is out of coverage.
Keep unsent readings in a temporary file and send them when the connection
returns. The backlog lives only as long as the run.

```lua
local backlog = storage.open()
local backlog_lines = 0

local function send(reading)
    local line = json.encode(reading)
    local response, err = network.post(URL, line,
        { headers = { ["Content-Type"] = "application/json" } })
    if err then
        backlog:append(line .. "\n")
        backlog_lines = backlog_lines + 1
        return false
    end
    return true
end

local function drain()
    while backlog_lines > 0 do
        local line = backlog:read{ line = 1 }
        local response, err = network.post(URL, line,
            { headers = { ["Content-Type"] = "application/json" } })
        if err then
            return
        end
        local rest = backlog:read{ length = math.maxinteger, offset = #line + 1 }
        backlog:write(rest or "")
        backlog_lines = backlog_lines - 1
    end
end
```

## Battery charger voltage list has a gap

`device.power.battery.set_charger_cv_cc(voltage, current)` accepts **only**
these termination voltages:

```
3.50 3.55 3.60 3.65 4.00 4.05 4.10 4.15 4.20 4.25 4.30 4.35 4.40 4.45
```

There are no valid values between 3.65 and 4.00, so `3.7`, `3.8` and `3.85`
raise. Current is an integer from 32 to 800 mA in 2 mA steps. For a standard
single-cell LiPo use `set_charger_cv_cc(4.2, C)`, where `C` is the cell's
rated charge current, such as 200 for a 200 mAh cell at 1C.

The firmware programs 3.50 V and 32 mA at every boot, so set the charger in
setup.

## Ports boot at 1.8 V; VOUT applies to all ports at once

**At boot the port rails are live at 1.8 V.** A 3.3 V sensor on an
unconfigured port doesn't fail cleanly. It may half-work, with marginal I2C
signalling and garbage readings. Call `device.power.set_vout(3.3)` in setup
before talking to 3.3 V sensors.

`device.power.set_vout(voltage)` sets **all** ports, PORTA to PORTF, together:
1.8 to 3.3 V in 0.1 V steps, or `0` to switch port power off. You cannot run
PORTA at 1.8 V and PORTD at 3.3 V. Mixed-voltage sensors need level shifting,
or the 5 V VSYS rail with their own regulators.

## Some settings outlive the run

A restart of Lua, including new code arriving, does **not** reset:

- PSM, set by `location.enable` or `network.low_power_mode`
- the VOUT voltage
- the charger settings
- the level of a pin driven with `set_output`, until the new code uses the pin

A reboot resets them all. Set each one explicitly in setup rather than relying
on its current value.

## JTAG erase permanently destroys the module's identity

The S2 can be erased over Tag-Connect and J-Link and loaded with custom
firmware, but this **permanently erases the SoftSIM, the data plan and the
module's Superstack identity**. The module can never be used with Superstack
again.

Never suggest re-flashing, factory reset, or "erase and reprogram" as a
troubleshooting step. For a device that ignores uploads, see the PSM trap
above. For pairing problems, unpair it and pair it again with the CLI, which
needs access to its fleet.

## LED states worth knowing when debugging

| Observation | Meaning |
|---|---|
| Network LED strobing rapidly | Firmware update in progress. Leave it powered and wait it out |
| Network LED off, with brief flashes | Paired and connected. This is normal operation |
| Network LED slow blink | Searching for LTE. Check antenna clearance and coverage for the country |
| Network LED solid | Connected but not paired with a fleet |
| Power LED short blinks | On battery, no external power |

## Confirmed runtime behaviour

Checked against firmware 3.0.0:

| Behaviour | Fact |
|---|---|
| Lua version | **5.5**, with 64-bit integers. Libraries: base, coroutine, table, string, math, utf8, and a `json` table. **No `io`, `os`, `debug` or `package`**. `load` accepts text only |
| `json` | `json.encode(value)`, `json.decode(text)` and `json.null`. Both raise on bad input. Nesting is limited to 16 levels |
| `print` | Joins its arguments with tabs into **one** log. A log over about 2 KB, or one that arrives while the 2 KB send queue is full, is dropped whole without notice. Logs never block |
| Runtime error | The code stops. `superstack device list` shows `crashed`, and the log shows `Code crashed: main.lua:<line>: <message>`. It does not restart until new code, a start or restart, or a reboot |
| Crash at boot | If the code made the device reboot, for example by refusing to stop, it is not started again at the next boot. The log says so |
| Busy loop | Does not harm the device. Lua runs at the lowest priority, and an instruction hook delivers stops and events. The cost is power, so always sleep in the main loop |
| Event handlers during `device.sleep()` | Run within about 100 ms, then the sleep resumes. Shared state they touch can change across any `sleep()` |
| Lua heap | All the RAM the firmware doesn't use, about 160 KB. Still avoid large tables and long strings |
| Storage | Up to 96 KB of flash, shared by the code bundle and temporary files, in 4 KB blocks |
| I2C | 7-bit addresses (0 to 127). `write_read` is a write, a stop, then a read, never a repeated start. A transfer is at most 8191 bytes, and a stuck bus times out after 2 s with `success = false` |
| SPI | Pin options `sclk_pin`, `mosi_pin`, `miso_pin` and `cs_pin` are all or none. At most 8191 bytes per transfer |
| Digital input | `get_input` and `assign_input_event` pull **down** unless `pull` says otherwise. `set_output` needs a boolean, not `1` or `0` |
| PSM timing | Requested as a 900 s periodic update and 30 s active time, hence "up to 15 minutes". The network may grant different values |
| `get_time_date().yearday` | 0-based: January 1 is 0 |
| State across new code | Globals do not survive. Code starts from the top of `main.lua`, and temporary files are gone |
