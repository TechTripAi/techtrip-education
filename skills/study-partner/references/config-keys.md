# study.config

One file at the top of a study root. Plain `KEY='value'` lines, sourceable by `sh`. Written
by `write-config.sh`; edit it by hand or re-run that script with `--force`. Never put a
secret in it: AI tools read this file.

| Key | Meaning | Default |
|---|---|---|
| `STUDY_NAME` | Name of this study root. Qualifies subject references as `<name>:<subject>` from any directory. Lowercase, hyphens. | the directory's name |
| `SUBJECTS_DIR` | Where active subject directories live. Relative to the study root unless absolute. | `subjects` |
| `LEARNER_NAME` | Optional. What the study partner calls the learner. | empty |
| `REVIEW_INTERVALS` | Days until a step is next suggested for review, as it moves up a level after each review that goes well. After the last level no further review is suggested. | `1 3 7 14 30` |

Unknown keys are ignored by the scripts.

## The registry

`write-config.sh` also records `STUDY_NAME=/absolute/path/study.config` in the per-user
registry `~/.study-roots` (or `$STUDY_ROOTS`). It lets a subject be found from any
directory. It is a convenience only: a script run from inside the study root finds
`study.config` by walking up, and when exactly one root is registered it is used without
being named.

The registry holds absolute paths, so it belongs to one machine and is never synced.
`write-config.sh --register <directory>` adds a study root that already exists to this
machine's registry and changes no file in it.

## More than one machine

A study root can be used from several machines by syncing its folder with any tool: a
private git repository, or a file-sync service. Everything in it is plain text with
relative paths, so the folder may sit at a different path on each machine. Keep
`SUBJECTS_DIR` relative; an absolute value is right on one machine only.

| Step | How |
|---|---|
| Once per machine | Sync the folder there, then `write-config.sh --register <directory>`. |
| Before a session | Bring the folder up to date (for git, pull). |
| After a session | Send the changes (for git, commit and push). The scripts never commit or push. |

Nothing locks a subject, so the rule is one machine at a time per subject. Different
subjects on different machines do not collide: only `overview.md` is shared, and it is
rebuilt by `overview.sh`. When the same subject was changed in two places, the file that
collides is usually `progress.md`.

`overview.sh` and `check-root.sh` report the signs, and stop nothing:

| Sign | Reported as | What to do |
|---|---|---|
| A conflict copy from a sync tool (`*.sync-conflict-*`, `*conflicted copy*`, `<name> 2.md`), outside `materials/` and `packets/` | note, WARN | Compare it with the original, keep what is right, move the copy out of the study root. |
| Merge markers in `brief.md`, `plan.md`, `progress.md`, `sources.md`, `glossary.md` or `overview.md` | note, FAIL | Resolve them. In `progress.md` keep the row with the later `Last worked` date for each step, and keep every session entry. |
| The study root is a git repository with an unfinished merge, changes not committed, or commits not pushed | note, WARN | Finish the merge; commit and push when the session is over. |

`overview.md` and `packets/` are generated. A conflict in either is settled by running
`overview.sh` or `export-packet.sh` again.

## Layout of a study root

```
<study root>/
  study.config
  overview.md              rebuilt by overview.sh; see overview-format.md
  subjects/                active subjects
    <subject>/
      brief.md             see brief-format.md
      sources.md           see sources-format.md
      plan.md              see plan-format.md
      lessons/             one file per step; see lesson-format.md
      glossary.md          terms, used the same way in every lesson
      sheets/              cheat sheets
      quizzes/             see quiz-format.md
      materials/           files the learner supplied: a syllabus, an exam guide, slides
      progress.md          working state; see progress-format.md
  packets/<subject>/       the exported packet; see packet-format.md
  archive/                 closed subjects, moved here whole, with index.md
```

All state is plain text under the study root. Nothing needed to resume lives anywhere else.
Each subject is independent: nothing in one subject refers to another.
