# Conventions

Maintainer rules for this repository. `CLAUDE.md` and `AGENTS.md` summarise them for agents;
this file is the long form. Packaging, naming and release rules shared by every TechTrip
plugin are in the catalog's `docs/packaging.md` and are not repeated here.

## Layout
- `skills/<name>/SKILL.md` plus optional `scripts/`, `references/`, `roles/`. Flat; no
  bucket folders. The skill's `name` equals its directory name. Related skills share a
  prefix (`study-`).
- A skill is self-contained: its scripts, references and role files live inside its own
  folder, so it works when only that folder is linked or copied into another tool.
- `incubator/<name>/` for unpromoted skills. Never referenced by manifests.
- `docs/` for maintainer documents and `docs/decisions/` for ADRs about this repo.
- `tests/*.sh` are standalone bash, each building a scratch study root under `mktemp -d`
  with `STUDY_ROOTS` pointed at a scratch registry. They delete nothing; the OS temp cleaner
  owns what they leave.
- `plugin.json` (Agent Plugins 1.0.0) and `.claude-plugin/plugin.json` (Claude Code) carry
  the same `version` and `description`.

## Frontmatter
- `name`, `description` (at most 1024 characters; Copilot CLI silently skips longer ones).
- Both skills are model-invoked and keep a rich trigger description so plain language
  reaches them.
- `argument-hint` on anything that takes an argument.

## Writing skill text
- The learner never has to name a role, a file or a command. Skill text is written so the
  agent infers the subject and the kind of help.
- Keep `SKILL.md` short. A role's detail goes in `roles/<role>.md`; a file's shape goes in
  `references/<file>-format.md`. Each is read only when needed.
- Describe a format once. Other files point at the reference by name.
- No rules about what kind of help the learner may ask for. The plugin does not regulate
  that (`docs/decisions/ADR-001`).
- Anything the skill starts on its own is written as an offer the learner can decline:
  quizzes, checkpoints, suggested reviews, plan changes, sources it found.
- When a request is open, the skill shows a short numbered menu and waits. Decisions during
  planning are brought as menus with the recommended choice first.
- No personal names, subject names or paths. Use `<placeholders>`.

## Format ownership
| Format | File (under `skills/study-partner/references/`) |
|---|---|
| `study.config` keys, registry, study root layout | `config-keys.md` |
| `brief.md`: mission, done means, target date | `brief-format.md` |
| `sources.md` | `sources-format.md` |
| `plan.md` and the parser's rules | `plan-format.md` |
| Lesson files | `lesson-format.md` |
| Quiz files, modes and question-writing rules | `quiz-format.md` |
| `progress.md`, statuses and review suggestions | `progress-format.md` |
| `overview.md` | `overview-format.md` |
| The packet, export, close and reopen | `packet-format.md` |
| Checkpoints: the offer, saving, looking back, bringing back | `checkpoints.md` |

## Scripts
- `#!/usr/bin/env bash`, `set -eu`, no arrays (macOS ships bash 3.2), POSIX tools only.
- `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"`, then source
  `lib/resolve.sh`.
- Strip `\r` when parsing a learner's file.
- Date arithmetic goes through `date_add` in `lib/resolve.sh`, never the local `date`
  command's own options.
- Never overwrite a learner's file without `--force`; never delete anything from a study
  root; never push, pull, fetch or add a remote; never write secrets.
- No `case` statement inside a `$( )` command substitution: bash 3.2 cannot parse it. Put
  it in a function and call that.
- A function that resolves a subject runs in a command substitution. Call
  `load_root_for <subject-dir>` afterwards when the script needs the study root's settings.
- A usage comment at the top of every script: what it does, usage, exit codes.

## Release
1. Bump `version` in `plugin.json`, `.claude-plugin/plugin.json` and the entry in
   `.claude-plugin/marketplace.json`.
2. Add the `## [x.y.z] - YYYY-MM-DD` section to `CHANGELOG.md`.
3. `bash scripts/check.sh`.
4. Commit locally with a plain message. The owner pushes.
5. Set the entry's `version` in TechTrip-AI-plugins to the same string after every release
   here. That entry is what marketplace users of Claude Code and Copilot CLI receive, so a
   release is not finished until it is set. The catalog's check compares it with the pushed
   manifest, so it is done after the owner pushes.
