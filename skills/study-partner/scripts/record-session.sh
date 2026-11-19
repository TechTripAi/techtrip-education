#!/usr/bin/env bash
# Stamp a subject's progress.md when a session is recorded: sets the "Last session" date in
# its header and the "Last machine" line beside it, which is how the next session, on any
# machine, can tell where the subject was last worked on. The session entry itself is
# written by the study partner; this script touches nothing but those two header lines.
#
# Usage: record-session.sh <subject ref or directory> [--date YYYY-MM-DD]
# Exit 1: bad usage, or progress.md has no "Last session" line. Exit 2/4: the subject did
# not resolve.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

ref=""; day=""
while [ $# -gt 0 ]; do
    case "$1" in
        --date) day="${2:-}"; shift 2 ;;
        -*) echo "record-session: unknown option $1" >&2; exit 1 ;;
        *) [ -z "$ref" ] && ref="$1" || { echo "record-session: one subject only" >&2; exit 1; }; shift ;;
    esac
done
[ -n "$ref" ] || { echo "usage: record-session.sh <subject ref or directory> [--date YYYY-MM-DD]" >&2; exit 1; }
[ -n "$day" ] || day="$(today)"
is_date "$day" || { echo "record-session: --date must be YYYY-MM-DD" >&2; exit 1; }
rc=0; sdir="$(resolve_subject "$ref")" || rc=$?
[ "$rc" -eq 0 ] || exit "$rc"
[ -f "$sdir/progress.md" ] || { echo "record-session: $sdir has no progress.md yet; run init-progress.sh" >&2; exit 1; }
grep -q '^\*\*Last session:\*\*' "$sdir/progress.md" || { echo "record-session: progress.md has no '**Last session:**' line" >&2; exit 1; }

me="$(this_machine)"
tmp="$sdir/progress.md.tmp.$$"
tr -d '\r' < "$sdir/progress.md" | RS_DAY="$day" RS_ME="$me" awk '
    BEGIN { s="**Last session:**"; m="**Last machine:**" }
    /^## / { body=1 }
    !body && index($0,s)==1 { print s " " ENVIRON["RS_DAY"]; print m " " ENVIRON["RS_ME"]; next }
    !body && index($0,m)==1 { next }
    { print }' > "$tmp" || { rm -f "$tmp"; echo "record-session: could not update progress.md; it is unchanged" >&2; exit 1; }
mv "$tmp" "$sdir/progress.md"
echo "record-session: $(basename "$sdir") last session $day on $me"
