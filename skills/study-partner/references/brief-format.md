# brief.md

What a subject is and why the learner is studying it. Created by `new-subject.sh`, filled
in during planning. Scripts read the title and the `**Label:**` lines at the top.

```markdown
# AWS Solutions Architect

**Subject:** aws-sa
**Status:** active
**Kind:** certification
**Started:** 2026-11-13
**Target date:** 2027-01-15

## Mission

## Done means

## Where the plan came from

## How I want to work
```

| Part | Rule |
|---|---|
| `# ` heading | The subject's title. `resolve-subject.sh` matches a reference against it and the directory name. |
| `**Subject:**` | The directory name. |
| `**Status:**` | `active`, `paused`, or `closed YYYY-MM-DD`. `close-subject.sh` writes the last one. |
| `**Kind:**` | `certification`, `training` or `topic`. |
| `**Started:**` | `YYYY-MM-DD`. |
| `**Target date:**` | `none`, which is the default and means open-ended, or `YYYY-MM-DD`. A planning aid only: it sizes the plan and appears in the overview. A date that passes changes nothing. |
| Mission | Why the learner is studying this, in their words. It decides how deep lessons go and what the plan emphasises. Changed only when the learner says so; note the change in the session log. |
| Done means | What the learner will be able to do when the subject is finished. |
| Where the plan came from | The spec the plan was built from (a syllabus, an exam guide, a course outline, a book's contents), or "a new topic, planned from the learner's description". |
| How I want to work | The learner's preferences: pace, depth, how lessons should be delivered, anything they say about how they like to study. Add to it when they tell you something new. |

Keep each `**Label:**` on its own line, exactly as spelled. Everything under the `##`
headings is free text.
