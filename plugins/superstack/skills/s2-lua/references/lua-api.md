<!--
  GENERATED FILE - DO NOT EDIT BY HAND.
  Generated from pages/superstack/lua.md in the siliconwitchery/docs repo by
  scripts/generate-references.py. To update, edit the docs and run:
      python3 scripts/generate-references.py --docs <docs-checkout> --write
-->

# Superstack Lua reference

---

Superstack devices such as the S2 Module run Lua. You upload your code with the [Superstack CLI](/pages/superstack/cli), and the device runs it. This reference lists every function your code can call to read sensors, drive IO, make web requests and receive messages from your application.

Each function runs C code in the firmware. Lua can't reach the parts of the firmware that check in with Superstack and install updates, so no code you upload can stop the device from receiving new code.

Complete, ready-to-run code is in the example repository. If you write code with an AI agent, the Superstack plugin for Claude Code and Codex teaches it this reference.

---

## Contents

- [Function summary](#function-summary)
- [Coding principles and notation](#coding-principles-and-notation)
- [Standard libraries](#standard-libraries)
- [Hardware libraries](#hardware-libraries)
  - [Digital IO](#digital-io)
  - [PWM output](#pwm-output)
  - [Analog input](#analog-input)
  - [I2C communication](#i2c-communication)
  - [SPI communication](#spi-communication)
  - [UART communication](#uart-communication)
- [Networking libraries](#networking-libraries)
  - [Networking (LTE)](#networking-lte)
  - [Location (GPS)](#location-gps)
- [System libraries](#system-libraries)
  - [Logging](#logging)
  - [Sleep](#sleep)
  - [Power](#power)
  - [Code files](#code-files)
  - [Temporary files](#temporary-files)
  - [Timekeeping](#timekeeping)
  - [Device information](#device-information)
  - [JSON](#json)

---

## Function summary

Every function and constant on this page, in page order. Each links to its full description.

| Function | What it does |
| --- | --- |
| [`device.digital.set_output()`](#set-or-clear-a-digital-output-on-a-pin) | Set or clear a digital output on a pin |
| [`device.digital.get_input()`](#get-the-digital-value-on-a-pin) | Get the digital value on a pin |
| [`device.digital.assign_input_event()`](#assign-an-event-handler-for-a-pin-input-change) | Assign an event handler for a pin input change |
| [`device.digital.unassign_input_event()`](#disable-an-input-event-handler-on-a-pin) | Disable an input event handler on a pin |
| [`device.pwm.set_output()`](#output-a-pwm-signal-on-a-pin) | Output a PWM signal on a pin |
| [`device.analog.get_input()`](#read-the-analog-value-on-a-pin) | Read the analog value on a pin |
| [`device.analog.get_differential_input()`](#read-the-differential-analog-value-across-two-pins) | Read the differential analog value across two pins |
| [`device.i2c.read()`](#read-bytes-from-an-i2c-device) | Read bytes from an I2C device |
| [`device.i2c.write()`](#write-bytes-to-an-i2c-device) | Write bytes to an I2C device |
| [`device.i2c.write_read()`](#write-then-read-bytes-from-an-i2c-device) | Write then read bytes from an I2C device |
| [`device.i2c.scan()`](#scan-for-i2c-devices) | Scan for I2C devices |
| [`device.spi.write_read()`](#write-then-read-bytes-from-an-spi-device) | Write then read bytes from an SPI device |
| [`device.spi.write()`](#write-bytes-to-an-spi-device) | Write bytes to an SPI device |
| [`device.spi.read()`](#read-bytes-from-an-spi-device) | Read bytes from an SPI device |
| [`device.spi.transact()`](#transact-bytes-with-an-spi-device-write-and-read-in-parallel) | Transact bytes with an SPI device (write and read in parallel) |
| [`device.uart.write()`](#write-uart-data) | Write UART data |
| [`device.uart.assign_read_event()`](#assign-an-event-handler-for-uart-data) | Assign an event handler for UART data |
| [`device.uart.unassign_read_event()`](#disable-the-uart-read-event-handler) | Disable the UART read event handler |
| [`network.get()`](#send-a-get-or-delete-request-to-a-web-service) | Send a GET or DELETE request to a web service |
| [`network.delete()`](#send-a-get-or-delete-request-to-a-web-service) | Send a GET or DELETE request to a web service |
| [`network.post()`](#send-a-post-put-or-patch-request-to-a-web-service) | Send a POST, PUT or PATCH request to a web service |
| [`network.put()`](#send-a-post-put-or-patch-request-to-a-web-service) | Send a POST, PUT or PATCH request to a web service |
| [`network.patch()`](#send-a-post-put-or-patch-request-to-a-web-service) | Send a POST, PUT or PATCH request to a web service |
| [`network.assign_message_event()`](#assign-an-event-handler-for-messages) | Assign an event handler for messages |
| [`network.unassign_message_event()`](#disable-the-message-event-handler) | Disable the message event handler |
| [`network.connected()`](#check-if-the-network-is-connected) | Check if the network is connected |
| [`network.low_power_mode()`](#set-low-power-mode) | Set low power mode |
| [`location.enable()`](#enable-gps) | Enable GPS |
| [`location.get_latest()`](#get-the-latest-gps-data) | Get the latest GPS data |
| [`location.disable()`](#disable-gps) | Disable GPS |
| [`print()`](#post-log-to-superstack) | Post log to Superstack |
| [`device.sleep()`](#sleep-for-a-duration) | Sleep for a duration |
| [`device.sleep_ms()`](#sleep-for-a-short-duration) | Sleep for a short duration |
| [`device.power.battery.set_charger_cv_cc()`](#configure-the-battery-charger) | Configure the battery charger |
| [`device.power.battery.get_voltage()`](#get-the-battery-voltage) | Get the battery voltage |
| [`device.power.battery.get_charging_status()`](#get-the-battery-charging-status) | Get the battery charging status |
| [`device.power.set_vout()`](#set-the-io-voltage-for-all-ports) | Set the IO voltage for all ports |
| [`require()`](#run-another-code-file) | Run another code file |
| [`storage.open()`](#open-a-temporary-file) | Open a temporary file |
| [`handle:write()`](#write-data-to-a-temporary-file) | Write data to a temporary file |
| [`handle:append()`](#append-data-to-a-temporary-file) | Append data to a temporary file |
| [`handle:read()`](#read-data-from-a-temporary-file) | Read data from a temporary file |
| [`handle:close()`](#close-a-temporary-file) | Close a temporary file |
| [`time.get_unix_time()`](#get-the-current-unix-timestamp) | Get the current Unix timestamp |
| [`time.get_time_date()`](#get-the-current-time-and-date) | Get the current time and date |
| [`device.HARDWARE_VERSION`](#hardware-version-constant) | Hardware version constant |
| [`device.FIRMWARE_VERSION`](#firmware-version-constant) | Firmware version constant |
| [`json.encode()`](#encode-a-value-as-json) | Encode a value as JSON |
| [`json.decode()`](#decode-json-text) | Decode JSON text |

---

## Coding principles and notation

The functions described in this reference typically represent single, atomic operations. For example `device.digital.set_output()` will output a high, or low voltage on a specified pin. Unlike most hardware level programming, a separate configuration step isn't needed. All configuration is optional and is passed directly into this function if desired.

The functions may accept a combination of **positional** and **named** arguments. Positional arguments always come first, with the named arguments provided at the end as a Lua table of key-value pairs.

Most of the named arguments will take on a default value if not provided. These are marked as _optional_.

A pin name is the port letter and the pin number on that port: `A0`, `A1`, `B0`, `B1`, `C0` to `C4`, `D0` to `D4`, `E0`, `E1`, `F0` and `F1`. The [S2 pinout](/pages/s2-module#pinout) shows where each one is. Any other name raises an error, such as `invalid pin`.

```lua
-- Calling a function with only positional arguments
device.digital.set_output("A0", true)

-- Calling a function with both positional and named arguments
device.i2c.write(0x12, "\x4F\x01", { sda_pin="B0", scl_pin="B1" })

-- Calling a function with only named arguments. Note how the () can be omitted
location.enable{ accuracy="LOW" }
```

Event handlers, such as those assigned with `device.digital.assign_input_event()`, run only while the code is running. Code that reaches the end of `main.lua` ends, and its handlers stop. To keep handling events, end `main.lua` with a loop:

```lua
while true do
    device.sleep(1)
end
```

An error that the code doesn't catch with `pcall` ends the code. The log shows `Code crashed:` followed by the error, and the code's run state becomes crashed. An error inside a handler or a request callback ends the code the same way. Handlers and callbacks can't call `coroutine.yield()`, and doing so raises an error. To run the code again, upload it or run `superstack device start <imei>`.

If the code makes the S2 restart, the S2 doesn't run it again after the restart. The log shows `Code crashed the device, so it was not started again`.

---

## Standard libraries

The device runs **Lua 5.5**. Most of the standard Lua libraries that you would find on the desktop installation of Lua are included:

- ✅ [Basic functions](https://www.lua.org/manual/5.5/manual.html#6.1)
- ✅ [Math functions](https://www.lua.org/manual/5.5/manual.html#6.7)
- ✅ [String manipulation](https://www.lua.org/manual/5.5/manual.html#6.4)
- ✅ [Table manipulation](https://www.lua.org/manual/5.5/manual.html#6.6)
- ✅ [UTF-8 support](https://www.lua.org/manual/5.5/manual.html#6.5)
- ✅ [Coroutine manipulation](https://www.lua.org/manual/5.5/manual.html#6.2)

The remaining standard libraries are not included, as they are superseded by similar functionality provided by the device specific libraries:

- ❎ File IO functions - Replaced by the [temporary files](#temporary-files) library
- ❎ Operating system functions - Replaced by the [timekeeping](#timekeeping) and [device information](#device-information) libraries
- ❎ Debug library
- ❎ Package library - `require` loads [code files](#code-files) without it

Three basic functions differ from desktop Lua:

- `require` loads another code file. See [code files](#code-files)
- `load` accepts only text, not precompiled bytecode
- `dofile` and `loadfile` are not available. Use `require` instead

---

## Hardware libraries

### Digital IO

#### Set or clear a digital output on a pin

```lua
device.digital.set_output(pin, value)
```

**Parameters**

- `pin` - **string** - The pin name. E.g. `"A0"`
- `value` - **boolean** - The level to set. `true` for high, `false` for low

**Returns**

- **nil**

**Note:** Setting an output on a pin removes any input event handler assigned to the pin.

**Example**

```lua
-- Set pin B1 to a high value
device.digital.set_output("B1", true)
```

---

#### Get the digital value on a pin

```lua
device.digital.get_input(pin, { pull="PULL_DOWN" })
```

**Parameters**

- `pin` - **string** - The pin name. E.g. `"A0"`

**Optional parameters**

- `pull` - **string** - The pull mode on the pin. Can be `"PULL_UP"`, `"PULL_DOWN"`, or `"NO_PULL"`

**Returns**

- **boolean** - `true` if the pin is high, `false` if low

**Note:** Reading a pin removes any input event handler assigned to the pin.

**Example**

```lua
-- Print the value on pin D0
local val = device.digital.get_input("D0")
print(val)
```

---

#### Assign an event handler for a pin input change

```lua
device.digital.assign_input_event(pin, handler, { pull="PULL_DOWN" })
```

**Parameters**

- `pin` - **string** - The pin name. E.g. `"A0"`
- `handler` - **function** - The function to call when the pin goes high or low. Called with two arguments:
    - `pin` - **string** - The pin name that generated the event. E.g. `"A0"`
    - `state` - **boolean** - The pin value when the event occurred. `true` if high, `false` if low

**Optional parameters**

- `pull` - **string** - The pull mode on the pin. Can be `"PULL_UP"`, `"PULL_DOWN"`, or `"NO_PULL"`

**Returns**

- **nil**

**Note:** If the pin changes several times before the handler runs, the handler runs once, with the latest state. Using the pin for anything else, such as PWM, an analog read or I2C, stops the handler firing.

**Example**

```lua
-- Assign a function that triggers when the input value of C3 changes
function my_pin_handler(pin, state)
    if state == true then
        print(pin.." went high")
    else
        print(pin.." went low")
    end
end

device.digital.assign_input_event("C3", my_pin_handler)
```

---

#### Disable an input event handler on a pin

```lua
device.digital.unassign_input_event(pin)
```

**Parameters**

- `pin` - **string** - The pin name. E.g. `"A0"`

**Returns**

- **nil**

**Example**

```lua
-- Disable the event and detach the pin from the handler
device.digital.unassign_input_event("C3")
```

---

### PWM output

#### Output a PWM signal on a pin

```lua
device.pwm.set_output(pin, duty_cycle, { frequency=1000 })
```

**Parameters**

- `pin` - **string** - The pin name. E.g. `"A0"`
- `duty_cycle` - **number** - The percentage of each period that the pin is high. From `0` to `100`

**Optional parameters**

- `frequency` - **number** - The PWM frequency in Hz. From `4` to `5000000`

**Returns**

- **nil**

**Note:** Up to four pins can output PWM at once. Starting PWM on a fifth pin stops it on the pin that started first. Any other function that uses the pin, such as `device.digital.set_output()`, also stops it.

**Example**

```lua
-- Dim an LED on pin A0 to 25% brightness
device.pwm.set_output("A0", 25, { frequency=2000 })
```

---

### Analog input

#### Read the analog value on a pin

```lua
device.analog.get_input(pin, { acquisition_time=10 })
```

**Parameters**

- `pin` - **string** - The pin name. Must be an analog capable pin: `"C2"` to `"C4"`, or `"D0"` to `"D4"`

**Optional parameters**

- `acquisition_time` - **integer** - The measurement time in microseconds. Can be `3`, `5`, `10`, `15`, `20`, or `40`. Higher values support greater source resistances (10kΩ, 40kΩ, 100kΩ, 200kΩ, 400kΩ, 800kΩ respectively)

**Returns**

- **number** - The voltage present on the pin in volts

**Example**

```lua
-- Read the analog voltage on pin D0
local voltage = device.analog.get_input("D0")
print(voltage)
```

---

#### Read the differential analog value across two pins

```lua
device.analog.get_differential_input(positive_pin, negative_pin, { acquisition_time=10 })
```

**Parameters**

- `positive_pin` - **string** - The pin name of the positive pin. Must be an analog capable pin. E.g. `"D0"`
- `negative_pin` - **string** - The pin name of the negative pin. Must be an analog capable pin, and different from `positive_pin`. E.g. `"D1"`

**Optional parameters**

- `acquisition_time` - **integer** - The measurement time in microseconds. Can be `3`, `5`, `10`, `15`, `20`, or `40`. Higher values support greater source resistances (10kΩ, 40kΩ, 100kΩ, 200kΩ, 400kΩ, 800kΩ respectively)

**Returns**

- **number** - The voltage across the pins in volts. Negative when `negative_pin` is at the higher voltage

**Example**

```lua
-- Read the differential analog voltage across pins D0 and D1
local voltage = device.analog.get_differential_input("D0", "D1")
print(voltage)
```

---

### I2C communication

**Optional parameters for every I2C function**

- `port` - **string** - The 4-pin port the I2C device is connected to. Can be `"PORTA"`, `"PORTB"`, `"PORTE"`, or `"PORTF"`. Defaults to `"PORTA"`. Assumes the [Stemma QT](https://learn.adafruit.com/introducing-adafruit-stemma-qt/what-is-stemma)/[Qwiic](https://www.sparkfun.com/qwiic) pinout, with SDA on pin 3 and SCL on pin 4. Cannot be used with `scl_pin` and `sda_pin`
- `scl_pin` - **string** - The pin name for the SCL signal, for any other pins or pin order. E.g. `"C3"`. Must be used with `sda_pin`
- `sda_pin` - **string** - The pin name for the SDA signal. E.g. `"C4"`. Must be used with `scl_pin`
- `frequency` - **integer** - The I2C frequency in kHz. Can be `100`, `250`, or `400`. Defaults to `100`

**Note:** A single I2C transaction may read or write at most **8191 bytes**. A transaction fails, and returns `success=false`, if the device does not acknowledge or does not finish within 2 seconds.

#### Read bytes from an I2C device

```lua
device.i2c.read(address, length, { port="PORTA", frequency=100 })
```

**Parameters**

- `address` - **integer** - The 7-bit address of the I2C device
- `length` - **integer** - The number of bytes to read

**Returns**

- **table** - A table of key-value pairs:
    - `success` - **boolean** - `true` if the transaction was successful, `false` otherwise
    - `data` - **string** - The bytes read. Always of size `length`. Absent if `success` is `false`
    - `value` - **integer** - The first byte read, useful if only one byte was requested. Absent if `success` is `false` or `length` is `0`

**Example**

```lua
-- Read multiple bytes from the device and print the fourth byte
local result = device.i2c.read(0x23, 4)

if result.success then
    print(string.byte(result.data, 4))
end
```

---

#### Write bytes to an I2C device

```lua
device.i2c.write(address, data, { port="PORTA", frequency=100 })
```

**Parameters**

- `address` - **integer** - The 7-bit address of the I2C device
- `data` - **string** - The data to write to the device. Can be a hexadecimal string containing zeros. E.g. `"\x1A\x50\x00\xF1"`

**Returns**

- **table** - A table of key-value pairs:
    - `success` - **boolean** - `true` if the transaction was successful, `false` otherwise

**Example**

```lua
-- Write 0x1234 to the register 0xF9
device.i2c.write(0x23, "\xF9\x12\x34")
```

---

#### Write then read bytes from an I2C device

```lua
device.i2c.write_read(address, write_data, read_length, { port="PORTA", frequency=100 })
```

**Parameters**

- `address` - **integer** - The 7-bit address of the I2C device
- `write_data` - **string** - The data to write to the device. Can be a hexadecimal string containing zeros. E.g. `"\x1A\x50\x00\xF1"`
- `read_length` - **integer** - The number of bytes to read

**Returns**

- **table** - A table of key-value pairs:
    - `success` - **boolean** - `true` if both the write and the read were successful, `false` otherwise
    - `data` - **string** - The bytes read. Always of size `read_length`. Absent if `success` is `false`
    - `value` - **integer** - The first byte read, useful if only one byte was requested. Absent if `success` is `false` or `read_length` is `0`

**Example**

```lua
-- Read a byte from register 0x1F on a device with address 0x23
local result = device.i2c.write_read(0x23, "\x1F", 1)

if result.success then
    print(result.value)
end
```

---

#### Scan for I2C devices

```lua
device.i2c.scan({ port="PORTA", frequency=100 })
```

**Returns**

- **nil** - The scan logs `Scanning for I2C devices`, then `Device found: 0x23` for each device it finds, then `I2C scan complete`

**Example**

```lua
-- Log the address of every device on PORTF
device.i2c.scan({ port="PORTF" })
```

---

### SPI communication

**Optional parameters for every SPI function**

- `sclk_pin` - **string** - The pin name for the SCK signal. Defaults to `"C0"`
- `mosi_pin` - **string** - The pin name for the MOSI signal. Defaults to `"C1"`
- `miso_pin` - **string** - The pin name for the MISO signal. Defaults to `"C2"`
- `cs_pin` - **string** - The pin name for the CS signal. Defaults to `"C3"`
- `mode` - **integer** - The SPI mode. Can be `0`, `1`, `2`, or `3`. Defaults to `0`
- `frequency` - **integer** - The SPI frequency in kHz. Can be `125`, `250`, `500`, `1000`, `2000`, `4000`, or `8000`. Defaults to `4000`
- `bit_order` - **string** - The bit order for transactions. Can be `"MSB_FIRST"` or `"LSB_FIRST"`. Defaults to `"MSB_FIRST"`
- `hold_cs` - **boolean** - If `true`, the CS pin remains held after the transaction completes. Useful for multi-step transactions. Defaults to `false`
- `cs_active_high` - **boolean** - If `true`, the CS pin is set high during the transaction and low once completed. Defaults to `false`
- `miso_pull` - **string** - The pull mode on the MISO pin. Can be `"PULL_UP"`, `"PULL_DOWN"`, or `"NO_PULL"`. Defaults to `"NO_PULL"`

**Note:** The pin options `sclk_pin`, `mosi_pin`, `miso_pin` and `cs_pin` must all be specified together. Providing only some of them raises an error. A single transfer may read or write at most **8191 bytes**.

#### Write then read bytes from an SPI device

```lua
device.spi.write_read(write_data, read_length, { mode=0, frequency=4000 })
```

**Parameters**

- `write_data` - **string** - The data to write to the device
- `read_length` - **integer** - The number of bytes to read from the device after the write. CS stays active between the two

**Returns**

- **string** - The bytes read. Always of size `read_length`

**Example**

```lua
-- Read data from an SPI flash device
local data = device.spi.write_read("\x03\x00\x00\x00", 11)
print(data)
```

---

#### Write bytes to an SPI device

```lua
device.spi.write(data, { mode=0, frequency=4000 })
```

**Parameters**

- `data` - **string** - The data to write to the device

**Returns**

- **nil**

**Example**

```lua
-- Wake up the flash with the 0xAB command
device.spi.write("\xAB")
```

---

#### Read bytes from an SPI device

```lua
device.spi.read(length, { mode=0, frequency=4000 })
```

**Parameters**

- `length` - **integer** - The number of bytes to read from the device

**Returns**

- **string** - The bytes read. Always of size `length`

**Example**

```lua
-- Read 4 bytes from an SPI device
local data = device.spi.read(4)
print(data)
```

---

#### Transact bytes with an SPI device (write and read in parallel)

```lua
device.spi.transact(write_data, read_length, { mode=0, frequency=4000 })
```

**Parameters**

- `write_data` - **string** - The data to write to the device
- `read_length` - **integer** - The number of bytes to read from the device while writing

**Returns**

- **string** - The bytes read. Always of size `read_length`

**Example**

```lua
-- Write and read data simultaneously
local data = device.spi.transact("\x9F", 3)
print(data)
```

---

### UART communication

#### Write UART data

```lua
device.uart.write(data, { tx_pin="A1", baudrate=9600, parity=false, stop_bits=1 })
```

**Parameters**

- `data` - **string** - The data to send

**Optional parameters**

- `tx_pin` - **string** - The pin name for the transmit signal. E.g. `"C1"`
- `baudrate` - **integer** - The baudrate in bits-per-second. Can be `1200`, `2400`, `4800`, `9600`, `14400`, `19200`, `28800`, `31250`, `38400`, `56000`, `57600`, `76800`, `115200`, `230400`, `250000`, `460800`, `921600`, or `1000000`
- `parity` - **boolean** - If `true`, enables the parity bit
- `stop_bits` - **integer** - The number of stop bits. Can be `1` or `2`

**Returns**

- **nil** - Returns once all the data is sent

**Example**

```lua
-- Send UART data
device.uart.write("Hello there. This is some data\n", { baudrate=19200 })
```

---

#### Assign an event handler for UART data

```lua
device.uart.assign_read_event(terminator, handler, { rx_pin="A0", baudrate=9600, parity=false, stop_bits=1 })
```

**Parameters**

- `terminator` - **string** - The character to wait for before calling `handler`. E.g. `"\n"`. A string that isn't exactly one character raises an error. If `nil`, `handler` is called with whatever data has arrived
- `handler` - **function** - The function to call when data is received. Called with one argument:
    - `data` - **string** - The bytes received since the last call, including the terminator

**Optional parameters**

- `rx_pin` - **string** - The pin name for the receive signal. E.g. `"C0"`
- `baudrate` - **integer** - The baudrate in bits-per-second. Takes the same values as `device.uart.write()`
- `parity` - **boolean** - If `true`, enables the parity bit
- `stop_bits` - **integer** - The number of stop bits. Can be `1` or `2`

**Returns**

- **nil**

**Note:** Only one UART read event can be assigned at a time. Assigning another replaces it. If 512 bytes arrive without a terminator, `handler` is called with them anyway. If more than 2048 bytes arrive before the code handles them, they are dropped.

**Example**

```lua
-- Log each line received
device.uart.assign_read_event("\n", function(line)
    print("Got a new line: " .. line)
end, { baudrate=19200 })
```

---

#### Disable the UART read event handler

```lua
device.uart.unassign_read_event()
```

**Returns**

- **nil**

**Example**

```lua
-- Stop receiving UART data
device.uart.unassign_read_event()
```

---

## Networking libraries

### Networking (LTE)

#### Send a GET or DELETE request to a web service

```lua
network.get(url, { headers=nil, callback=nil })
network.delete(url, { headers=nil, callback=nil })
```

**Parameters**

- `url` - **string** - The full address, starting with `https://` or `http://`, including any query string. E.g. `"https://example.com/api?city=Oslo"`. It must name a host, and any port must be a number. It can't contain control characters or invalid UTF-8, and outside the query a `%` must start an escape such as `%20`

**Optional parameters**

- `headers` - **table** - The request headers, as names mapped to values. E.g. `{ ["Authorization"]="Bearer abc" }`. A name can contain only letters, digits and ``!#$%&'*+-.^_`|~``. A value can't contain control characters other than tab, or invalid UTF-8
- `callback` - **function** - If given, the call returns at once and this function is called when the request finishes. Called with the same `response` and `error` that the call would otherwise return

**Returns**

- `response` - **table** - A table of key-value pairs, or `nil` if `error` is set:
    - `status` - **integer** - The HTTP status code. E.g. `200`
    - `content` - **string** - The response body
- `error` - **string** - `nil`, or the reason no response arrived:
    - `"no network"` - The request did not reach Superstack, or Superstack did not accept it
    - `"timeout"` - The web service did not answer in time, or its answer did not reach the device
    - `"connection failed"` - Superstack could not connect to the web service
    - `"too large"` - The response body was too long
    - `"no credit"` - The fleet has no [credit](/pages/superstack/credit), so the device did not send the request

With `callback`, the call returns only `error`, which is `nil`

**Note:** Superstack makes the request on the device's behalf. [Receive requests from a device](/pages/superstack/api#receive-requests-from-a-device) lists the limits the web service must meet, how Superstack follows redirects, and which responses reach Lua. Only one request can wait at a time, with or without `callback`, and making another raises an error.

A `url` or `headers` that breaks a rule above raises an error that names the rule. The URL and headers fit in about 5000 bytes, and a longer request raises the error `url and headers are too long`.

**Example**

```lua
local response, err = network.get("https://example.com/api/weather?city=Oslo")

if response then
    print(response.status, response.content)
else
    print("Request failed: " .. err)
end
```

---

#### Send a POST, PUT or PATCH request to a web service

```lua
network.post(url, body, { headers=nil, callback=nil })
network.put(url, body, { headers=nil, callback=nil })
network.patch(url, body, { headers=nil, callback=nil })
```

**Parameters**

- `url` - **string** - The full address, with the same rules as [`network.get()`](#send-a-get-or-delete-request-to-a-web-service)
- `body` - **string** - The request body, sent unchanged. At most 4096 bytes

**Optional parameters**

- `headers` - **table** - The request headers, with the same rules as [`network.get()`](#send-a-get-or-delete-request-to-a-web-service)
- `callback` - **function** - Called with `response` and `error` when the request finishes

**Returns**

- `response` and `error` - The same as [`network.get()`](#send-a-get-or-delete-request-to-a-web-service)

**Note:** The URL and headers fit in about 980 bytes beside a 4096-byte body. A longer request raises the error `url and headers are too long`.

**Example**

```lua
-- Send a reading as JSON without waiting for the answer
network.post("https://example.com/api/readings", json.encode{ temperature=21.5 }, {
    headers={ ["Content-Type"]="application/json" },
    callback=function(response, err)
        print(err or response.status)
    end,
})
```

---

#### Assign an event handler for messages

```lua
network.assign_message_event(handler)
```

**Parameters**

- `handler` - **function** - The function to call when a message arrives from your application through Superstack. Called with one argument:
    - `content` - **string** - The message exactly as your application sent it

**Returns**

- **nil**

**Note:** A message that arrives while no handler is assigned, or while the code is stopped, is discarded. [How a message reaches a device](/pages/superstack/api#how-a-message-reaches-a-device) describes when messages arrive and how many the device holds.

**Example**

```lua
-- Switch an output from a JSON message such as {"led":true}
network.assign_message_event(function(content)
    device.digital.set_output("B1", json.decode(content).led)
end)
```

---

#### Disable the message event handler

```lua
network.unassign_message_event()
```

**Returns**

- **nil**

**Example**

```lua
-- Stop handling messages. Later messages are discarded
network.unassign_message_event()
```

---

#### Check if the network is connected

```lua
network.connected()
```

**Returns**

- **boolean** - `true` if the LTE network is connected, `false` otherwise

**Example**

```lua
if network.connected() then
    print("Network is up")
end
```

---

#### Set low power mode

```lua
network.low_power_mode(enabled)
```

**Parameters**

- `enabled` - **boolean** - `true` to enable PSM (Power Saving Mode), `false` to disable it

**Returns**

- **nil**

**Warning:** Enabling PSM introduces up to **15 minutes of latency** for code uploads, messages, and starting, stopping or restarting the code, because the S2 receives them only at its check-in every 15 minutes. To return to real-time updates, call `network.low_power_mode(false)` and wait up to 15 minutes for the modem to re-register.

PSM stays on after the code ends, crashes or is stopped, until code turns it off or the S2 restarts.

**Example**

```lua
-- Enable low power mode when the network is not needed
network.low_power_mode(true)
```

---

### Location (GPS)

#### Enable GPS

```lua
location.enable{ accuracy="HIGH", power_saving="OFF", tracking_interval=1 }
```

**Optional parameters**

The table itself is required. Pass `{}` to use every default

- `accuracy` - **string** - The accuracy of the fix. `"LOW"` requires three satellites, `"HIGH"` requires four satellites
- `power_saving` - **string** - The power saving level. Can be `"OFF"`, `"MEDIUM"`, or `"MAX"`. Higher power saving reduces accuracy and increases time to fix
- `tracking_interval` - **integer** - The period to poll for new location updates. `1` for continuous 1-second updates, or a value between `10` and `65535` seconds for slower updates to save power

**Returns**

- **nil**

**Warning:** `location.enable()` automatically activates PSM to allow the modem to share hardware with the GPS. This introduces up to **15 minutes of latency** for code uploads, messages, and starting, stopping or restarting the code. To return to real-time updates, call `location.disable()` followed by `network.low_power_mode(false)`, then wait up to 15 minutes.

GPS and PSM stay on after the code ends, crashes or is stopped, until code turns them off or the S2 restarts.

**Example**

```lua
-- Start GPS with default settings
location.enable{}

-- Start GPS with low accuracy to save power
location.enable{ accuracy="LOW", power_saving="MAX" }
```

---

#### Get the latest GPS data

```lua
location.get_latest()
```

**Returns**

- **table** - A table of key-value pairs:
    - `valid` - **boolean** - `true` if the latest fix is valid. If `false`, the location and speed values are from the last valid fix, or `0` before the first. The latest fix stays until the S2 restarts, even after `location.disable()` or after the code ends, so `valid` can be `true` for a fix from an earlier run
    - `latitude` - **number** - The latitude in degrees
    - `longitude` - **number** - The longitude in degrees
    - `altitude` - **number** - The altitude in meters
    - `accuracy` - **number** - The location accuracy in meters
    - `speed` - **number** - The horizontal speed in meters per second
    - `speed_accuracy` - **number** - The speed accuracy in meters per second
    - `satellites` - **table** - A table of key-value pairs:
        - `tracked` - **integer** - The number of satellites currently being tracked
        - `in_fix` - **integer** - The number of satellites currently being used for measurement
        - `unhealthy` - **integer** - The number of satellites that could not be used for measurement

**Example**

```lua
-- GPS must be enabled before getting a location fix
location.enable{}

-- Avoid network activity while waiting for a fix. It competes
-- for the modem hardware and delays acquisition
device.sleep(60)

local fix = location.get_latest()

if fix.valid then
    print(string.format("%.5f, %.5f", fix.latitude, fix.longitude))
else
    print("No fix yet. Tracking " .. fix.satellites.tracked .. " satellites")
end
```

---

#### Disable GPS

```lua
location.disable()
```

**Returns**

- **nil**

**Warning:** Disabling GPS alone does **not** restore real-time code updates. PSM remains active until `network.low_power_mode(false)` is called. After calling it, wait up to 15 minutes for the modem to re-register before code updates arrive in real time.

**Example**

```lua
-- Stop GPS and restore real-time connectivity
location.disable()
network.low_power_mode(false)
```

---

## System libraries

### Logging

#### Post log to Superstack

```lua
print(...)
```

**Parameters**

- `...` - **any** - One or more values to print. They are converted to strings and joined with tabs into one log

**Returns**

- **nil**

**Example**

```lua
-- Simple print
print("hello world")

-- Print several values in one log, separated by tabs
print("count", 4 + 3)

-- C printf style formatted prints
print(string.format("pi = %.4f", math.pi))
```

**Note:** `print` never waits for the network. Logs wait on the device in a 2048-byte buffer until they are sent, and a log that does not fit is dropped whole. A single `print` of more than 2045 bytes is always dropped. [When a fleet runs out of credit](/pages/superstack/credit#when-a-fleet-runs-out-of-credit), the device discards logs instead of sending them.

---

### Sleep

#### Sleep for a duration

```lua
device.sleep(time)
```

**Parameters**

- `time` - **number** - The duration to sleep in seconds. E.g. `1.5`

**Returns**

- **nil**

**Note:** Assigned event handlers continue to fire during sleep. See [assign an event handler](#assign-an-event-handler-for-a-pin-input-change).

**Example**

```lua
-- Sleep for 1.5 seconds
device.sleep(1.5)
```

---

#### Sleep for a short duration

```lua
device.sleep_ms(time)
```

**Parameters**

- `time` - **integer** - The duration to sleep in milliseconds. From `0` to `1000`

**Returns**

- **nil**

**Note:** Event handlers do not fire during `device.sleep_ms()`, and stopping the code waits for it to return. Use `device.sleep()` for anything longer.

**Example**

```lua
-- Pulse pin B1 high for 5 milliseconds
device.digital.set_output("B1", true)
device.sleep_ms(5)
device.digital.set_output("B1", false)
```

---

### Power

#### Configure the battery charger

```lua
device.power.battery.set_charger_cv_cc(voltage, current)
```

**Parameters**

- `voltage` - **number** - The termination voltage. Can be `3.50`, `3.55`, `3.60`, `3.65`, `4.00`, `4.05`, `4.10`, `4.15`, `4.20`, `4.25`, `4.30`, `4.35`, `4.40`, or `4.45`
- `current` - **integer** - The constant charge current in mA. Must be between `32` and `800` in steps of `2`

**Returns**

- **nil**

**Note:** This setting reverts to the firmware default (**3.50V** termination, **32mA** charge current) at reboot. Configure the charger near the top of your code so that it is reapplied whenever the code restarts.

**Example**

```lua
-- Configure the battery charger for a 4.2V 200mAh rated Li-Po cell
device.power.battery.set_charger_cv_cc(4.2, 200)
```

---

#### Get the battery voltage

```lua
device.power.battery.get_voltage()
```

**Returns**

- **number** - The voltage of the cell in volts

**Example**

```lua
local voltage = device.power.battery.get_voltage()
print("Battery voltage is "..tostring(voltage).."V")
```

---

#### Get the battery charging status

```lua
device.power.battery.get_charging_status()
```

**Returns**

- **string** - The charging status: `"charging"`, `"charged"`, or `"discharging"` if a battery is connected, or `"external_power"` if no battery is installed or the battery has a fault

**Example**

```lua
local status = device.power.battery.get_charging_status()

if status ~= "external_power" then
    print("Battery is "..status)
else
    print("Battery not connected. On external power")
end
```

---

#### Set the IO voltage for all ports

```lua
device.power.set_vout(voltage)
```

**Parameters**

- `voltage` - **number** - The IO voltage of `PORTA` - `PORTF`. Can be between `1.8` and `3.3` in steps of `0.1`, or `0` to switch the power pins of every port off. Any other value raises `voltage must be between 1.8 and 3.3 in steps of 0.1`

**Returns**

- **nil**

**Note:** At boot, the port rails default to **1.8V**. If a connected sensor requires a higher IO voltage, call this function before communicating with it. The voltage applies to every port at once. It stays set after the code ends, until the code changes it or the S2 restarts.

**Example**

```lua
-- Set the voltage of Vout to 3.3V
device.power.set_vout(3.3)
```

---

### Code files

#### Run another code file

```lua
require(name)
```

**Parameters**

- `name` - **string** - The path of a code file in the bundle, without `.lua`. E.g. `"sensors"` for `sensors.lua`, or `"lib/sensors"` for `lib/sensors.lua`

**Returns**

- **any** - The value the file returns, or `true` if it returns nothing

**Note:** A file runs once. Later calls with the same name return the value from the first call without running the file again. Files can require other files up to 8 levels deep. A deeper `require` raises `require is nested too deeply`, and a missing file raises `module not found`.

Unlike desktop Lua, a `.` in the name is not a folder separator, so `require("lib.sensors")` looks for `lib.sensors.lua`. To put `sensors.lua` in a `lib` folder on the device, upload the folder that holds `lib`. See [what an upload sends](/pages/superstack/cli#what-an-upload-sends).

**Example**

```lua
-- sensors.lua returns a table of functions
local sensors = require("sensors")
print(sensors.read_temperature())
```

---

### Temporary files

**Note:** A temporary file is created by `storage.open()` and reached only through the handle it returns. Closing the handle deletes the file, and every temporary file is deleted when the code starts, ends, crashes, stops or restarts. Temporary files share storage with the code files in the bundle. The storage is **96KB**, and the file system uses part of it.

#### Open a temporary file

```lua
storage.open()
```

**Returns**

- **handle** - A new, empty temporary file. Call `write`, `append`, `read` and `close` on it using the `:` syntax

**Example**

```lua
-- Buffer readings in a temporary file while the network is down
local readings = storage.open()

while not network.connected() do
    readings:append(device.power.battery.get_voltage() .. "\n")
    device.sleep(60)
end

-- Send the buffered readings once the network returns
network.post("https://example.com/api/readings", readings:read{ length=4096 })
readings:close()
```

**Note:** If storage is full, `storage.open()` raises `there is not enough storage`. Every method raises an error once the handle is closed. A handle dropped without closing is closed when the garbage collector reclaims it, so close a file as soon as it is no longer needed to free its space.

---

#### Write data to a temporary file

```lua
handle:write(data)
```

**Parameters**

- `data` - **string** - The data to write. Replaces the whole content of the file

**Returns**

- **nil**

**Example**

```lua
-- Write data to the file, then replace it
local file = storage.open()
file:write("Hello world")
file:write("Goodbye world")

-- Prints "Goodbye world"
print(file:read())
```

**Note:** If the data does not fit in the remaining space, the write raises an error and leaves the file unchanged.

---

#### Append data to a temporary file

```lua
handle:append(data)
```

**Parameters**

- `data` - **string** - The data to append to the end of the file

**Returns**

- **nil**

**Example**

```lua
-- Append more data to the file
file:append("\nThis is another line of text")
file:append("\nAnd this is a final line of text")
```

**Note:** If the data does not fit in the remaining space, the append raises an error and leaves the file unchanged.

---

#### Read data from a temporary file

```lua
handle:read{ line=nil, length=nil, offset=0 }
```

**Optional parameters**

- `line` - **integer** - The line index to return. `1` is the first line, `2` the second, etc. Negative values index from the end: `-1` is the last line, `-2` the second to last, etc. Cannot be `0`, and cannot be combined with `length` or `offset`
- `length` - **integer** - The number of bytes to read. Cannot be used with `line`. If longer than the file, a shorter result is returned
- `offset` - **integer** - The number of bytes to skip before reading. `0` reads from the start. Requires `length`

**Returns**

- **string** - The contents read, or the whole file when neither `line` nor `length` is given. A line is returned without its newline. `nil` if the line does not exist

**Example**

```lua
-- Read the whole file
print(file:read())

-- Print the last line from the file
print(file:read{ line=-1 })

-- Skip the first 8 bytes, then read 16
print(file:read{ length=16, offset=8 })
```

**Note:** Reading more than the free memory holds raises a `not enough memory` error. Read a large file in parts with `length` and `offset`.

---

#### Close a temporary file

```lua
handle:close()
```

**Returns**

- **nil**

**Example**

```lua
-- Close the file. This deletes it and frees its space
file:close()
```

**Note:** Any use of the handle after closing raises an error. Use `pcall` if the code cannot guarantee the handle is still open.

---

### Timekeeping

#### Get the current Unix timestamp

```lua
time.get_unix_time()
```

**Returns**

- **integer** - The current Unix timestamp (i.e the number of non-leap milliseconds that have elapsed since 00:00:00 UTC on 1 January 1970), or if the time is not yet known, returns the uptime of the device in milliseconds

**Example**

```lua
-- Repeat something for 30 seconds
local t = time.get_unix_time()

while t + 30000 > time.get_unix_time() do
    print("waiting")
    device.sleep(5)
end
```

Note: the returned value is in **milliseconds**, so 30 seconds is `30000`

---

#### Get the current time and date

```lua
time.get_time_date({ unix_epoch=nil, timezone="+00:00" })
```

**Optional parameters**

- `unix_epoch` - **integer** - A Unix timestamp in milliseconds to convert, as returned by `time.get_unix_time()`. If `nil`, the current time is used, and an error is raised if the time is not yet known
- `timezone` - **string** - The timezone offset as `"+HH:MM"` or `"-HH:MM"`, from `"-12:59"` to `"+14:59"`. E.g. `"+02:00"` or `"-07:30"`. Defaults to `"+00:00"`

**Returns**

- **table** - A table of key-value pairs:
    - `year` - **integer** - The current year
    - `month` - **integer** - The current month
    - `day` - **integer** - The current day
    - `yearday` - **integer** - The day of the year. `1` on 1 January
    - `weekday` - **integer** - The days since Sunday. `0` on Sunday
    - `hour` - **integer** - The current hour
    - `minute` - **integer** - The current minute
    - `second` - **integer** - The current second

**Example**

```lua
-- Print the current time and date
local now = time.get_time_date()

print(string.format("The current time is: %02d:%02d", now.hour, now.minute))
print(string.format("The current date is: %d/%d/%d", now.year, now.month, now.day))
```

---

### Device information

#### Hardware version constant

```lua
device.HARDWARE_VERSION
```

**Returns**

- **string** - Always `"s2-module"`

**Example**

```lua
print(device.HARDWARE_VERSION)
```

---

#### Firmware version constant

```lua
device.FIRMWARE_VERSION
```

**Returns**

- **string** - A string representing the current firmware version. E.g. `"3.0.0"`

**Example**

```lua
print(device.FIRMWARE_VERSION)
```

---

### JSON

#### Encode a value as JSON

```lua
json.encode(value)
```

**Parameters**

- `value` - **any** - A table, string, number, boolean, `nil` or `json.null`. `nil` and `json.null` become `null`. A table whose keys are all whole numbers from 1 up becomes an array, with `null` for each missing key. E.g. `{[1]=1, [3]=3}` becomes `[1,null,3]`. Any other table becomes an object. An empty table becomes `{}`

**Returns**

- **string** - The JSON text

**Note:** Tables can nest up to 16 levels deep. A value that JSON cannot hold, such as a function, raises an error.

An array table whose highest key is above 10 and more than twice its number of keys, such as `{[20]=1}`, raises the error `Cannot serialise table: excessively sparse array`.

An integer is written exactly. Any other number is written to 14 significant digits. A `/` in a string is written as `\/`, so `"https://example.com"` becomes `"https:\/\/example.com"`, which any JSON parser reads back as the same string.

**Example**

```lua
-- Prints {"temperature":21.5,"readings":[1,2,3]}, with the keys in any order
print(json.encode{ temperature=21.5, readings={1, 2, 3} })
```

---

#### Decode JSON text

```lua
json.decode(text)
```

**Parameters**

- `text` - **string** - The JSON text

**Returns**

- **any** - The decoded value. Objects and arrays become tables, and `null` becomes `json.null`

**Note:** Text that is not valid JSON, or that nests more than 16 levels deep, raises an error. Use `pcall` to handle text that might be invalid.

**Example**

```lua
local ok, message = pcall(json.decode, '{"led":true,"level":null}')

if ok and message.level == json.null then
    print("No level given")
end
```
