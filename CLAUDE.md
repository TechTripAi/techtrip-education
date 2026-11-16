# CLAUDE.md

Guidance for AI coding agents working in this repository. `CLAUDE.md` and `AGENTS.md` carry
the same text; when you change one, change the other.

## What this is

**`techtrip-education`** is TechTrip AI's education plugin: one plugin for the whole
domain, holding education skills flat under `skills/`. It starts with `study-partner`, an
interactive study partner for certifications, training and any topic, with long-lived state
per subject, and `study-orientation`, the tour, which teaches how to use it. Further
education skills are added beside them over time.

One tree carries an Agent Plugins 1.0.0 manifest at `plugin.json`, a Claude Code manifest at
`.claude-plugin/plugin.json`, and plain `skills/<name>/SKILL.md` folders (Agent Skills
format). Released; listed in the TechTrip catalog as `techtrip-education`, category
`education`. Users install it from there (README "Install").

Install a checkout for development (it loads in place):
```
git clone https://github.com/TechTripAi/techtrip-education.git
claude plugin marketplace add /path/to/techtrip-education
claude plugin install techtrip-education@techtrip-education
```

## The design (`docs/decisions/ADR-001`)

It is the story workflow's shape applied to study: a spec in, a plan first, then the plan
worked one step at a time, with all state in plain files.

- **A subject is one directory of plain files** under the learner's study root. All state
  is there; resuming needs nothing else. Subjects are independent: nothing in one refers
  to another, and work on one never reads another's directory.
- **Plan first.** A brief with the mission and an optional target date, then the
  authoritative sources, then a phased study plan of `[Learn]` and `[Apply]` steps.
- **The skill offers; the learner decides.** Quizzes, checkpoints, suggested reviews, plan
  changes and sources the skill finds are offers. There are no gates: any order, any step
  skipped, several lessons open, stop at any point. A target date that passes does nothing.
- **One skill.** The learner never names a role or a command. A role (teacher, partner,
  assistant) is a guidance file under `roles/`, read only when in use.
- **A lesson is a living file per step.** Its headings are its scaffold; they are filled in
  over time, and the file holds its own place.
- **The packet builds as you go.** Brief, sources, plan, glossary, lessons, sheets and
  quizzes are clean Markdown, exportable at any time. Closing archives the subject after a
  final export.
- **The view across subjects is status only**, through `overview.md`.
- **The plugin does not regulate what the learner asks for.** It carries no rules about
  what kind of help is allowed. Do not add any.

## Layout

- `skills/study-partner/` is self-contained, so it works when only the skill folder is
  linked or copied into another tool:
  - `SKILL.md`: short. Find the study root, menus, work out the subject, read only that
    subject, pick the role, lessons, sources, record, export and close.
  - `roles/`: `teacher.md` (planning, changing a plan, teaching a Learn step), `partner.md`
    (working steps, Apply steps, reviews), `assistant.md` (quizzes, research, sheets,
    glossary, sources).
  - `references/`: every file format, once: `config-keys.md`, `brief-format.md`,
    `sources-format.md`, `plan-format.md`, `lesson-format.md`, `quiz-format.md`,
    `progress-format.md`, `overview-format.md`, `packet-format.md`.
  - `scripts/`: `lib/resolve.sh` (sourced by every script), `write-config.sh`,
    `new-subject.sh`, `resolve-subject.sh`, `init-progress.sh`, `set-step.sh`,
    `record-review.sh`, `open-lesson.sh`, `reviews.sh`, `overview.sh`, `pace.sh`,
    `export-packet.sh`, `close-subject.sh`, `check-root.sh`.
- `skills/study-orientation/SKILL.md`: the tour. Teaches, never executes, never restates a
  format.
- `incubator/<name>/` for unpromoted skills. Manifests never see it.
- `docs/` for maintainer documents; `docs/decisions/` for ADRs about this repo.
- `scripts/check.sh` is the health check. Run it before every commit. `tests/*.sh` are run
  by it and by CI on ubuntu, macos and windows.
- `.claude-plugin/marketplace.json` makes the repo its own single-plugin marketplace for
  development.

No learner data lives in this repository. A study root is created wherever the learner
chooses.

## How it fits at runtime

- `study.config` at the top of the study root is the only configuration. Scripts find it
  via `$STUDY_CONFIG`, by walking up from the current directory, or through the per-user
  registry `~/.study-roots` (`name=/path/study.config`, written by `write-config.sh`); when
  exactly one root is registered it is used without being named. The file is sourced, so
  values are plain shell assignments and nothing secret may go in it.
- A study root is shared between machines by syncing its folder; the plugin does no
  syncing. The registry holds absolute paths and is per machine, so
  `write-config.sh --register <directory>` adds an existing root to it without changing
  the root. Nothing locks a subject. `sync_notes` in `lib/resolve.sh` finds conflict
  copies, merge markers and, in a git repository, unmerged, uncommitted and unpushed
  work; `overview.sh` prints them as `overview: note:` lines on stderr and
  `check-root.sh` as `sync` rows. They are reports and never stop anything.
- A subject reference is `[<root>:]<directory name | fragment of the name or title | path>`.
  `resolve-subject.sh` prints the subject directory; exit 4 lists several matches, exit 5
  means no subject was named, exit 2 says when a subject is archived.
- `resolve_subject` is called in a command substitution, so the settings it loads do not
  reach the caller. A script that needs the study root's settings afterwards calls
  `load_root_for <subject-dir>`.
- `plan.md` is the contract between planning and the ledger. `init-progress.sh` parses
  `## Phase X: Title` headings, column-zero `N. **[Learn|Apply] Title.**` lines into step
  ids such as `A1` and `B3`, and `Checkpoint X:` lines into `CP-X`. It creates
  `progress.md`, or adds rows for new steps and checkpoints and changes nothing else.
