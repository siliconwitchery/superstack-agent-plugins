# Before first release

## Waiting on other repositories

- [ ] `docs` `pages/superstack/lua.md`: replace `network.send_data` with the
      network calls and `network.assign_message_event`, and drop the data
      allowance, 1023-character log and 48 KB storage notes. Then regenerate
      `s2-lua/references/lua-api.md`.
- [ ] `docs` `pages/superstack/cli.md`: copy `superstack help` from the
      released CLI. The page still shows the 0.0.4 `tail` and `--log-file`.
- [ ] `docs` `pages/superstack/api.md`: replace the legacy deployments API
      with fleet-key messaging. Then generate
      `superstack-cli/references/api.md`, which `superstack-cli/SKILL.md`
      already links.
- [ ] Merge the `docs` changes to `main`. `sync-docs.yml` reads `main` and
      fails until `cli.md` is there.
- [ ] `s2-lua-examples`: replace `network.send_data` in every file, then
      recheck the index in `s2-lua/references/examples.md`.
- [ ] `s2-firmware`: `no credit` from network calls and dropping logs without
      credit are in `design.md` but not in the firmware yet. The skills
      already describe them.

## Here

- [ ] Run the "Try it" prompts from the README, with and without the plugin,
      on Claude Code and Codex.
- [ ] Test install: `claude --plugin-dir plugins/superstack`, then
      `/plugin marketplace add siliconwitchery/superstack-agent-plugins` from
      a clean repository.
- [ ] Test install on Codex:
      `codex plugin marketplace add siliconwitchery/superstack-agent-plugins`
      and `codex plugin add superstack@siliconwitchery`.
- [ ] `claude plugin validate .` clean.
- [ ] Add the `SYNC_PR_TOKEN` repository secret so sync-docs pull requests
      trigger CI.
- [ ] Tag v0.1.0 and attach skill zips for claude.ai users.
- [ ] Drop `.claude/settings.json` with `extraKnownMarketplaces` into
      `s2-lua-examples`.
- [ ] List on skills.sh and submit to anthropics/claude-plugins-community.
