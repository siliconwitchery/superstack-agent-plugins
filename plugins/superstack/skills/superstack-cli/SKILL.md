---
name: superstack-cli
description: >-
  Drives the Superstack CLI (`superstack`) to manage S2 Module devices: log in,
  create fleets, pair devices, upload Lua code, start, stop and restart it, read
  device logs, add members, create fleet keys and check or top up credit. Also
  covers sending messages to devices from the user's own project with a fleet
  key. Use when the user wants to put code on an S2, see what a device is
  doing, manage fleets, devices, members, keys or credit, or reach a device
  from their own software.
license: Apache-2.0
compatibility: >-
  Needs the `superstack` CLI on PATH and network access. The CLI stores its
  login in `~/.local/state/superstack/key` on Linux, or in the user's config
  directory on macOS and Windows, so a sandboxed agent may need the user to
  approve running it outside the sandbox.
metadata:
  vendor: siliconwitchery
  docs: https://docs.siliconwitchery.com/pages/superstack/cli
  cli: https://github.com/siliconwitchery/superstack-cli
---

# Driving Superstack with the CLI

## What Superstack is

Superstack carries code out to S2 Modules over cellular and carries data back.
The user writes Lua (see the `s2-lua` skill), and the `superstack` CLI is how
they manage everything else.

Use these words with the user, because the CLI and docs use them:

- **Device:** one S2 Module, named by the 15-digit IMEI printed on it.
- **Fleet:** a group that owns devices, members, fleet keys and credit. Its id
  is the number `fleet list` shows.
- **Owner** and **member:** the owner manages the fleet. Members can do
  everything to its devices.
- **Pair** and **unpair:** put a device into a fleet, or take it out.
- **Code:** the Lua and other files the user uploads. The set of files is the
  **bundle**, and it always contains `main.lua`.
- **Log:** `print()` output and the messages that code started, ended,
  stopped or crashed.
- **Credit:** a fleet's prepaid balance in euros.
- **Fleet key:** a key that lets the user's own software send messages to one
  fleet's devices.

## Before the first command

1. Check the CLI is installed with `superstack version`. If it is missing,
   send the user to the install steps at
   https://github.com/siliconwitchery/superstack-cli#install. Never install it
   with a method the user did not choose.
2. Run `superstack help` to list the commands, and
   `superstack help <command>` before using one for the first time. The
   installed version's help is authoritative over this skill.
3. List commands print text by default. Add `--json` to `fleet list`,
   `device list`, `member list`, `key list` and `account balance` when you need
   to read the result.

## Commands that need the user

The CLI is built for a person at a terminal. Several commands wait for that
person, so run them like this:

- **Login.** `superstack login github` or `superstack login gitlab` prints a
  one-time code and a web address, then waits until the user enters the code.
  Run it in the background, give the user the code and address, and wait for
  the command to exit. The user can enter the code from any browser.
- **Pairing.** `superstack device pair <imei> <fleet_id> [name]` waits about a
  minute for the user to press the pairing button on the device. Tell the user
  to be ready to press it, then run the command.
- **Top-up.** `superstack account topup <fleet_id> </dev/null` prints a
  payment page and exits. Give the user the address. The user chooses the
  amount and pays, never you.
- **Confirmations.** These commands ask `[y/N]` and do nothing unless they
  read `y`:
  - `device unpair`: the device wipes its code, restarts Lua, and waits to be
    paired again. Its logs are deleted.
  - `fleet delete`: unpairs every device in the fleet and forfeits its credit.
  - `fleet transfer`: the user loses access to the fleet, its devices and its
    credit.
  - `member remove`, `key revoke` and `account delete`.
  - `download` into a directory where the files already exist.

  Tell the user what the command will do, in the words above, and wait for a
  clear yes in the conversation. Only then answer the prompt:

  ```sh
  printf 'y\n' | superstack device unpair <imei>
  ```

  Never answer `y` on the user's behalf without that yes.

## Putting code on a device

1. Keep the bundle in one directory with `main.lua` at its top.
2. Upload it to one device or to every device in a fleet:

   ```sh
   superstack upload <imei|fleet_id> <directory>
   ```

   A directory uploads its contents, with paths relative to it, skipping
   dotfiles. A file argument lands at the top of the bundle under its own name.
3. The upload replaces the whole bundle. The server refuses it when:
   - `main.lua` is missing.
   - A path is `tmp` or starts with `tmp/`.
   - A path is longer than 255 bytes.
   - The bundle does not fit the device's storage.
   - The fleet has no credit.
