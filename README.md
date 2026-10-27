# Superstack agent plugins

Agent plugins for the [S2 Module](https://docs.siliconwitchery.com/pages/s2-module)
and [Superstack](https://docs.siliconwitchery.com/pages/superstack). They teach
Claude Code, Codex and other coding agents to write S2 Lua and to drive
Superstack through the `superstack` CLI.

## What's inside

One plugin, `superstack`, with two skills:

| Skill            | What it teaches the agent |
|------------------|---------------------------|
| `s2-lua`         | Writing Lua for the S2 Module: pins and ports, I2C, SPI, UART, analog, GPS, power, temporary files, network calls, messages from the user's project, and I2C sensor drivers from datasheets, including the traps the docs don't make obvious. |
| `superstack-cli` | Driving the `superstack` CLI: login, fleets, pairing, uploading code, device state, logs, members, fleet keys and credit, plus messaging a device from the user's own project. |

The `superstack-cli` skill needs the [Superstack CLI](https://github.com/siliconwitchery/superstack-cli#install)
on `PATH`.

## Install

### Claude Code

```
/plugin marketplace add siliconwitchery/superstack-agent-plugins
/plugin install superstack@siliconwitchery
```

### Codex

```sh
codex plugin marketplace add siliconwitchery/superstack-agent-plugins
codex plugin add superstack@siliconwitchery
```

Codex reads the same marketplace and plugin manifests as Claude Code. The CLI
needs network access and writes its login to your config directory, so approve
it when Codex asks to run `superstack` outside its sandbox.

### Any agent that supports Agent Skills

The skills follow the open [Agent Skills](https://agentskills.io) format. Copy
the skill folders into your agent's skills directory. For example, for Claude
Code without plugins:

```sh
git clone https://github.com/siliconwitchery/superstack-agent-plugins
cp -r superstack-agent-plugins/plugins/superstack/skills/* ~/.claude/skills/
```

### claude.ai

Download the skill zips from the latest
[release](https://github.com/siliconwitchery/superstack-agent-plugins/releases)
and upload them under **Settings → Capabilities → Skills**.

## Try it

With the plugin installed, ask your agent things like:

- *"Read temperature from a BMP280 on PORTA of my S2 every 10 minutes and post it to my server."*
- *"Upload this directory to my greenhouse fleet and tell me when every device is running it."*
- *"Let my Python app change the sample interval on device 350457790012345."*

## Repository layout

```
.claude-plugin/marketplace.json     Marketplace catalog, read by Claude Code and Codex
plugins/superstack/                 The plugin
  .claude-plugin/plugin.json
  skills/s2-lua/                    Lua skill
  skills/superstack-cli/            CLI skill
scripts/                            CI tooling (reference generation from the docs repo)
```

Reference files under `references/` marked `GENERATED` come from the
[siliconwitchery/docs](https://github.com/siliconwitchery/docs) repo through
`scripts/generate-references.py`. Edit the docs, not the generated files.
Everything else is maintained here.

## License

[Apache-2.0](LICENSE)
