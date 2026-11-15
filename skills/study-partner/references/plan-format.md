# plan.md

The subject's study plan: what will be studied, in what order. There is one per subject.
Written during planning, after the brief and the sources. `init-progress.sh` parses it, so
three things have a fixed shape: the phase heading, the step line and the checkpoint line.

```markdown
# AWS Solutions Architect: study plan

**Status:** ready (updated 2026-11-13)
**Source:** brief.md

## Phase A: Core services

1. **[Learn] Compute options.** EC2, Lambda, containers. Sources: S1, S3.
   Done when: you can choose between them for a given workload and say why.
2. **[Apply] Launch and size an instance.** Hands-on in a free-tier account. Sources: S2.
   Done when: you have launched, resized and terminated an instance.

Checkpoint A: quiz on steps 1 to 2.

## Phase B: Networking. Builds on Phase A.

3. **[Learn] VPC basics.** Subnets and routing. Sources: S1.
   Done when: you can sketch a two-tier VPC.
```

| Part | Rule |
|---|---|
| Phase heading | `## Phase X: Title`, with a letter. Phases are stages of the subject in the order that makes sense to learn them. "Builds on Phase A" after the title is information only. |
| Step line | Starts at column zero: `N. **[Learn] Title.** ...` or `N. **[Apply] Title.** ...`. The id is the phase letter and the number: `A1`, `B3`. |
| Tag | `[Learn]` is something to understand. `[Apply]` is something to do. Every phase has both, so there is always a way to apply what was learned. |
| Numbering | Continues across phases and never restarts. A number is never reused or changed once a step has been worked on, because the ledger and the lesson files are keyed on it. Add new steps with new numbers. |
| Sources | `Sources: S1, S3.` on the step line, naming ids from `sources.md`. |
| Done when | The indented line under the step: one thing the learner will be able to do. Quiz questions are written from it. |
| Checkpoint line | Starts at column zero: `Checkpoint X: what it covers.` One per phase, after its steps. It is an offered quiz, not a step. |
| Anything else | Free text, as long as no other line starts with a number, a full stop and bold text. |

There are no gates. The learner may take steps in any order, skip any step, have several
lessons open at once, and stop at any point.

A step that appears before the first phase heading still parses, with a warning. Two steps
with the same number are an error.

After changing the plan, run `init-progress.sh "<subject>"`. It adds a ledger row for every
step and checkpoint that does not have one and changes nothing else. `--dry-run` shows what
it would do. A change to a plan that is already in use is made only after the learner
agrees to it, and is marked in place with a dated note.

For a plan with a target date, `pace.sh "<subject>"` shows how the remaining steps sit
against it, and `pace.sh --steps <n> --target <date>` works out a pace before the plan is
written.
