# progress.md

The subject's working state: where every step stands, which checkpoints have been offered,
and what happened in each session. It is not part of the exported packet.
`init-progress.sh` creates it and adds rows; `set-step.sh` and `record-review.sh` update one
row at a time; `record-session.sh` writes the two header lines; the study partner writes the
session entries.

```markdown
# AWS Solutions Architect: progress

**Last session:** 2026-11-20
**Last machine:** desk

## Steps

| Step | Phase | Kind | Title | Status | Level | Last worked | Next review | Note |
|---|---|---|---|---|---|---|---|---|
| A1 | A | Learn | Compute options | done | 1 | 2026-11-20 | 2026-11-21 | |
| A2 | A | Apply | Launch and size an instance | skipped | 0 | 2026-11-13 | - | already do this at work |
| B3 | B | Learn | VPC basics | in progress | 0 | 2026-11-20 | - | |

## Checkpoints

| Checkpoint | Covers | Status |
|---|---|---|
| CP-A | quiz on steps 1 to 2. | taken 2026-11-20 |

## Sessions

### 2026-11-20 (session 2)
Did: finished A1; started B3 and stopped at routing tables; took the Phase A quiz on hard.
Offered and declined: adding a step on spot instances.
```

## Step rows

Never edit a step row by hand. Use the scripts:

| To record | Run |
|---|---|
| A step's status | `set-step.sh "<subject>" <id> pending|started|done|skipped|deferred [--note "<reason>"]` |
| How a review or quiz question went | `record-review.sh "<subject>" <id> pass|fail` |

`Status` is `pending`, `in progress`, `done`, `skipped` or `deferred`. A step is `done` when
the learner says it is. Several steps can be `in progress` at once. Record the reason for a
skip or a deferral with `--note`.

`Level` and `Next review` belong to review suggestions. `pass` moves a step up a level and
sets the next suggestion further out; `fail` moves it back to level 1 and sets it soon. The
gaps are `REVIEW_INTERVALS` in `study.config`. A step is suggested for review when its
`Next review` is today or earlier; `reviews.sh` lists them. A suggestion is an offer.

## Checkpoint rows

`set-step.sh "<subject>" CP-A taken|skipped|pending`. A checkpoint is offered once its phase
has been worked through; record `skipped` when the learner declines, so it is not offered
again unless they ask. When the plan rewords a checkpoint, `init-progress.sh` brings the
`Covers` text into line with it and leaves the status alone.

## Header and sessions

`**Last session:**` is `YYYY-MM-DD` or `-`. `**Last machine:**` is the short name of the
machine the last session was recorded on; a ledger written before version 0.2.2 has no such
line until its next session. Neither is written by hand: after appending the session entry,
run `record-session.sh "<subject>" [--date YYYY-MM-DD]`. When a subject was last recorded on
a different machine, `overview.sh` and `check-root.sh` say so.

Append one entry per session under `## Sessions`, newest last: what was done, and anything
that was offered and declined. Never rewrite an earlier entry. Where the learner stopped
inside a lesson is recorded in that lesson file, not here.
