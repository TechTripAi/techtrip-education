#!/usr/bin/env bash
# Open the lesson file for a step. Creates lessons/<id>-<title>.md with its header taken
# from the plan if it does not exist yet, marks a pending step as in progress, and prints
# the file's path. An existing lesson file is never changed.
#
# Usage: open-lesson.sh <subject ref or directory> <step id>
# Exit 1: bad usage or unknown step. Exit 2/4: the subject did not resolve.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

[ $# -ge 2 ] || { echo "usage: open-lesson.sh <subject> <step id>" >&2; exit 1; }
rc=0; sdir="$(resolve_subject "$1")" || rc=$?
[ "$rc" -eq 0 ] || exit "$rc"
id="$(norm_step "$2")"
[ -f "$sdir/plan.md" ] || { echo "open-lesson: $sdir has no plan.md yet" >&2; exit 1; }
row="$(plan_steps "$sdir" | awk -F'\t' -v id="$id" '$1==id')"
[ -n "$row" ] || { echo "open-lesson: no step $id in $sdir/plan.md" >&2; exit 1; }
kind="$(printf '%s' "$row" | cut -f3)"
detail="$(plan_step_detail "$sdir" "$id")"
title="$(printf '%s\n' "$detail" | sed -n 1p)"
donewhen="$(printf '%s\n' "$detail" | sed -n 2p)"
sources="$(printf '%s\n' "$detail" | sed -n 3p)"
mkdir -p "$sdir/lessons"
existing=""
for f in "$sdir/lessons/$id"-*.md; do [ -f "$f" ] && existing="$f" && break; done
if [ -z "$existing" ]; then
    existing="$sdir/lessons/$id-$(kebab "$title").md"
    cat > "$existing" <<LESSON
# $id: $title

**Step:** $id [$kind]
**Done when:** ${donewhen:--}
**Sources:** ${sources:--}
**Stopped at:** not started

## Try it

## Parked questions

## Reviews
LESSON
fi
if [ -f "$sdir/progress.md" ]; then
    st="$(step_rows "$sdir" | awk -F'\t' -v id="$id" '$1==id {print $5}')"
    if [ "$st" = pending ]; then bash "$SCRIPT_DIR/set-step.sh" "$sdir" "$id" started >/dev/null; fi
fi
printf '%s\n' "$existing"
