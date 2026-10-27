-- S2 Module program template
-- Canonical shape: config constants, setup, handlers, main loop with sleep.
-- New code, a restart and a reboot all start from the top of main.lua.

-- 1. Config constants
local SEND_URL = "https://example.com/readings" -- the user's own endpoint
local SENSOR_PORT = "PORTA" -- Qwiic sensor on a 4-pin port (A/B/E/F only)
local send_interval_s = 600 -- seconds; a message can change it at run time

-- 2. One-time setup
device.power.set_vout(3.3) -- ports boot at 1.8 V; raise to 3.3 V before sensor use

-- time.get_unix_time() returns MILLISECONDS, and uptime until first sync
local TIME_VALID_THRESHOLD = 1704067200000 -- 2024-01-01 in Unix ms
while time.get_unix_time() < TIME_VALID_THRESHOLD do
    device.sleep(1)
end

-- 3. Optional event handlers
-- Messages come from the user's project through a fleet key
network.assign_message_event(function(content)
    local ok, message = pcall(json.decode, content)

    if ok and type(message) == "table" and math.type(message.interval_s) == "integer" then
        send_interval_s = message.interval_s
    end
end)

local function read_sensor()
    local result = device.i2c.write_read(0x76, "\xD0", 1, { port = SENSOR_PORT })

    if not result.success then
        print("sensor not responding")
        return nil
    end

    return result.value
end

-- 4. Main loop, which always sleeps
while true do
    local ok, err = pcall(function()
        local value = read_sensor()

        if value == nil then
            return
        end

        local response, send_error = network.post(SEND_URL, json.encode{
            sensor_raw_value = value,
            battery_voltage = device.power.battery.get_voltage(),
            sampled_at_ms = time.get_unix_time(),
        }, { headers = { ["Content-Type"] = "application/json" } })

        if send_error then
            print("send failed: " .. send_error)
        elseif response.status >= 300 then
            print("server answered " .. response.status)
        end
    end)

    if not ok then
        print("error: " .. tostring(err))
    end

    device.sleep(send_interval_s)
end
