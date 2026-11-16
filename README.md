# techtrip-education

<p align="center">
  <img src="img/FellowshipOfTheAgents-bold-Education.png" alt="techtrip-education: a study partner for certifications, training and any topic, from TechTrip AI" width="100%" />
</p>

> **Status: currently under test as a first release, RC1 (version 0.2.0).** It works and is
> installable, but expect rough edges and changes while it is being tried on real study
> subjects. Reports of anything that goes wrong are welcome as issues on this repository.

**TechTrip AI's education skills, one plugin for the whole domain.** It starts with a study
partner for certifications, training and any topic you want to learn. It keeps its place in
every subject for as long as you study it, and picks up where you left off days later or
from a different AI tool. It is installed from the
[TechTrip-AI-plugins](https://github.com/TechTripAi/TechTrip-AI-plugins) catalog.

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

```
/plugin marketplace add TechTripAi/TechTrip-AI-plugins
/plugin install techtrip-education@TechTrip-AI-plugins
/techtrip-education:study-orientation
```

The first line registers the TechTrip catalog, the second installs the plugin, the third
starts its tour.

## Other AI tools

The two folders under `skills/` are plain Agent Skills, and `study-partner` carries its own
scripts, role guidance and format references, so it works in any tool that reads a skills
folder. One command installs both skills for Cursor, Codex, Gemini CLI and other tools:

```
npx skills add TechTripAi/techtrip-education -g
```

It asks which tools to install for. `-g` installs for your user account; leave it off to
install into the current project only. Requires Node.js. `npx skills update -g` picks up
later releases.

To install for one tool only:

- **Gemini CLI only.** Gemini CLI installs from the repository itself, into
  `~/.gemini/skills`, which no other tool reads:

  ```
  gemini skills install https://github.com/TechTripAi/techtrip-education.git --path skills
  ```

  Add `--scope workspace` to install into the current project only. Requires Gemini CLI
  0.68.0 or later.

- **Cursor only.** Name the tool with `-a`:

  ```
  npx skills add TechTripAi/techtrip-education -g -a cursor
  ```

  With `-g` the skills go to `~/.agents/skills`, a shared folder that other tools also
  read. To keep them to Cursor in one project, leave `-g` off and run the command in that
  project.

Gemini CLI uses its own authentication, which this plugin does not configure. Set it up
with a Gemini API key on a project that has billing enabled; the free tier's daily request
limit is too low for a planning session. See
[Google's API key instructions](https://ai.google.dev/gemini-api/docs/api-key). Never store
the key in a study root.

Do not keep a second copy of a skill in another skills directory; two copies leave the bare
name pointing at whichever loaded first.

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
/plugin update techtrip-education@TechTrip-AI-plugins
```

then `/reload-plugins` in a running session, or start a new one. In other tools, run
`npx skills update -g`.

## Developing

To work on the plugin, register a clone as its own marketplace. It then loads in place:
edits apply at the next session start or after `/reload-plugins`, with no version bump. Do
not keep this and the catalog install side by side.

```
git clone https://github.com/TechTripAi/techtrip-education.git
claude plugin marketplace add /path/to/techtrip-education
claude plugin install techtrip-education@techtrip-education
```

```
bash scripts/check.sh      # syntax, frontmatter, versions, manifest validation, tests
claude plugin validate .   # Claude Code's own manifest check
```

To try a clone in another tool, link its skill folders in place of the `npx` install:
`gemini skills link /path/to/techtrip-education/skills` for Gemini CLI (0.68.0 or later), or
symlink each folder under `skills/` into the tool's skills directory, such as
`~/.cursor/skills/`.

Maintainer conventions are in `docs/conventions.md`; decisions about this repository are in
`docs/decisions/`.

## No warranty

Provided as is. An AI can be wrong about your subject; lessons cite their sources so
you can check what matters.

## License

FSL-1.1-MIT (`LICENSE.md`): source-available, converts to MIT two years after each release.
Copyright 2026 Terry Trippany (Try AI Solutions).
