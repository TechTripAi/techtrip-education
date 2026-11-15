# techtrip-education

<p align="center">
  <img src="img/FellowshipOfTheAgents.png" alt="techtrip-education" width="100%" />
</p>

**Pre-release. Private. Not yet in the TechTrip catalog.** TechTrip AI's education skills,
one plugin for the whole domain. It starts with a study partner for certifications,
training and any topic you want to learn. It keeps its place in every subject for as long
as you study it, and picks up where you left off days later or from a different AI tool. It
will be listed in [TechTrip-AI-plugins](https://github.com/TechTripAi/TechTrip-AI-plugins)
when it is ready to ship; until then it is installed from a local checkout.

## How it works

A subject is anything you are studying. Each one is a folder of plain files on your disk,
independent of every other subject.

**It plans first.** Give it a spec, a syllabus or an exam guide, or just name a topic. It
settles three things with you before any teaching:

- **your mission:** why you are studying this, and what done means, with an optional target
  date that is open-ended by default
- **the sources:** a list of authoritative sources you approve, and can add to at any time
- **the study plan:** phases of small steps, each marked Learn or Apply

**Then it works the plan with you.** Each step has its own lesson file that builds up over
time. You can take steps in any order, have several lessons open, skip any step, and stop
whenever you like.

**Quizzes are offered, never forced.** Pick easy, hard or expert. The review goes one
question at a time, and anything it turns up is offered back into your plan for you to
accept or decline.

**It builds a packet as you go.** The brief, sources, plan, glossary, lessons, cheat sheets
and quizzes are plain Markdown. Export the packet at any time; closing a subject makes a
final export and archives it. The packet opens in any Markdown tool.

You talk in plain words, or pick from the short menus it shows:

- "I want to study Rust, plan it from scratch"
- "I'm studying for the AWS exam, here is the exam guide"
- "let's study aws"
- "quiz me on phase A, hard"
- "add this book as a source"
- "show my subjects"
- "export my aws packet"

How you use it is up to you. The plugin sets no limits on the kind of help you ask for.

## Skills included

- **`study-partner`**: everything above. Works out the subject and the kind of help from
  what you say, reads only that subject, does the work, and records where things stand.
  Try "let's set up my study partner", or `/study-partner`.
- **`study-orientation`**: a menu-style tour that hands you the prompts to type and never
  runs anything. Try "give me the study tour", or `/techtrip-education:study-orientation`.

## Install

Until the plugin is listed in the catalog there is one route for Claude Code: clone the
private repo and register the checkout as its own marketplace. The plugin then loads **in
place**: edits apply at the next session start or after `/reload-plugins`, with no version
bump.

```
git clone git@github.com:TechTripAi/techtrip-education.git
claude plugin marketplace add /path/to/techtrip-education
claude plugin install techtrip-education@techtrip-education
```

Once it is released, the install is the same as every TechTrip plugin:

```
/plugin marketplace add TechTripAi/TechTrip-AI-plugins
/plugin install techtrip-education@TechTrip-AI-plugins
/techtrip-education:study-orientation
```

## Other AI tools

The two folders under `skills/` are plain Agent Skills, and `study-partner` carries its own
scripts, role guidance and format references, so it works wherever a skill folder can be
linked or copied.

```
mkdir -p ~/.cursor/skills
for s in study-partner study-orientation; do
  ln -s /path/to/techtrip-education/skills/$s ~/.cursor/skills/$s
done
```

For Gemini CLI: `gemini skills link /path/to/techtrip-education/skills`. Do not keep a
second copy of a skill in another skills directory; two copies leave the bare name pointing
at whichever loaded first.

A study root set up in one tool works in the others. Its files are plain text, and the
registry of study roots (`~/.study-roots`) is per user, not per tool.

To use one study root from several machines, sync its folder with any tool (a private git
repository works well) and run `write-config.sh --register <folder>` once on each machine.
Work on a subject from one machine at a time. If a file was changed in two places, the
study partner reports it and stops nothing.

## What it writes

Only inside the study root you choose: `study.config`, `overview.md`, the subject folders,
and the `packets` and `archive` folders. Plus one line per study root in `~/.study-roots`. Nothing leaves your machine, and
no secret is ever written to a file.

## Requirements

`bash`, `awk`, `sed`, `grep`, `sort`. macOS and Linux; Windows through Git Bash while the
CI matrix is green.

## Updating

```
git -C /path/to/techtrip-education pull
```

then `/reload-plugins` in a running session, or start a new one.

## Developing

```
bash scripts/check.sh      # syntax, frontmatter, versions, manifest validation, tests
claude plugin validate .   # Claude Code's own manifest check
```

Maintainer conventions are in `docs/conventions.md`; decisions about this repository are in
`docs/decisions/`.

## No warranty

Provided as is. An AI can be wrong about your subject; lessons cite their sources so
you can check what matters.

## License

FSL-1.1-MIT (`LICENSE.md`): source-available, converts to MIT two years after each release.
Copyright 2026 Terry Trippany (Try AI Solutions).
