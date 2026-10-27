# Complete example programs

Full S2 Module Lua programs. The ground rules: code starts from the top of `main.lua` on new code, a restart or a reboot; there is no `io`, `os` or `package`; temporary files and globals never survive into the next run; data leaves through a REST call to the user's own endpoint, and arrives as a message from the user's project.

## Official examples index (s2-lua-examples repo)

Repository: <https://github.com/siliconwitchery/s2-lua-examples>

Single-sensor drivers:

- [`adafruit_bmp280.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/adafruit_bmp280.lua) — Barometric pressure + temperature; reads the on-chip calibration block and runs the Bosch compensation algorithm.
- [`adafruit_ina237.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/adafruit_ina237.lua) — Voltage, current, and power monitoring on a shunt resistor.
- [`adafruit_mcp9808.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/adafruit_mcp9808.lua) — Precision temperature; demonstrates manufacturer-ID probing and sign-flag handling.
- [`adafruit_mlx90393.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/adafruit_mlx90393.lua) — 3-axis magnetic field strength.
- [`adafruit_vl53l0x.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/adafruit_vl53l0x.lua) — Laser time-of-flight distance measurement.
- [`sparkfun_as7343.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/sparkfun_as7343.lua) — 12-channel spectral light sensing.
- [`sparkfun_cap1203.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/sparkfun_cap1203.lua) — 3-pad capacitive touch input.
- [`sparkfun_vcnl4040.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/sparkfun_vcnl4040.lua) — Ambient light; demonstrates little-endian registers and split write/read transactions.

Complete applications:

