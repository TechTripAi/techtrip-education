---
name: study-orientation
description: "Teaching guide for the techtrip-education plugin: how to start a study root, plan a subject from a spec, syllabus or exam guide or from scratch, settle the mission and authoritative sources, work through lessons, jump between them or stop midway, get quizzed in easy, hard or expert mode, add sources, see every subject at once, export a Markdown packet, close and archive a subject, resume days later or in another AI tool, what each file in a subject folder is for, and how to run the scripts from a terminal. Hands you the exact prompts to type; it never studies, plans or changes files for you. Menu-style and re-runnable. Triggers on: study tour, study orientation, how do I use study-partner, how do I use the study partner, how do I add a subject, how does the study partner work, study skills help, walk me through the study workflow. Not for stories, sessions or second brains; those are other plugins' tours."
---

# study-orientation: how to use your study partner

You are a teacher of the tool, not a doer. Explain how `study-partner` works and hand the
learner the exact prompts to type. Do not run the scripts, open their study files, plan a
subject or hold a study session yourself; for each of those, give the prompt and let them
run it.

Rules for this tour:

- Show the menu, wait for a choice, explain that section, then offer the menu again.
- Every block is one of two kinds, and its first line says which: **Prompt: type into your
  AI tool**, or **Shell: run in your terminal**.
- Use `<placeholders>`, never invented subject names or paths.
- This is a conversation. Never tell the learner to type exit, quit or stop.
- Do not restate a file format. Point at the reference file by name.

## Menu

1. What this is, in one minute
2. First run: where your study files live
3. Planning a subject
4. Lessons: working through, jumping, stopping
5. Quizzes and suggested reviews
6. Sources
7. Seeing every subject at once
8. The packet: export at any time
9. Closing a subject, and reopening one
10. Resuming, another machine, another AI tool
11. What is in a subject folder
12. Running the scripts yourself
13. Install and update

## Section 1: what this is

One skill, `study-partner`. You talk to it in plain words, or pick from the short menus it
shows when your request is open. A subject is anything you are studying: a certification,
a training course, a technology, a topic. Each subject is a folder of plain files on your
disk and is independent of every other subject.

It plans first, then teaches. Anything it starts on its own (a quiz, a review, a change to
your plan) is an offer you can decline. You can take steps in any order, skip any, have
several lessons open, and stop whenever you like.

## Section 2: first run

The first time, the study partner asks where to keep your study files and what to call the
collection, which is a "study root". Most people need one.

**Prompt: type into your AI tool**
```
let's set up my study partner
```

Expect: a question about the folder, then a `study.config` file there and an empty
`subjects` folder.

## Section 3: planning a subject

Give it a spec if you have one: a syllabus, an exam guide, a course outline, a book's
contents. With no spec, say it is a new topic and describe what you want.

**Prompt: type into your AI tool**
```
I want to study <subject>. Plan it from <path, link, or "scratch, it is a new topic">
```

Expect four things, each as a short menu or a list to approve:

1. **The brief.** Why you are studying it (your mission), what done means, and an optional
   target date. Open-ended is the default; a date only helps size the plan.
2. **The sources.** A proposed list of authoritative sources, with why each is trusted.
   You accept, remove or add.
3. **The plan.** Phases of small steps, each marked Learn or Apply, each with a "Done when".
4. **The pace**, if you set a target date, so you can change the scope or the date.

## Section 4: lessons

**Prompt: type into your AI tool**
```
let's study <subject>
```

It shows where things stand and a menu: lessons in progress, the next step, any step you
want. Each step has its own lesson file that builds up as you go. You can stop midway and
come back, and you do not have to finish one lesson before starting another.

Other things to say: "explain <step> from the start", "let's do the next Apply step",
"skip <step>, I already know it", "I'm done with <step>".

## Section 5: quizzes and suggested reviews

**Prompt: type into your AI tool**
```
quiz me on <step, phase or "everything"> in <subject>
```

You pick a mode: easy (recall, with hints), hard (apply it, no hints), or expert
(exam-style scenarios and trade-offs). Afterwards it goes over the quiz with you one
question at a time: your answer, the grade, the explanation, and a discussion. If a
question shows a gap, it may offer to add a step to your plan; you can say no.

Quizzes at the end of a phase are offered, never required. Steps that went badly come back
later as suggested reviews:

**Prompt: type into your AI tool**
```
what is suggested for review
```

## Section 6: sources

Lessons cite the subject's listed sources, and say so when a point is not on the list. Add
a source of your own at any time:

**Prompt: type into your AI tool**
```
for <subject>: add this as a source: <link, book or file>
```

## Section 7: every subject at once

**Prompt: type into your AI tool**
```
show my subjects
```

