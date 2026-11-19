#!/usr/bin/env bash
# Rebuild the study root's overview.md: one line per active subject, read from each
# subject's brief.md header and its progress.md. Status only. It is the one view across
# subjects, and it never opens a subject's lessons, sources or quizzes.
#
# Usage: overview.sh [--root <study root name>] [--date YYYY-MM-DD] [--stdout]
#   --stdout prints the overview and writes nothing.
# When the study root shows signs of having been changed in two places, holds work another
# machine cannot see yet, or is in a different format from the one these scripts write, it
# says so in "overview: note:" lines on stderr. They are information; the overview is
# written all the same. One "overview: offer:" line appears while checkpoints could be kept
# for this study root and the learner has not yet been asked.
# Exit 2: no study root.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

root=""; day=""; to_stdout=0
while [ $# -gt 0 ]; do
    case "$1" in
        --root) root="${2:-}"; shift 2 ;;
        --date) day="${2:-}"; shift 2 ;;
        --stdout) to_stdout=1; shift ;;
        *) echo "overview: unknown option $1" >&2; exit 1 ;;
    esac
done
[ -n "$day" ] || day="$(today)"
open_root "$root" || exit 2
cell() { v="$(printf '%s' "$1" | tr '|' '/' | tr '\n' ' ')"; [ -n "$v" ] && printf '%s' "$v" || printf '%s' "-"; }
tab="$(printf '\t')"

out="$( {
    echo "# Study overview: $STUDY_NAME"
    echo
    echo "**Updated:** $day"
    echo
    echo "| Subject | Title | Status | Steps done | In progress | Suggested reviews | Target date | Last session |"
    echo "|---|---|---|---|---|---|---|---|"
    n=0
    for d in "$ST_SUBJECTS"/*/; do
        [ -f "${d}brief.md" ] || continue
        d="${d%/}"; n=$((n + 1))
        counts="$(step_rows "$d" | awk -F'\t' -v day="$day" '
            { total++; if ($5=="done") done++; if ($5=="in progress") open++; if ($8!="-" && $8!="" && ($8"" <= day"")) due++ }
            END { printf "%d of %d\t%d\t%d", done+0, total+0, open+0, due+0 }')"
        done_of="$(printf '%s' "$counts" | cut -f1)"; open="$(printf '%s' "$counts" | cut -f2)"; due="$(printf '%s' "$counts" | cut -f3)"
        if [ ! -f "$d/plan.md" ]; then done_of="no plan yet"; open="-"; due="-"; fi
        printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' \
            "$(basename "$d")" "$(cell "$(subject_title "$d")")" "$(cell "$(brief_field "$d" Status)")" \
            "$done_of" "$open" "$due" "$(cell "$(brief_field "$d" "Target date")")" \
            "$(cell "$(progress_field "$d" "Last session")")"
    done
    [ "$n" -gt 0 ] || { echo; echo "No active subjects."; }
    if [ -f "$ST_ARCHIVE/index.md" ]; then
        echo; echo "Closed subjects are listed in archive/index.md."
    fi
} )"
if [ "$to_stdout" -eq 1 ]; then printf '%s\n' "$out"
else printf '%s\n' "$out" > "$ST_ROOT/overview.md"; echo "overview: wrote $ST_ROOT/overview.md"; fi
cps="$(cp_state)"
{ format_note; sync_notes "$ST_ROOT" | cut -f2
  case "$cps" in broken*) printf 'checkpoints are turned on for this study root and cannot be saved here: %s\n' "$(printf '%s' "$cps" | cut -f3)" ;; esac
} | sed 's/^/overview: note: /' >&2
if [ "$cps" = not-asked ]; then
    echo "overview: offer: checkpoints (a history of the study files, so earlier versions can be brought back) can be kept for this study root, and the learner has not been asked yet" >&2
fi