- [`air-quality-monitor.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/air-quality-monitor.lua) — SHT45 + ENS160 with cross-sensor calibration and relay-driven fan control (the blog build; note it skips SHT4x CRC validation — see `sensor-drivers.md` for the CRC-checked version).
- [`embedded-world-badge.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/embedded-world-badge.lua) — Conference badge combining temperature, eCO₂, NFC, and a transparent display.
- [`weather-station.lua`](https://github.com/siliconwitchery/s2-lua-examples/blob/main/weather-station.lua) — SHT45 + BMP280 station computing dew point (Magnus formula), sea-level pressure, and a 3-hour pressure-tendency storm forecast with IIR filtering.

---

## Example A: Battery-powered environmental logger

An SHT45 logger that posts each reading to the user's own endpoint. It keeps readings in a temporary file while the device is out of coverage, sends them when the connection returns, and accepts a new sample interval as a message.

Credit notes:

- Every log, every network call and its response, and every message spend credit. This program prints only on errors and after a backlog drains.
- Draining sends one request per buffered sample so each keeps its own timestamp. Aggregate instead, such as min, mean and max per hour, if credit matters more than per-sample timing.
- The backlog lives only as long as the run. New code, a restart or a reboot deletes it.

```lua
-- Battery-powered SHT45 environmental logger.
-- Wiring: SHT45 on PORTA (Qwiic: SDA=A0, SCL=A1). Powered from a 4.2 V LiPo.

local SHT45_ADDRESS = 0x44
local URL = "https://example.com/readings"
local HEADERS = { headers = { ["Content-Type"] = "application/json" } }
local sample_interval_s = 60

-- 4.2 V 200 mAh LiPo. Termination voltage must be 3.50-3.65 or 4.00-4.45
device.power.battery.set_charger_cv_cc(4.2, 200)

-- Power the sensor rail and let it settle
device.power.set_vout(3.3)
device.sleep(0.1)

-- The user's project can send {"interval_s": 300} with a fleet key
network.assign_message_event(function(content)
    local ok, message = pcall(json.decode, content)

    if ok and type(message) == "table" and math.type(message.interval_s) == "integer"
        and message.interval_s >= 10 then
        sample_interval_s = message.interval_s
    end
end)

-- CRC-8, polynomial 0x31, init 0xFF (Sensirion)
local function crc8(data, first, last)
    local crc = 0xFF
    for i = first, last do
        crc = crc ~ string.byte(data, i)
        for _ = 1, 8 do
            if crc & 0x80 ~= 0 then
                crc = ((crc << 1) & 0xFF) ~ 0x31
            else
                crc = (crc << 1) & 0xFF
            end
        end
    end
    return crc
end

-- Returns temperature (C) and humidity (%), or nil on failure
local function sht45_measure()
    if not device.i2c.write(SHT45_ADDRESS, "\xFD", { port = "PORTA" }).success then
        return nil
    end
    device.sleep(0.01)

    local result = device.i2c.read(SHT45_ADDRESS, 6, { port = "PORTA" })
    if not result.success then
        return nil
    end

    local d = result.data
    if crc8(d, 1, 2) ~= string.byte(d, 3) or crc8(d, 4, 5) ~= string.byte(d, 6) then
        return nil
    end

    local raw_t = (string.byte(d, 1) << 8) | string.byte(d, 2)
    local raw_h = (string.byte(d, 4) << 8) | string.byte(d, 5)

    local temperature = -45 + 175 * (raw_t / 65535)
    local humidity = math.min(math.max(-6 + 125 * (raw_h / 65535), 0), 100)

    return temperature, humidity
end

-- Below year 2001 in ms means the clock hasn't synced and the value is uptime
local function time_is_synced(ts)
    return ts > 1000000000000
end

local backlog = storage.open()
local backlog_count = 0

-- Returns true once the server accepted the reading
local function post(line)
    local response, err = network.post(URL, line, HEADERS)
    return err == nil and response.status < 300
end

-- Sends buffered readings oldest first, and stops at the first failure
local function drain_backlog()
    local sent = 0

    while backlog_count > 0 do
        local line = backlog:read{ line = 1 }
        if not post(line) then
            break
        end

        backlog:write(backlog:read{ length = math.maxinteger, offset = #line + 1 })
        backlog_count = backlog_count - 1
        sent = sent + 1
    end

    if sent > 0 then
        print("Sent " .. sent .. " buffered readings")
    end
end

while true do
    local temperature, humidity = sht45_measure()

    if temperature then
        local now = time.get_unix_time() -- MILLISECONDS
        local line = json.encode{
            sampled_at_ms = now,
            clock_synced = time_is_synced(now),
            temperature_celsius = temperature,
            humidity_percent = humidity,
            battery_volts = device.power.battery.get_voltage(),
            battery_status = device.power.battery.get_charging_status(),
        }

        drain_backlog()

        if backlog_count > 0 or not post(line) then
            backlog:append(line .. "\n")
            backlog_count = backlog_count + 1
        end
    else
        print("SHT45 read failed (bus error or CRC mismatch)")
    end

    device.sleep(sample_interval_s) -- seconds
end
```

To stretch battery life further, call `network.low_power_mode(true)`. PSM then delays uploads, stops and messages until the next check-in, up to **15 minutes**. `network.low_power_mode(false)` restores responsive updates once it lands.

---

## Example B: GPS asset tracker

Reports position on a fixed interval. Two rules are built in:

1. **`location.enable{}` turns on PSM**, because GPS only runs while LTE sleeps. From then on, uploads, stops and messages wait up to **15 minutes**. Recovery needs `location.disable()` **and** `network.low_power_mode(false)`.
2. **Avoid network calls while acquiring a fix.** They compete with GPS for the radio and delay acquisition. The wait loop below is deliberately silent.

```lua
-- GPS asset tracker: acquire a fix, then report position periodically.
--
-- WARNING: location.enable{} turns on PSM (Power Saving Mode). From then on,
-- uploads and messages may take up to 15 MINUTES to arrive. To restore
-- responsive updates, upload code that runs:
--     location.disable()
--     network.low_power_mode(false)

local URL = "https://example.com/positions"
local HEADERS = { headers = { ["Content-Type"] = "application/json" } }
local REPORT_INTERVAL_S = 60
local FIX_TIMEOUT_S = 300

-- 4.2 V 400 mAh LiPo
device.power.battery.set_charger_cv_cc(4.2, 400)

-- Log before enabling GPS, so nothing uses the network during acquisition
print("Tracker starting. GPS on, uploads now take up to 15 min")

-- MEDIUM power saving and a 10 s tracking interval trade fix speed for
-- battery life. Use power_saving="OFF", tracking_interval=1 for fastest fixes
location.enable{ accuracy = "HIGH", power_saving = "MEDIUM", tracking_interval = 10 }

-- Count fixed sleeps rather than comparing Unix times: before the first time
-- sync get_unix_time() returns uptime, and the sync can land mid-wait
for _ = 1, FIX_TIMEOUT_S // 10 do
    if location.get_latest().valid then
        break
    end
    device.sleep(10)
end

if not location.get_latest().valid then
    print("No fix within timeout. Continuing to search")
end

while true do
    local l = location.get_latest()

    -- When the fix is lost, valid is false and the coordinates are stale
    if l.valid then
        local response, err = network.post(URL, json.encode{
            latitude = l.latitude,
            longitude = l.longitude,
            altitude_m = l.altitude,
            accuracy_m = l.accuracy,
            speed = l.speed,
            speed_accuracy = l.speed_accuracy,
            satellites_in_fix = l.satellites.in_fix,
            battery_volts = device.power.battery.get_voltage(),
        }, HEADERS)

        if err then
            print("send failed: " .. err)
        end
    end

    device.sleep(REPORT_INTERVAL_S)
end
```

Deployment tip: because PSM delays every upload, test tracker code on a bench unit with GPS *disabled* first, and enable `location` only in the final field build.
