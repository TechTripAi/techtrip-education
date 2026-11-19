# Copilot CLI session hooks (not shipped)

A draft of the two session hooks for GitHub Copilot CLI, matching `hooks/hooks.json` for
Claude Code. It is here, and not in the plugin, because it has not been run on an
installed copy of Copilot CLI. Until it has, Copilot CLI users get checkpoints through the
study partner's own step when a session is recorded, as every other tool does.

Written from GitHub's documentation as read on 2026-11-19:

- https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference
- https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-hooks-reference

## To confirm before promoting it

1. **Where the file goes.** The root `plugin.json` is an Agent Plugins 1.0 manifest, which
   Copilot CLI reads in preference to `.claude-plugin/plugin.json`. For that manifest type
   the documented location is `com.github.copilot/hooks/hooks.json`. Confirm it is loaded
   from there.
2. **How a hook finds the plugin's own files.** `${PLUGIN_ROOT}` is documented for MCP and
   LSP settings, not for hooks. The draft tries `PLUGIN_ROOT` and `COPILOT_PLUGIN_ROOT` as
   environment variables and does nothing when neither leads to the script. If Copilot
   substitutes `${PLUGIN_ROOT}` in the text before running it, that works too. Confirm one
   of them does.
3. **The working directory** when `cwd` is omitted. `session-hook.sh` walks up from the
   current directory to find the study root, so it must be the session's directory.
4. **Output at session start.** Copilot CLI reads only `additionalContext` from a JSON
   object on stdout. `session-hook.sh start` prints plain text, so it needs a mode that
   prints `{"additionalContext": "..."}` with the text escaped.
5. **Whether Copilot CLI reads `hooks/hooks.json`** at the plugin root, which is in Claude
   Code's format, and what it does with it.
6. **Windows.** The draft has a `bash` command only.

When all six are settled: move the file to its place, add the JSON mode and a test for it,
list it in README "What it writes" and add a CHANGELOG line.
