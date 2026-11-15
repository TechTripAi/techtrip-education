# ADR-001: The study partner: plan first, one skill, independent subjects, offers not gates

**Status:** Accepted
**Date:** 2026-11-12
**Deciders:** Terry

## Context
The first user is a professional studying for certifications and training, self-directed
and not on a timetable. A learner has several subjects under way at once; each is
long-lived and needs its own state and its own narrow context, and the learner needs one
view across them. The design should work the way the story workflow in
`techtrip-engineering` works, because that is how the owner already works: a spec in, a
plan first, then the plan carried out one step at a time, with all state in plain files.

## Options considered
1. One skill per role (teacher, partner, assistant) plus an orchestrator: more commands for
   the learner to know, and it is the same AI in every case.
2. One agent definition per subject or per role: real isolation, but something has to be
   created per subject, and it does not work in tools without agents.
3. A school-shaped model: classes, terms, a syllabus with units and topics, due reviews as
   a queue. It suits a regimented student, not a self-directed professional.
4. One skill over independent subject directories, plan-first, with everything the skill
   initiates treated as an offer (this decision).

## Decision
Option 4.

- **A subject is a directory of plain files** under the learner's study root. Subjects are
  independent: nothing from one appears in another, and work on one never reads another's
  directory. The view across subjects, `overview.md`, shows status only.
- **Plan first, as in the story workflow.** Input is a spec, a syllabus, an exam guide or
  just a topic; with no spec the skill asks whether it is a brand-new learning topic. The
  AI does the research. Three things are settled before any teaching:
  - the **brief**: the mission (why the learner is studying this), what done means, and an
    optional target date, open-ended by default. A date sizes the plan; passing it does
    nothing.
  - the **sources**: authoritative sources, proposed with a reason each and approved by
    the learner, who may add more at any time. A claim on no listed source is labelled.
  - the **study plan**: phases of numbered steps, each tagged `[Learn]` or `[Apply]` with a
    "Done when", and one offered checkpoint per phase.
- **The skill offers; the learner decides.** Quizzes, checkpoints, suggested reviews, plan
  changes and sources the skill finds are offers that can be accepted, skipped or deferred.
  There are no gates: steps in any order, any step skipped with a reason, several lessons
  open at once, stop at any point. There is no placement step.
- **One skill, `study-partner`.** The learner speaks in plain words or picks from short
  menus. A role (teacher, partner, assistant) is a stance toward the same files, kept as a
  guidance file read only when in use.
- **A lesson is a living file per step.** Its headings are its scaffold, laid down when the
  lesson opens and filled in over time. It holds its own place, so it can be stopped
  midway, and it takes a dated line each time it is reviewed.
- **Learning is easy; the challenge is in quizzes.** Three modes: easy, hard and expert.
  The review goes one question at a time, and what it turns up is offered back into the
  plan. A quiz changes nothing by itself.
- **A packet builds as you go.** Brief, sources, plan, glossary, lessons, cheat sheets and
  quizzes are clean Markdown, exportable and refreshable at any time. Closing a subject
  makes a final export and moves it to the archive, which keeps the active list bounded.
  The packet depends on nothing in this plugin.
- **The plugin does not regulate what the learner asks for.** It carries no rules about
  what kind of help is allowed.
- **Sub-agents are deferred.** Every piece of work is already a subject, a role and a task,
  so a background worker would be handed a subject directory and a role file with no
  change to the files.

## Consequences
- The skill folder is self-contained (scripts, roles and references inside it), so it works
  when only that folder is linked or copied into another tool. Each format exists once.
- The scripts follow the story workflow's patterns (config found by walking up, a per-user
  registry, a plan parser with a dry run, a status table) but are this plugin's own,
  because each plugin must install without the other.
- Suggested reviews use a simple ladder of growing gaps. It is a convenience, not a
  schedule the learner owes anything to.
- A school-shaped layer (terms, dated coursework, marking against a rubric) can be added
  later on the same core.
- A single writer per subject is assumed. It becomes a stated rule when background workers
  arrive.

## Influences
The mission, settling trusted sources before teaching, and the rules for writing
multiple-choice options came out of a comparison with the `/teach` skill by Matt Pocock
(`mattpocock/skills`, MIT). No text from it is used.
