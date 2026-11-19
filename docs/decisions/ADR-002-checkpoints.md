# ADR-002: Checkpoints

Date: 2026-11-19. Status: accepted.

## Context

A study root is weeks of work in plain files, and the plugin had no protection against a
bad edit or a lost file beyond whatever the learner arranged. Some learners keep the root
in a git repository and commit by hand; many have never heard of git. The same root may
be used from several machines, through a sync service, a network share or a git remote.

## Decision

- **Checkpoints are a git history inside the study root, presented without git.** Text a
  learner sees says checkpoint, history and earlier version. Git is never required, and no
  text tells a learner to install it.
- **Opt-in, asked once.** `AUTO_CHECKPOINT` in `study.config` holds the answer: `1`, `0`,
  or absent for never asked. A no is recorded so the question is not repeated.
- **One checkpoint per sitting, not one per file write.** The skill saves when it records a
  session. That works in every AI tool, and it catches changes the scripts make through the
  shell, which a hook on file-editing tools would miss.
- **Hooks are a convenience on top.** Claude Code gets a session-start hook that passes on
  the scripts' notes and a session-end hook that saves a checkpoint as a safety net. They
  act only inside a study root.
- **No network.** Nothing pushes, pulls, fetches or adds a remote. "Behind the other
  machine" is not checked, because that needs the remote. The `Last machine` line in
  `progress.md` covers the case without it.
- **Sync service or checkpoints, not both.** A repository inside a folder that a sync
  service copies about can be corrupted, so `--enable` refuses in the folders it can
  recognise by name, and inside another repository. The list cannot be complete.
- **Bringing back never discards.** A restore saves the present state, checks the path out
  from the chosen checkpoint, and saves again. Files created since stay.

## Consequences

- A learner's own git identity is used when there is one; otherwise a name for that save
  only, so the first checkpoint cannot fail and no git configuration is written.
- A study root that is already a repository, with or without a remote, turns checkpoints on
  with one yes and keeps its history.
- A second machine that receives the root without its history (a share, or a copy) reports
  checkpoints as on and unable to save, until `--enable` is run there.
- Commit signing and commit hooks the learner has configured apply to checkpoints. If one
  refuses a save, the files are untouched and the next session's notes say changes are not
  yet saved.
