#!/usr/bin/env bash
# Create a subject directory in a study root: brief.md, sources.md, glossary.md, and the
# lessons/, sheets/, quizzes/ and materials/ folders. plan.md is not created here; the study
# partner writes it after the brief and the sources are settled, and its existence is what
# marks a subject as planned.
#
# Usage: new-subject.sh "<Subject title>" [--slug <name>] [--kind certification|training|topic]
#                       [--target YYYY-MM-DD] [--root <study root name>]
# Exit 1: bad usage. Exit 2: no study root. Exit 3: the subject already exists (active or archived).
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

title=""; slug=""; kind="topic"; target="none"; root=""
while [ $# -gt 0 ]; do
    case "$1" in
        --slug) slug="${2:-}"; shift 2 ;;
        --kind) kind="${2:-}"; shift 2 ;;
        --target) target="${2:-}"; shift 2 ;;
        --root) root="${2:-}"; shift 2 ;;
        -*) echo "new-subject: unknown option $1" >&2; exit 1 ;;
        *) [ -z "$title" ] && title="$1" || { echo "new-subject: quote the title" >&2; exit 1; }; shift ;;
    esac
done
[ -n "$title" ] || { echo 'usage: new-subject.sh "<Subject title>" [--slug <name>] [--kind ...] [--target YYYY-MM-DD] [--root <name>]' >&2; exit 1; }
case "$kind" in certification|training|topic) ;; *) echo "new-subject: --kind is certification, training or topic" >&2; exit 1 ;; esac
[ "$target" = none ] || is_date "$target" || { echo "new-subject: --target is a date as YYYY-MM-DD" >&2; exit 1; }
open_root "$root" || exit 2
[ -n "$slug" ] || slug="$title"
slug="$(kebab "$slug")"
[ -n "$slug" ] || { echo "new-subject: could not make a directory name from '$title'" >&2; exit 1; }
sdir="$ST_SUBJECTS/$slug"
[ ! -e "$sdir" ] || { echo "new-subject: $sdir already exists" >&2; exit 3; }
[ ! -e "$ST_ARCHIVE/$slug" ] || { echo "new-subject: '$slug' is archived; reopen it with close-subject.sh --reopen $slug" >&2; exit 3; }
mkdir -p "$sdir/lessons" "$sdir/sheets" "$sdir/quizzes" "$sdir/materials"
cat > "$sdir/brief.md" <<BRIEF
# $title

**Subject:** $slug
**Status:** active
**Kind:** $kind
**Started:** $(today)
**Target date:** $target

## Mission

## Done means

## Where the plan came from

## How I want to work
BRIEF
cat > "$sdir/sources.md" <<SOURCES
# $title: sources

| Id | Source | Kind | Why it is trusted | Version | Added |
|---|---|---|---|---|---|
SOURCES
cat > "$sdir/glossary.md" <<GLOSSARY
# $title: glossary

| Term | Meaning | First used |
|---|---|---|
GLOSSARY
echo "subject ref: $STUDY_NAME:$slug"
echo "$sdir"
