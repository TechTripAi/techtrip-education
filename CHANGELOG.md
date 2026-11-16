# Changelog

All notable changes to `techtrip-education` are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [0.2.0] - 2026-11-16

First public release, listed in the TechTrip-AI-plugins catalog. Under test as release
candidate 1 (RC1); the README says so.

### Added
- `write-config.sh --register <directory>` adds a study root that already exists, such as
  one synced from another machine, to this machine's registry and changes no file in it.
- `overview.sh` (as `overview: note:` lines on stderr) and `check-root.sh` (as `sync` rows)
  report signs that a study root was changed in two places or holds work another machine
  cannot see: conflict copies from a sync tool, merge markers in the files the scripts
  read, and, when the study root is a git repository, an unfinished merge, changes not
  committed and commits not pushed. They report and stop nothing.
- "More than one machine" in `references/config-keys.md`.
- A new subject opens with a short bulleted list of what planning will ask for (what the
  plan is built from, the mission, what done means, an optional target date, sources), so
  the learner sees it all before the first question. Only the topic is needed to begin, and
  the list says the skill can look for sources itself.
- README: one-command install for Cursor, Codex, Gemini CLI and other tools
  (`npx skills add`), and Gemini CLI authentication with an API key.
- README opens with the education banner (`img/FellowshipOfTheAgents-Education.png`) and
  gives the catalog install; installing a clone is now under "Developing".

### Changed
- The tour skill is `study-orientation`; it was `brain-dump`. Each TechTrip plugin now names
  its own tour, so that two plugins' tours can sit in one flat skills folder. "Give me the
  study tour" reaches it in plain words.
- `check-root.sh` suggests `write-config.sh --register` for a study root that is not
  registered, in place of `--force`.

## [0.1.0] - 2026-11-12

### Added
- **study-partner**: one skill for studying a certification, a training course or any
  topic over time. Plan first: a brief with the mission and an optional target date, the
  authoritative sources, then a phased study plan of `[Learn]` and `[Apply]` steps. Works
  out the subject and the kind of help from plain language or short menus; acts as
  teacher, partner or assistant through role guidance read on demand; reads one subject's
  directory at a time.
- Everything the skill starts on its own is an offer: quizzes in easy, hard or expert mode
  with a question-by-question review, checkpoints, suggested reviews, plan changes, sources
  it found. No gates: any order, any step skipped, several lessons open, stop at any point.
- A living lesson file per step, a glossary, cheat sheets and quiz files, which together
  with the brief, sources and plan make a Markdown packet. `export-packet.sh` exports or
  refreshes it at any time; `close-subject.sh` makes a final export and archives the
  subject; `--reopen` brings it back.
- Study root layout and formats in `skills/study-partner/references/`.
- Scripts: `write-config.sh`, `new-subject.sh`, `resolve-subject.sh`, `init-progress.sh`,
  `set-step.sh`, `record-review.sh`, `open-lesson.sh`, `reviews.sh`, `overview.sh`,
  `pace.sh`, `export-packet.sh`, `close-subject.sh`, `check-root.sh`, over a shared
  `lib/resolve.sh`.
- **brain-dump**: menu-style tour. Teaches, never does.
- Agent Plugins 1.0.0 root manifest, Claude Code manifest and a development marketplace
  file; `scripts/check.sh`; tests under `tests/`; a three-OS CI matrix.
- ADR-001: the study partner's design.