4. The device receives the code at its next check-in. The server prompts one
   straight after the upload, so it usually arrives within seconds. A device
   in power-saving mode can take up to 15 minutes.
5. Check the result with `superstack device list <fleet_id>`. Its state
   column shows one of these:

   | State | Meaning |
   | --- | --- |
   | `updating firmware` | The device is installing new firmware |
   | `no space` | The bundle did not fit. Lua is stopped. Upload a smaller bundle |
   | `rejected` | The device cannot apply the bundle. Lua is stopped. Fix the cause and upload again |
   | `failed` | The device failed to apply the bundle three times. Lua is stopped. Upload again |
   | `no code` | No bundle is stored for the device |
   | `no credit` | A bundle is waiting and the fleet has no credit. Top up to send it |
   | `updating` | The device has not received the bundle yet |
   | `starting`, `stopping`, `restarting` | The device has not confirmed the request yet |
   | `running`, `stopped`, `crashed` | What the device last reported about its Lua |
   | `-` | The device has code but hasn't reported its state yet |

6. Read the log for `Code started`, or `Code crashed: <error>` with the Lua
   error and line.

A fleet upload reaches the devices paired with the fleet at that moment. A
device paired later needs its own upload.

`superstack dev <imei|fleet_id> <directory>` uploads on every change and
follows the log. Use it when the user is working interactively. It runs until
stopped.

`superstack download <imei> <directory>` fetches the bundle the server holds
for a device. Nothing is read back from the device itself.

`superstack device start`, `stop` and `restart` control the code on one
device. Stop is the remote kill switch. It always works, even without credit.

## Reading logs

- `superstack tail <fleet_id> [imei ...] -n <count>` prints the newest
  `<count>` logs, from 1 to 1000, and exits. Add `-o <skip>` to look further
  back. Prefer this when you need a snapshot.
- Without `-n`, `tail` prints the newest 100 logs and then follows the fleet
  until stopped. Run it in the background with its output sent to a file, read
  the file, and stop the command when you are done.
- Each line is `<time> <IMEI> <kind> [<device name>] <text>`, where kind is
  `print`, `state` or `error`.
- The server keeps logs for 14 days.

## Credit

- Credit belongs to a fleet. A new device gives €10 of starter credit to the
  first fleet it pairs with.
- User data costs €1 per MB, counted on the data itself. User data is code
  uploads, logs, messages to a device, network calls from Lua and their
  responses.
- Managing a device is free: check-ins, pairing, unpairing, starting,
  stopping, restarting and firmware updates.
- An upload sends only the files that changed, but it sends them to every
  target device. Estimate the cost before uploading to a large fleet.
- A fleet with no credit refuses uploads and messages, sends no logs, and its
  network calls from Lua return `no credit`. The code keeps running.
- `superstack account balance [fleet_id]` shows the credit left.

## Messaging a device from the user's own project

The user's software reaches a device with a fleet key over plain HTTPS.

1. Create a key. The CLI prints it once:

   ```sh
   superstack key create <fleet_id> <label>
   ```

2. Treat the key as a password. Tell the user to keep it in an environment
   variable or a secret manager. Never write it into code, a commit, a log or
   a file the user did not ask for.
3. Send a message:

   ```sh
   curl -X POST "https://supernext.siliconwitchery.com/fleets/<fleet_id>/messages?imei=<imei>" \
       -H "Authorization: Bearer $SUPERSTACK_FLEET_KEY" \
       --data-binary 'hello'
   ```

   - The body is the message, up to 4096 bytes. Lua receives exactly those
     bytes, so it can be JSON, text or binary.
   - Repeat `imei=` to name several devices. Leave it out to send to every
     device paired with the fleet now.
   - `expires_in` sets how long the message waits for the device, from 30
     seconds to 14 days. The default is 1 hour.
   - `202` means queued. The server does not wait for the device.
   - `402` means the fleet has no credit, `413` the message is too large, and
     `429` a device already has 100 messages waiting.
4. The device receives the message at its next check-in, through
   `network.assign_message_event` in its Lua (see the `s2-lua` skill).

Full reference: [references/api.md](references/api.md).

Don't invent commands, endpoints, webhooks or a WebSocket API. Use only what
`superstack help` and the references document.

## Checklist

- [ ] Every command and flag appears in `superstack help` for the installed
      version.
- [ ] Every confirmation was answered only after the user said yes.
- [ ] Login and top-up were completed by the user.
- [ ] No fleet key appears in code, commits or logs.
- [ ] The user knows the credit cost of a large fleet upload before it runs.
- [ ] After an upload, the device state and log were checked.