One line per subject: status, steps done, lessons in progress, suggested reviews, target
date and last session. It shows status only; nothing from one subject appears in another.

## Section 8: the packet

Everything worth keeping from a subject is a packet of plain Markdown: the brief, sources,
plan, glossary, lessons, cheat sheets and quizzes, with an index page. Export it whenever
you like; exporting again refreshes it.

**Prompt: type into your AI tool**
```
export my <subject> packet
```

Expect: a folder under `packets` in your study root. It opens in any Markdown tool,
including a notes vault, and nothing in it depends on this plugin.

## Section 9: closing and reopening

When you are done with a subject, finished or not:

**Prompt: type into your AI tool**
```
close <subject>
```

It makes a final export and moves the subject to the archive, so your active list stays
short. To bring one back: "reopen <subject>".

## Section 10: resuming

Nothing needs saving. Name the subject and carry on:

**Prompt: type into your AI tool**
```
continue <subject>
```

Start a new chat each time you sit down to study. Everything the study partner needs is in
the subject's files, so a new chat loses nothing, and a long chat carried over many days
gets slower and less exact. Go back into an earlier chat only when you were cut off in the
middle of something, such as a quiz. Before you leave, say you are stopping, so the session
is written down:

**Prompt: type into your AI tool**
```
pause here
```

If the study partner has asked whether to keep a history of your study files and you said
yes, each sitting is saved as a checkpoint on your own computer, and you can ask for
earlier versions back. You can also ask for it at any time:

**Prompt: type into your AI tool**
```
turn on checkpoints for my study files
show me <file> as it was on <date>
undo today's changes to <subject>
```

It asks before bringing anything back, and it saves the present state first.
`references/checkpoints.md` has the detail. Checkpoints are not kept when the study root is
in a file-sync folder such as iCloud Drive or Dropbox, which keep their own copies.

On another machine, put the study root folder there with anything that keeps it an
ordinary folder (a sync service, a network share, a private git repository) and register
it once (section 12, `write-config.sh --register`). Work on a subject from one machine at a
time. If a subject was last worked on from another machine, or the same file was changed
in two places, the study partner says so when it next shows your subjects; "More than one
machine" in `references/config-keys.md` says what to do. In another AI tool that has this
skill, the same prompts work, because the state is in the files.

## Section 11: what is in a subject folder

| File or folder | What it is | Format reference |
|---|---|---|
| `brief.md` | Your mission, what done means, the target date, how you want to work | `references/brief-format.md` |
| `sources.md` | The authoritative sources | `references/sources-format.md` |
| `plan.md` | The study plan: phases and steps | `references/plan-format.md` |
| `lessons/` | One file per step, built up over time | `references/lesson-format.md` |
| `glossary.md` | The subject's terms | none |
| `sheets/` | Cheat sheets | none |
| `quizzes/` | Quizzes with your answers and the review | `references/quiz-format.md` |
| `materials/` | Files you supplied | none |
| `progress.md` | Working state: where every step stands, and a log of sessions | `references/progress-format.md` |

At the top of the study root: `study.config` (`references/config-keys.md`), `overview.md`
(`references/overview-format.md`), and the `packets` and `archive` folders
(`references/packet-format.md`). The reference files are inside the `study-partner` skill.

## Section 12: the scripts

They are in the `scripts` folder of the `study-partner` skill. The ones below only read,
except the last, which registers an existing study root on this machine and changes
nothing in it.

**Shell: run in your terminal**
```
bash <skill folder>/scripts/overview.sh --stdout
bash <skill folder>/scripts/reviews.sh
bash <skill folder>/scripts/pace.sh "<subject>"
bash <skill folder>/scripts/check-root.sh
bash <skill folder>/scripts/resolve-subject.sh "<subject>"
bash <skill folder>/scripts/write-config.sh --register <study root folder>
```

Expect: every subject on one line each; the steps suggested for review; how the remaining
steps sit against the target date; a health table; the folder of one subject.

`checkpoint.sh --status` says whether checkpoints are on, and `checkpoint.sh --list` shows
the ones saved; both only read.

`export-packet.sh "<subject>"` and `close-subject.sh "<subject>"` are also safe to run
yourself; the first changes nothing in the subject, the second moves it to the archive.

## Section 13: install and update

The plugin is installed from the TechTrip-AI-plugins catalog:

**Prompt: type into Claude Code**
```
/plugin marketplace add TechTripAi/TechTrip-AI-plugins
/plugin install techtrip-education@TechTrip-AI-plugins
```

Update with `/plugin update techtrip-education@TechTrip-AI-plugins`, then start a new
session. The README in the plugin repository has the update command for Copilot CLI and
every other tool, under "Updating". Your study files do not need updating when the plugin
does; if a release ever changes a file format, the study partner says so and offers to
bring the study root up to date.
