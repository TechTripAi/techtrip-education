#!/usr/bin/env bash
# Set the status of a step or a checkpoint in a subject's progress.md.
#   A step:        pending | started | done | skipped | deferred
#   A checkpoint:  pending | taken | skipped        (checkpoint ids look like CP-A)
# "started" is written as "in progress". A step closes when the learner says so; nothing
# else changes its status. --note records a reason, for example why a step was skipped.
#
# Usage: set-step.sh <subject ref or directory> <step or checkpoint id> <status> [--note "<text>"] [--date YYYY-MM-DD]
# Exit 1: bad usage or unknown id. Exit 2/4: the subject did not resolve.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

[ $# -ge 3 ] || { echo 'usage: set-step.sh <subject> <step or checkpoint id> <status> [--note "<text>"] [--date YYYY-MM-DD]' >&2; exit 1; }
ref="$1"; id="$(norm_step "$2")"; status="$3"; note=""; has_note=0; day=""
shift 3
while [ $# -gt 0 ]; do
    case "$1" in
        --note) note="${2:-}"; has_note=1; shift 2 ;;
        --date) day="${2:-}"; shift 2 ;;
        *) echo "set-step: unknown option $1" >&2; exit 1 ;;
    esac
done
rc=0; sdir="$(resolve_subject "$ref")" || rc=$?
[ "$rc" -eq 0 ] || exit "$rc"
[ -f "$sdir/progress.md" ] || { echo "set-step: $sdir has no progress.md; run init-progress.sh first" >&2; exit 1; }
[ -n "$day" ] || day="$(today)"
note="$(printf '%s' "$note" | tr '|\n' '/ ')"
tmp="$sdir/progress.md.tmp.$$"
case "$id" in
    CP-*)
        case "$status" in pending) val="pending" ;; taken) val="taken $day" ;; skipped) val="skipped $day" ;;
            *) echo "set-step: a checkpoint is pending, taken or skipped" >&2; exit 1 ;; esac
        checkpoint_rows "$sdir" | cut -f1 | grep -qx -- "$id" || { echo "set-step: no checkpoint $id in $sdir/progress.md" >&2; exit 1; }
        tr -d '\r' < "$sdir/progress.md" | awk -F'|' -v id="$id" -v val="$val" '
            function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
            $0 ~ /^\| *CP-[A-Z]+ *\|/ && trim($2)==id { printf "| %s | %s | %s |\n", id, trim($3), val; next } { print }' > "$tmp"
        mv "$tmp" "$sdir/progress.md"
        echo "$id: $val"
        ;;
    *)
        case "$status" in pending) val="pending" ;; started|in-progress|"in progress") val="in progress" ;; done) val="done" ;; skipped) val="skipped" ;; deferred) val="deferred" ;;
            *) echo "set-step: a step is pending, started, done, skipped or deferred" >&2; exit 1 ;; esac
        step_rows "$sdir" | cut -f1 | grep -qx "$id" || { echo "set-step: no step $id in $sdir/progress.md" >&2; exit 1; }
        tr -d '\r' < "$sdir/progress.md" | awk -F'|' -v id="$id" -v val="$val" -v day="$day" -v note="$note" -v hn="$has_note" '
            function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
            $0 ~ /^\| *[A-Z]+[0-9]+ *\|/ && trim($2)==id {
                last=(val=="pending" ? trim($8) : day); n=(hn=="1" ? note : trim($10))
                printf "| %s | %s | %s | %s | %s | %s | %s | %s | %s |\n", id, trim($3), trim($4), trim($5), val, trim($7), last, trim($9), n; next }
            { print }' > "$tmp"
        mv "$tmp" "$sdir/progress.md"
        step_rows "$sdir" | awk -F'\t' -v id="$id" '$1==id { printf "%s  %s: %s%s\n", $1, $4, $5, ($9!="" ? " (" $9 ")" : "") }'
        ;;
esac
