<!--
  GENERATED FILE - DO NOT EDIT BY HAND.
  Generated from pages/superstack/cli.md in the siliconwitchery/docs repo by
  scripts/generate-references.py. To update, edit the docs and run:
      python3 scripts/generate-references.py --docs <docs-checkout> --write
-->

# Superstack CLI reference

---

`superstack` is the command line interface to Superstack. It logs you in, pairs S2 Modules with fleets, uploads Lua to them, streams their logs and manages credit. It is a single static binary.

---

## Commands

`superstack help` prints every command. `superstack help <command>` prints the help for one command.

```
superstack 0.0.4

Usage: superstack <command> [arguments]

Getting started
  login <github|gitlab>                               Log in with the selected provider
  logout                                              Log out of your account

Fleets
  fleet create <name>                                 Create a fleet
  fleet list [--json]                                 List the fleets you can reach
  fleet rename <fleet_id> <new_name>                  Rename a fleet
  fleet transfer <fleet_id> <email>                   Hand a fleet to a new owner
  fleet delete <fleet_id>                             Delete a fleet and unpair its devices

Devices
  device pair <imei> <fleet_id> [name]                Pair a device with a fleet
  device list [fleet_id] [--json]                     List devices and when they were last seen
  device rename <imei> <new_name>                     Rename a device
  device unpair <imei>                                Remove a device from its fleet
  device start <imei>                                 Start the code on a device
  device stop <imei>                                  Stop the code on a device
  device restart <imei>                               Restart the code on a device

Files
  upload <imei|fleet_id> <file> ...                   Upload files or directories to a device or fleet
  download <imei> <path>                              Download the code last uploaded to a device into <path>
  dev <imei|fleet_id> <file> ... [--log-file <file>]  Upload on every change, and tail

Logs
  tail <imei|fleet_id> [-n num] [--log-file <file>]   Stream a device or fleet's log as it arrives

People
  member add <email> <fleet_id>                       Add a member to a fleet
  member list <fleet_id> [--json]                     List a fleet's owner and members
  member remove <email> <fleet_id>                    Remove a member from a fleet

Keys
  key create <fleet_id> <label>                       Create a key for sending data to a fleet
  key list [fleet_id] [--json]                        List the keys that can reach your fleets
  key revoke <key_id>                                 Stop a key from reaching its fleet

Account
  account balance [fleet_id] [--json]                 Show the credit left on your fleets
  account topup <fleet_id>                            Add credit to a fleet
  account delete                                      Delete your account entirely

Superstack
  version                                             Show the version
  help [command]                                      Show this help, or help for one command
```
