#!/usr/bin/env bash
# List the steps suggested for review, across every active subject or in one subject.
# A step is suggested when its "Next review" date is on or before the day asked about.
# These are offers; nothing depends on taking them.
#
# Usage: reviews.sh [--root <study root name>] [--subject <subject ref>] [--date YYYY-MM-DD]
# Prints one line per suggested step, oldest first, then one summary line per subject.
# Exit 2: no study root, or the subject did not resolve.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

root=""; sub=""; day=""
while [ $# -gt 0 ]; do
    case "$1" in
        --root) root="${2:-}"; shift 2 ;;
        --subject) sub="${2:-}"; shift 2 ;;
        --date) day="${2:-}"; shift 2 ;;
        *) echo "reviews: unknown option $1" >&2; exit 1 ;;
    esac
done
[ -n "$day" ] || day="$(today)"
if [ -n "$sub" ]; then
    rc=0; one="$(resolve_subject "$sub")" || rc=$?
    [ "$rc" -eq 0 ] || exit "$rc"
    dirs="$one"
else
    open_root "$root" || exit 2
    dirs="$(for d in "$ST_SUBJECTS"/*/; do [ -f "${d}brief.md" ] && printf '%s\n' "${d%/}"; done)"
fi
tab="$(printf '\t')"
due="$(printf '%s\n' "$dirs" | sed '/^$/d' | while IFS= read -r d; do
    step_rows "$d" | awk -F'\t' -v day="$day" -v c="$(basename "$d")" '$8!="-" && $8!="" && ($8"" <= day"") { printf "%s\t%s\t%s\t%s\t%s\n", $8, c, $1, $4, $6 }'
done | sort)"
echo "Suggested reviews on or before $day:"
if [ -z "$due" ]; then echo "  none"
else printf '%s\n' "$due" | while IFS="$tab" read -r nxt c id title level; do
        printf '  %s  %-22s %-5s %s (level %s)\n' "$nxt" "$c" "$id" "$title" "$level"
    done
fi
echo
echo "By subject:"
printf '%s\n' "$dirs" | sed '/^$/d' | while IFS= read -r d; do
    step_rows "$d" | awk -F'\t' -v day="$day" -v c="$(basename "$d")" '
        { total++; if ($5=="done") done++; if ($5=="in progress") open++; if ($8!="-" && $8!="" && ($8"" <= day"")) due++ }
        END { printf "  %-22s %d suggested, %d in progress, %d done of %d steps\n", c, due+0, open+0, done+0, total+0 }'
done
