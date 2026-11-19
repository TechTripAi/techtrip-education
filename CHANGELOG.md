# Changelog

All notable changes to `techtrip-education` are documented here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [0.3.0] - 2026-11-19

### Added
- **Checkpoints.** A history of the study root's files, kept inside it, so an earlier
  version of anything can be looked at or brought back. Off until the learner says yes; the
  study partner asks once, in plain words, and records the answer in `study.config`
  (`AUTO_CHECKPOINT`). Git is the engine and the learner does not need to know it.
  - `checkpoint.sh` turns them on and off, saves one, lists them, prints a file as it was
    on a day, and brings a file, a folder or the whole root back. Bringing back saves the
    present state first and deletes nothing.
  - The study partner saves a checkpoint when it records a session.
  - They are never offered where they cannot be kept: git not installed, a study root
    inside a file-sync folder (iCloud Drive, Dropbox, OneDrive, Google Drive and others,
    recognised by folder name), or inside another git repository.
  - With no git identity set, a save uses the learner's name from `study.config`, so a
    first checkpoint cannot fail on that.
  - Nothing pushes, pulls, fetches or adds a remote.
- Claude Code session hooks (`hooks/hooks.json`). At session start, what the scripts note
  about the study root is passed to the session; at session end a checkpoint is saved if
  they are on. Both act only when the session was started inside a study root.
- `check-root.sh` has a `checkpoints` row; `overview.sh` prints an `overview: offer:` line
  while checkpoints could be kept and have not been offered, and a note when they are on
  and cannot be saved on this machine.
- `references/checkpoints.md`, `tests/checkpoints.sh`, `docs/decisions/ADR-002`.

### Not included
- Session hooks for Copilot CLI. A draft is in `incubator/copilot-hooks/` with what has to
  be confirmed on an installed copy first. Copilot CLI and every other tool save
  checkpoints through the study partner's own step when a session is recorded.

## [0.2.2] - 2026-11-19

### Added
- `record-session.sh` sets the `Last session` date in a subject's `progress.md` and a new
  `Last machine` line beside it. When a subject was last recorded on a different machine,
  `overview.sh` and `check-root.sh` say so. On a network share that is the only sign there
  is, since two machines writing one file leave no conflict copy. Ledgers without the line
  read as before.
- `STUDY_FORMAT` in `study.config`: the format of a study root's files. It is 1, and a root
  with no stamp is format 1. `overview.sh` and `check-root.sh` say when a root is in an
  older format, or in a newer one than this copy of the plugin can write.
- `check-root.sh --upgrade` brings a study root in an older format up to date. No release
  has needed a step yet, so today it only records the format.
- README "Updating": the update command for each way of installing, Copilot CLI included.
- The tour says to start a new chat for each sitting and to say "pause here" before leaving.

### Changed
- Notes about a git study root are worded for a learner who does not know git: changes not
  yet saved to the root's history, checkpoints not yet sent to other machines, files changed
  in two places and only half combined. The git term follows in brackets.
- `init-progress.sh` brings the description of an existing checkpoint into line with the
  plan when the plan rewords it. The checkpoint's status and every step row stay as they are.
- "More than one machine" says what works: anything that presents the study root as an
  ordinary folder, a network share included. A notebook application does not.

## [0.2.1] - 2026-11-18

### Fixed
- `init-progress.sh` failed on macOS (`awk: newline in string`) when a changed plan added
  more than one step, or more than one checkpoint, to an existing `progress.md`. It left an
  empty `progress.md.tmp.<pid>` beside the ledger and added nothing; the ledger itself was
  not changed. The new rows now reach awk through the environment, so any number can be
  added at once and a backslash in a title is kept as written. If the rewrite fails for
  another reason, the temporary file is removed and the script says the ledger is unchanged.

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
