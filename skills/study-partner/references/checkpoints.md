# Checkpoints

A checkpoint is a saved copy of the whole study root, kept in a history inside it, so an
earlier version of any file can be looked at or brought back. They are off until the
learner says yes. Git is the engine underneath. The learner never has to know that: say
"checkpoint", "history" and "earlier version", and use a git word only if they do first.

`checkpoint.sh` does all of it. It never pushes, pulls or contacts another machine, and it
never deletes a file from the study root.

## The offer, once

`overview.sh` prints one `overview: offer:` line while checkpoints could be kept and the
learner has not been asked. Ask once, at a natural pause and not in the middle of what
they came to do, in words like these:

> Do you want me to keep a history of your study files, so an earlier version of anything
> can be brought back? It stays on this computer, inside your study folder.

| They say | Run |
|---|---|
| Yes | `checkpoint.sh --enable` |
| No, or they pass over the question | `checkpoint.sh --disable`, which records the answer so it is not asked again |

There is no offer line, and nothing to say, when checkpoints cannot be kept: git is not
installed, the study root is inside a file-sync folder, or it is inside a larger folder
that already keeps its own history. Never tell a learner to install anything for this. If
they ask for checkpoints and `--enable` says why not, pass the reason on as it is written.
A study root uses a file-sync service or checkpoints, not both.

A learner can turn them on or off at any time by asking.

## Saving

After recording a session, run `checkpoint.sh --message "<subject>: <what was done, in one
line>"`. It saves when checkpoints are on and something changed, and otherwise says so and
does nothing. Where the AI tool runs the plugin's session hooks, one is also saved when a
session closes without being recorded.

## Looking back and bringing back

| The learner asks | Run |
|---|---|
| What checkpoints are there; when did this file change | `checkpoint.sh --list [<path>]` |
| Show me this file as it was last week | `checkpoint.sh --show <path> --at <YYYY-MM-DD or id>`, and show them the result |
| Put this file back the way it was; undo today's changes | `checkpoint.sh --restore <path> --at <YYYY-MM-DD or id>` |

`<path>` is relative to the study root; `.` is all of it. A date means the last checkpoint
saved on or before that day, so "undo today's changes" is `--restore . --at <yesterday>`.
An id is the first column of `--list`.

Before bringing anything back, say which checkpoint it will come from and what will
change, and wait for a yes. `--restore` saves the present state first and saves the result
after, so a restore can itself be undone, and files created since are left where they are.
Do not bring back a single step row or session entry by hand: restore the file, or show
the earlier version and let the learner say what they want from it.

## States

`checkpoint.sh --status` prints one line.

| Status | Meaning |
|---|---|
| `on` | Saving. |
| `off` | The learner said no. Not offered again. |
| `not-asked` | Could be kept; the offer is open. |
| `unavailable` | Never turned on, and cannot be kept here. The line says why. |
| `broken` | Turned on, and cannot be saved on this machine: git is missing here, or this copy of the folder has no history. `overview.sh` notes it. `--enable` mends a missing history. |

## More than one machine

A history can be shared by someone who already uses git: they add their own remote and
push and pull themselves. The scripts never do, and never suggest it to a learner who has
not raised it. When saved checkpoints have not been sent, `overview.sh` says so.
