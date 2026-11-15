# Quiz files

One file per quiz, under `quizzes/`, named `YYYY-MM-DD-<what it covers>-<mode>.md`, for
example `2026-11-20-phase-a-hard.md`. A quiz file is built over time like a lesson: it can
be stopped midway and resumed, and the review can happen later.

```markdown
# Quiz: Phase A, hard

**Covers:** A1, A2
**Mode:** hard
**Date:** 2026-11-20
**Status:** reviewed
**Score:** 3 of 4

## Q1 (A1)

**Question:** ...
**Your answer:** ...
**Grade:** right
**Explanation:** ... (S1)
**Review note:** what came out of talking it through
**Outcome:** understood

## Q2 (A1)
...
```

| Part | Rule |
|---|---|
| `**Covers:**` | The step ids, a phase, or `whole plan`. |
| `**Mode:**` | `easy`: recall, straight from the lesson, with hints available. `hard`: apply it to a new situation, with no hints. `expert`: exam-style scenarios, edge cases and trade-offs, including why the other options are wrong. |
| `**Status:**` | `in progress`, `answered` (all questions answered, not yet reviewed), or `reviewed`. |
| `**Score:**` | Filled in once every question is graded. |
| Each question | The step it tests in brackets after the number. |
| `**Grade:**` | `right`, `partly right`, or `wrong`. |
| `**Explanation:**` | The correct answer and why, tied to a source id. |
| `**Review note:**` | What came out of the discussion of this question. |
| `**Outcome:**` | `understood`; `review suggested`; or `plan change offered`, followed by `accepted` or `skipped`. |

A quiz is always an offer. A quiz changes nothing by itself: it never closes or reopens a
step. It leads only to a suggested review or to an offered change to the plan.

Writing questions:

- Write them from the steps' "Done when" lines, the lessons and the listed sources. For a
  certification, follow the exam's style.
- For multiple choice, make every option about the same length, move the correct option's
  position from question to question, and give no hint through formatting.
- Mix topics across steps only in apply-style questions. Keep terminology questions grouped.
- A hard question should be hard because it needs recall or application, never because it
  is worded awkwardly.
