#!/usr/bin/env bash
# Close a subject: mark it closed in its brief, export its packet one final time, and move
# it out of the active subjects into <study root>/archive/, with a line in archive/index.md.
# A subject can be closed at any point, finished or not. Nothing is deleted.
# --reopen moves an archived subject back and marks it active again.
#
# Usage: close-subject.sh <subject ref or directory> [--date YYYY-MM-DD]
#        close-subject.sh --reopen <subject directory name> [--root <study root name>]
# Exit 1: bad usage. Exit 2/4: the subject did not resolve. Exit 3: the destination exists.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

ref=""; reopen=""; root=""; day=""
while [ $# -gt 0 ]; do
    case "$1" in
        --reopen) reopen="${2:-}"; shift 2 ;;
        --root) root="${2:-}"; shift 2 ;;
        --date) day="${2:-}"; shift 2 ;;
        -*) echo "close-subject: unknown option $1" >&2; exit 1 ;;
        *) ref="$1"; shift ;;
    esac
done
[ -n "$day" ] || day="$(today)"
index_line() { # <slug> <title> <what happened>
    mkdir -p "$ST_ARCHIVE"
    if [ ! -f "$ST_ARCHIVE/index.md" ]; then
        { echo "# Closed subjects"; echo; echo "| Subject | Title | When | What | Packet |"; echo "|---|---|---|---|---|"; } > "$ST_ARCHIVE/index.md"
    fi
    printf '| %s | %s | %s | %s | ../packets/%s/index.md |\n' "$1" "$(printf '%s' "$2" | tr '|' '/')" "$day" "$3" "$1" >> "$ST_ARCHIVE/index.md"
}
if [ -n "$reopen" ]; then
    open_root "$root" || exit 2
    slug="$(kebab "$reopen")"
    [ -d "$ST_ARCHIVE/$slug" ] || { echo "close-subject: no archived subject '$slug' in $STUDY_NAME" >&2; exit 1; }
    [ ! -e "$ST_SUBJECTS/$slug" ] || { echo "close-subject: $ST_SUBJECTS/$slug already exists" >&2; exit 3; }
    mkdir -p "$ST_SUBJECTS"
    mv "$ST_ARCHIVE/$slug" "$ST_SUBJECTS/$slug"
    set_brief_field "$ST_SUBJECTS/$slug" Status active
    index_line "$slug" "$(subject_title "$ST_SUBJECTS/$slug")" reopened
    echo "close-subject: reopened $STUDY_NAME:$slug"
    echo "$ST_SUBJECTS/$slug"
    exit 0
fi
[ -n "$ref" ] || { echo "usage: close-subject.sh <subject> | close-subject.sh --reopen <name>" >&2; exit 1; }
rc=0; sdir="$(resolve_subject "$ref")" || rc=$?
[ "$rc" -eq 0 ] || exit "$rc"
load_root_for "$sdir" || { echo "close-subject: no study root found for $sdir" >&2; exit 2; }
slug="$(basename "$sdir")"
[ ! -e "$ST_ARCHIVE/$slug" ] || { echo "close-subject: $ST_ARCHIVE/$slug already exists" >&2; exit 3; }
set_brief_field "$sdir" Status "closed $day"
packet="$(bash "$SCRIPT_DIR/export-packet.sh" "$sdir" --date "$day")"
title="$(subject_title "$sdir")"
mkdir -p "$ST_ARCHIVE"
mv "$sdir" "$ST_ARCHIVE/$slug"
index_line "$slug" "$title" closed
echo "close-subject: closed $STUDY_NAME:$slug"
echo "packet:  $packet"
echo "archive: $ST_ARCHIVE/$slug"
