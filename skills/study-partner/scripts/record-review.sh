#!/usr/bin/env bash
# Record how a review or a quiz question on one step went, and set when that step is next
# suggested for review. It never changes the step's status.
#   pass  it went well: up one level, next suggested after that level's interval;
#         after the last level no further review is suggested
#   fail  it went badly: back to level 1, next suggested after the first interval
# The intervals are REVIEW_INTERVALS in study.config (days). A suggested review is an offer.
#
# Usage: record-review.sh <subject ref or directory> <step id> pass|fail [--date YYYY-MM-DD]
# Exit 1: bad usage or unknown step. Exit 2/4: the subject did not resolve.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

[ $# -ge 3 ] || { echo "usage: record-review.sh <subject> <step id> pass|fail [--date YYYY-MM-DD]" >&2; exit 1; }
ref="$1"; id="$(norm_step "$2")"; result="$3"; day=""
shift 3
while [ $# -gt 0 ]; do case "$1" in --date) day="${2:-}"; shift 2 ;; *) echo "record-review: unknown option $1" >&2; exit 1 ;; esac; done
case "$result" in pass|fail) ;; *) echo "record-review: result is pass or fail" >&2; exit 1 ;; esac
rc=0; sdir="$(resolve_subject "$ref")" || rc=$?
[ "$rc" -eq 0 ] || exit "$rc"
[ -f "$sdir/progress.md" ] || { echo "record-review: $sdir has no progress.md; run init-progress.sh first" >&2; exit 1; }
load_root_for "$sdir" || true
[ -n "$day" ] || day="$(today)"
step_rows "$sdir" | cut -f1 | grep -qx "$id" || { echo "record-review: no step $id in $sdir/progress.md" >&2; exit 1; }
: "${REVIEW_INTERVALS:=1 3 7 14 30}"
tmp="$sdir/progress.md.tmp.$$"
tr -d '\r' < "$sdir/progress.md" | awk -F'|' -v id="$id" -v res="$result" -v day="$day" -v iv="$REVIEW_INTERVALS" "$AWK_DATES"'
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    BEGIN { n=split(iv,ivs," "); base=ymd(day) }
    $0 ~ /^\| *[A-Z]+[0-9]+ *\|/ && trim($2)==id {
        level=trim($7)+0
        if (res=="pass") level=level+1; else level=1
        if (res=="pass" && level>n) { level=n; nxt="-" } else nxt=n2d(base+ivs[level])
        printf "| %s | %s | %s | %s | %s | %d | %s | %s | %s |\n", id, trim($3), trim($4), trim($5), trim($6), level, day, nxt, trim($10)
        next }
    { print }' > "$tmp"
mv "$tmp" "$sdir/progress.md"
step_rows "$sdir" | awk -F'\t' -v id="$id" '$1==id { printf "%s  %s: level %s, next suggested review %s\n", $1, $4, $6, $8 }'
