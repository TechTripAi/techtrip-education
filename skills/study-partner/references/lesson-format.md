# Lesson files

One file per step, under `lessons/`, named for the step: `A1-compute-options.md`. Created
by `open-lesson.sh`, which takes the header from the plan. A lesson is built over time: it
can be stopped midway, come back to, and reviewed, and several lessons can be open at once.
Each lesson stands on its own. It links to another lesson only where it truly builds on it.

```markdown
# A1: Compute options

**Step:** A1 [Learn]
**Done when:** you can choose between them for a given workload and say why.
**Sources:** S1, S3
**Stopped at:** When a container is the better choice

## What each option is

Covered text, with each claim tied to a source id, such as (S1).

## How they differ in cost and control

Covered text.

## When a container is the better choice

## Try it

## Parked questions

## Reviews

- 2026-11-20: reviewed from memory; mixed up Lambda's time limit, went over it again.
```

How a lesson is built:

1. **Scaffold first.** When the lesson is opened, add one `## ` heading for each point it
   will cover, in order, above "Try it", with nothing under them yet. Show the learner the
   headings and change them if they want.
2. **Fill in as you go.** Write under a heading once that point has been covered, in short
   paragraphs with a worked example where it helps. Tie each claim to a source id.
3. **Mark where you stopped.** Keep `**Stopped at:**` pointing at the heading to pick up
   from, or `finished` when every heading is filled.
4. **Headings can change.** Add, drop or reorder them at any time.

| Part | Rule |
|---|---|
| Header lines | `Step`, `Done when` and `Sources` come from the plan. Keep them in step with it. |
| `**Stopped at:**` | `not started`, a heading's text, or `finished`. |
| Point headings | The lesson's own structure. Empty ones are what remains. |
| Try it | Something for the learner to do with what the lesson covered. |
| Parked questions | Things the learner asked that were set aside, so they are not lost. |
| Reviews | One dated line each time the lesson is revisited: what was gone over and what was shaky. Never rewrite the lesson for a review. |

New terms go into `glossary.md` when they first appear, and are used the same way in every
later lesson of the subject.

A step's status lives in `progress.md`, not in the lesson file.
