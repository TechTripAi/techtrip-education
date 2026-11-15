# The packet

Everything a subject produces that is worth keeping, as plain Markdown with relative links.
It builds up as the subject is studied, because each piece is written as a clean file when
it is made. `export-packet.sh` copies it out.

```
packets/<subject>/
  index.md        generated: status, target date, and links to everything below
  brief.md        the mission and what done means
  sources.md      the authoritative sources
  plan.md         the study plan
  glossary.md
  lessons/        every lesson file, finished or not
  sheets/         cheat sheets
  quizzes/        quizzes, with answers, grades and review notes
  materials/      files the learner supplied
```

Not in the packet: `progress.md`, which is working state.

| Action | Command | Effect |
|---|---|---|
| Export or refresh at any time | `export-packet.sh "<subject>" [--to <directory>]` | Copies the files above to `<study root>/packets/<subject>/`, or to the directory given, and rewrites `index.md`. Run it as often as wanted; it refreshes the same folder. The subject is untouched. |
| Close a subject | `close-subject.sh "<subject>"` | Marks the brief `closed`, runs the export one final time, moves the subject to `<study root>/archive/<subject>/`, and adds a line to `archive/index.md`. A subject can be closed at any point, finished or not. |
| Reopen | `close-subject.sh --reopen <subject>` | Moves it back to the active subjects and marks it `active`. |

The packet is a folder of Markdown files, so it opens in any Markdown tool, including a
notes vault, reads on a code host, and prints. Nothing in it depends on this plugin.

An unfinished lesson is exported as it stands; the index shows each step's status at the
time of the export.