- `set-step.sh` is the only thing that changes a step's or a checkpoint's status.
  `record-review.sh` is the only thing that changes a step's review level and next
  suggested review; levels step through `REVIEW_INTERVALS` (days). The skill never does
  that arithmetic.
- `open-lesson.sh` creates a lesson file with its header from the plan and never changes an
  existing one. Where the learner stopped inside a lesson is in the lesson file; a step's
  status is in `progress.md`.
- `overview.sh` rebuilds `overview.md` from each active subject's brief header and ledger.
  `reviews.sh` lists steps whose next review is today or earlier. `pace.sh` reports
  remaining steps against the target date and changes nothing.
- `export-packet.sh` copies the packet files to `packets/<subject>/` and regenerates its
  `index.md`; it can be run at any time and never touches the subject. `close-subject.sh`
  marks the brief closed, exports, and moves the subject to `archive/`; `--reopen` reverses
  the move. Nothing is ever deleted.
- Date arithmetic is done in awk inside `lib/resolve.sh`, so it behaves the same with BSD
  `date`, GNU `date` and Git Bash. `$STUDY_TODAY` overrides today's date; the tests use it.

## Exercising a script change

```
d=$(mktemp -d); export STUDY_ROOTS="$d/registry" STUDY_CONFIG="$d/root/study.config"
S=skills/study-partner/scripts
bash $S/write-config.sh "$d/root" STUDY_NAME=scratch
bash $S/new-subject.sh "Example Subject" --slug example --target 2027-06-01
# write $d/root/subjects/example/plan.md following references/plan-format.md
bash $S/init-progress.sh example --dry-run && bash $S/init-progress.sh example
bash $S/open-lesson.sh example A1
bash $S/set-step.sh example A1 done; bash $S/record-review.sh example A1 pass
bash $S/reviews.sh; bash $S/pace.sh example; bash $S/overview.sh --stdout
bash $S/export-packet.sh example; bash $S/check-root.sh
```

Always set `STUDY_ROOTS` to a scratch file when testing, so the real registry is untouched.

## Invariants (check.sh enforces most of these)

- Every folder under `skills/` is listed in README "Skills included" and, except
  `study-orientation` itself, mentioned in `study-orientation`.
- The tour skill is `study-orientation`. Its name is unique across TechTrip plugins and its
  description carries "tour" and "how do I use" (the catalog's `docs/packaging.md`).
- `description` is at most 1024 characters (Copilot CLI silently skips longer skills).
- SKILL.md frontmatter uses only Agent Skills spec keys plus the Claude Code extensions
  `argument-hint` and `disable-model-invocation`. Both skills stay model-invocable: plain
  language such as "let's study sci 101" must reach `study-partner`.
- Every format is described once, in `skills/study-partner/references/`. `SKILL.md`, the
  role files and `study-orientation` point there and never paste a ledger, plan or brief
  skeleton.
- `study-partner/SKILL.md` stays short. Role detail goes in `roles/`, format detail in
  `references/`.
- Every script named in `study-partner/SKILL.md` exists.
- All state is plain text under the study root. Nothing on the resume path reads the
  registry alone, a transcript, or anything owned by a harness.
- Existing study roots keep working. Change the plan parser or the ledger columns only with
  a matching update to the reference file and a CHANGELOG line.
- Anything the skill starts on its own is worded as an offer. No script or skill text
  blocks the learner, enforces an order, or reacts to a target date that has passed.
- Nothing is deleted from a study root. Closing moves a subject; exporting copies.
- `version` and `description` agree between `plugin.json` and `.claude-plugin/plugin.json`,
  the entry in `.claude-plugin/marketplace.json` carries the same version, and the
  CHANGELOG's first `## [x.y.z]` heading matches.
- Scripts: `#!/usr/bin/env bash`, `set -eu`, no arrays (macOS bash 3.2), POSIX tools,
  `SCRIPT_DIR` via `pwd -P`, CR stripped when parsing, never overwrite a learner's file
  without `--force`, never `git push`, never write a secret. No CR line endings in tracked
  text.
- No personal names, subject names or paths inside a skill; they belong in the learner's
  study root.
- `AGENTS.md` and `CLAUDE.md` are identical below the title line.

## Not built yet

Background and parallel work by sub-agents ("research this for one subject while I study
another"). The design leaves room for it: every piece of work is a subject, a role and a
task, and a worker would be handed the subject directory and the role file. One writer per
subject at a time. Nothing in the files has to change for it.

## Validate

```
bash scripts/check.sh               # needs node on PATH (reads the manifests); skips plugin validate if claude is absent
claude plugin validate .            # one known warning: root CLAUDE.md is not loaded as context
claude --plugin-dir .               # then talk to it in a scratch study root
```

## Release

Bump `version` in both manifests and in the entry in `.claude-plugin/marketplace.json`, add
the CHANGELOG section, run `check.sh`, commit locally with a plain message (no attribution
lines). The owner pushes. After every release here, the entry's `version` in the
TechTrip-AI-plugins catalog is set to the same string.

## Meta

- License: **FSL-1.1-MIT** (`LICENSE.md`). Copyright 2026 Terry Trippany (Try AI Solutions).
- Owner/repo: `TechTripAi/techtrip-education` (public).
- Packaging, naming and release rules for every TechTrip plugin:
  https://github.com/TechTripAi/TechTrip-AI-plugins/blob/main/docs/packaging.md
  (the catalog's `docs/packaging.md`). Follow it; do not restate it here.
