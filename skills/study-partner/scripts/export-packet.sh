#!/usr/bin/env bash
# Export a subject's packet as plain Markdown: the brief, the sources, the study plan, the
# glossary, every lesson, the cheat sheets, the quizzes and the materials, plus a generated
# index.md that links them. The working state (progress.md) is not part of the packet.
# Run it at any time; it refreshes the same folder. Nothing in the subject is changed and
# nothing is deleted.
#
# Usage: export-packet.sh <subject ref or directory> [--to <directory>] [--date YYYY-MM-DD]
#   Default destination: <study root>/packets/<subject>/
# Prints the packet directory. Exit 1: bad usage. Exit 2/4: the subject did not resolve.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

ref=""; dest=""; day=""
while [ $# -gt 0 ]; do
    case "$1" in
        --to) dest="${2:-}"; shift 2 ;;
        --date) day="${2:-}"; shift 2 ;;
        -*) echo "export-packet: unknown option $1" >&2; exit 1 ;;
        *) ref="$1"; shift ;;
    esac
done
[ -n "$ref" ] || { echo "usage: export-packet.sh <subject> [--to <directory>]" >&2; exit 1; }
rc=0; sdir="$(resolve_subject "$ref")" || rc=$?
[ "$rc" -eq 0 ] || exit "$rc"
load_root_for "$sdir" || true
[ -n "$day" ] || day="$(today)"
slug="$(basename "$sdir")"
if [ -z "$dest" ]; then
    [ -n "${ST_PACKETS:-}" ] || { echo "export-packet: no study root found for $sdir; pass --to <directory>" >&2; exit 1; }
    dest="$ST_PACKETS/$slug"
fi
mkdir -p "$dest"
dest="$(cd "$dest" && pwd)"
for f in brief.md sources.md plan.md glossary.md; do
    [ -f "$sdir/$f" ] && cp "$sdir/$f" "$dest/$f"
done
for d in lessons sheets quizzes materials; do
    if [ -d "$sdir/$d" ] && [ -n "$(ls -A "$sdir/$d" 2>/dev/null)" ]; then
        mkdir -p "$dest/$d"; cp -R "$sdir/$d/." "$dest/$d/"
    fi
done
tab="$(printf '\t')"
link_list() { # <folder>: one bullet per Markdown file in the packet folder
    [ -d "$dest/$1" ] || { echo "- none"; return 0; }
    found=0
    for f in "$dest/$1"/*; do
        [ -f "$f" ] || continue
        found=1; b="$(basename "$f")"
        printf -- '- [%s](%s/%s)\n' "$b" "$1" "$(printf '%s' "$b" | sed 's/ /%20/g')"
    done
    [ "$found" -eq 1 ] || echo "- none"
}
{
    echo "# $(subject_title "$sdir"): packet"
    echo
    echo "**Exported:** $day"
    echo "**Status:** $(brief_field "$sdir" Status)"
    echo "**Target date:** $(brief_field "$sdir" "Target date")"
    echo
    echo "## Contents"
    echo
    for f in brief.md sources.md plan.md glossary.md; do
        [ -f "$dest/$f" ] || continue
        case "$f" in brief.md) label="Brief and mission" ;; sources.md) label="Sources" ;; plan.md) label="Study plan" ;; *) label="Glossary" ;; esac
        printf -- '- [%s](%s)\n' "$label" "$f"
    done
    echo
    echo "## Lessons"
    echo
    rows="$(step_rows "$sdir")"
    if [ -z "$rows" ]; then link_list lessons
    else
        echo "| Step | Kind | Title | Status | Lesson |"
        echo "|---|---|---|---|---|"
        printf '%s\n' "$rows" | while IFS="$tab" read -r id ph kind title status level last nxt note; do
            lf=""
            for f in "$dest/lessons/$id"-*.md; do [ -f "$f" ] && lf="$(basename "$f")" && break; done
            if [ -n "$lf" ]; then cellv="[$lf](lessons/$lf)"; else cellv="-"; fi
            printf '| %s | %s | %s | %s | %s |\n' "$id" "$kind" "$title" "$status" "$cellv"
        done
    fi
    echo
    echo "## Cheat sheets"
    echo
    link_list sheets
    echo
    echo "## Quizzes"
    echo
    link_list quizzes
    echo
    echo "## Materials"
    echo
    link_list materials
} > "$dest/index.md"
printf '%s\n' "$dest"
