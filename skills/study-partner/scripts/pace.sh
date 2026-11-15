#!/usr/bin/env bash
# Show how the remaining steps of a subject sit against its target date. Information only:
# it changes nothing, and a date that has passed is reported as a plain fact.
# With no target date the subject is open-ended and only the step counts are shown.
# --steps and --target work out a pace for a plan that is not written yet.
#
# Usage: pace.sh <subject ref or directory> [--date YYYY-MM-DD]
#        pace.sh --steps <number of steps> --target YYYY-MM-DD [--date YYYY-MM-DD]
# Exit 1: bad usage. Exit 2/4: the subject did not resolve.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

ref=""; day=""; steps=""; target=""
while [ $# -gt 0 ]; do
    case "$1" in
        --date) day="${2:-}"; shift 2 ;;
        --steps) steps="${2:-}"; shift 2 ;;
        --target) target="${2:-}"; shift 2 ;;
        -*) echo "pace: unknown option $1" >&2; exit 1 ;;
        *) ref="$1"; shift ;;
    esac
done
[ -n "$day" ] || day="$(today)"
if [ -n "$steps" ]; then
    case "$steps" in *[!0-9]*|"") echo "pace: --steps is a whole number" >&2; exit 1 ;; esac
    is_date "$target" || { echo "pace: --target is a date as YYYY-MM-DD" >&2; exit 1; }
    remaining="$steps"; total="$steps"
else
    [ -n "$ref" ] || { echo "usage: pace.sh <subject> | pace.sh --steps <n> --target YYYY-MM-DD" >&2; exit 1; }
    rc=0; sdir="$(resolve_subject "$ref")" || rc=$?
    [ "$rc" -eq 0 ] || exit "$rc"
    target="$(brief_field "$sdir" "Target date")"
    counts="$(step_rows "$sdir" | awk -F'\t' '{ total++; if ($5!="done" && $5!="skipped") rem++ } END { printf "%d %d", rem+0, total+0 }')"
    remaining="${counts% *}"; total="${counts#* }"
    if [ "$total" -eq 0 ]; then
        total="$(plan_steps "$sdir" | sed '/^$/d' | wc -l | tr -d ' ')"; remaining="$total"
    fi
fi
if ! is_date "$target"; then
    echo "Target date: none (open-ended)."
    echo "$remaining of $total steps remaining."
    exit 0
fi
days="$(days_between "$day" "$target")"
echo "Target date: $target."
echo "$remaining of $total steps remaining."
if [ "$days" -gt 0 ] && [ "$remaining" -gt 0 ]; then
    awk -v r="$remaining" -v d="$days" 'BEGIN {
        w=d/7; per=r/w; if (per < 1) { every=int(w/r); printf "%d days left: about one step every %d week%s.\n", d, every, (every==1?"":"s") }
        else { p=int(per); if (per>p) p++; printf "%d days left: about %d step%s a week.\n", d, p, (p==1?"":"s") } }'
elif [ "$days" -gt 0 ]; then
    echo "$days days left."
fi
