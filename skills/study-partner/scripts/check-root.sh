#!/usr/bin/env bash
# Health check for a study root. Read-only. One PASS/WARN/FAIL row per check.
#
# Usage: check-root.sh [<directory> | --root <study root name>]
# Exit 1: at least one FAIL. Exit 2: no study root found.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

fails=0
row() { printf '%-5s %-28s %s\n' "$1" "$2" "$3"; [ "$1" = FAIL ] && fails=$((fails + 1)) || true; }
if [ "${1:-}" = "--root" ]; then open_root "${2:-}" || exit 2
elif [ -n "${1:-}" ]; then
    [ -f "$1/study.config" ] || { echo "check-root: no study.config in $1" >&2; exit 2; }
    load_config "$1/study.config"
else open_root "" || exit 2
fi
row PASS "study.config" "$ST_CONFIG"
row PASS "STUDY_NAME" "$STUDY_NAME"
reg="$(registry_lookup "$STUDY_NAME")"
if [ "$reg" = "$ST_CONFIG" ]; then row PASS "registry" "$(registry_file)"
elif [ -z "$reg" ]; then row WARN "registry" "not registered; run write-config.sh --register $ST_ROOT"
else row WARN "registry" "$STUDY_NAME points at $reg"; fi
[ -d "$ST_SUBJECTS" ] && row PASS "SUBJECTS_DIR" "$ST_SUBJECTS" || row FAIL "SUBJECTS_DIR" "$ST_SUBJECTS is missing"
case "$REVIEW_INTERVALS" in *[!0-9\ ]*|"") row FAIL "REVIEW_INTERVALS" "'$REVIEW_INTERVALS' is not a list of whole days" ;; *) row PASS "REVIEW_INTERVALS" "$REVIEW_INTERVALS" ;; esac
for t in awk sed grep sort; do
    command -v "$t" >/dev/null 2>&1 && row PASS "tool: $t" "$(command -v "$t")" || row FAIL "tool: $t" "not found"
done
[ -f "$ST_ROOT/overview.md" ] && row PASS "overview.md" "present" || row WARN "overview.md" "missing; run overview.sh"
n=0
for d in "$ST_SUBJECTS"/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"; b="$(basename "$d")"; n=$((n + 1))
    if [ ! -f "$d/brief.md" ]; then row WARN "subject: $b" "no brief.md; not treated as a subject"; continue; fi
    t="$(brief_field "$d" "Target date")"
    if [ -n "$t" ] && [ "$t" != none ] && ! is_date "$t"; then row FAIL "subject: $b" "Target date '$t' is not none or YYYY-MM-DD"; continue; fi
    if [ ! -f "$d/plan.md" ]; then row WARN "subject: $b" "no plan.md yet"; continue; fi
    planned="$(plan_steps "$d" | sed '/^$/d' | wc -l | tr -d ' ')"
    if [ "$planned" -eq 0 ]; then row FAIL "subject: $b" "plan.md has no steps that parse"; continue; fi
    dups="$(plan_steps "$d" | cut -f1 | sed 's/^[A-Z]*//' | sort | uniq -d | tr '\n' ' ')"
    if [ -n "$dups" ]; then row FAIL "subject: $b" "plan.md uses a step number twice: $dups"; continue; fi
    if [ ! -f "$d/progress.md" ]; then row WARN "subject: $b" "$planned steps planned, no progress.md; run init-progress.sh"; continue; fi
    tracked="$(step_rows "$d" | sed '/^$/d' | wc -l | tr -d ' ')"
    if [ "$tracked" -lt "$planned" ]; then row WARN "subject: $b" "$planned steps planned, $tracked tracked; run init-progress.sh"
    else row PASS "subject: $b" "$planned steps planned, $tracked tracked"; fi
done
[ "$n" -gt 0 ] || row WARN "subjects" "none active"
notes="$(sync_notes "$ST_ROOT")"
if [ -z "$notes" ]; then row PASS "sync" "no conflict copies, merge markers or unsynced work found"
else
    while IFS="$(printf '\t')" read -r lvl txt; do row "$lvl" "sync" "$txt"; done <<NOTES
$notes
NOTES
fi
echo
if [ "$fails" -gt 0 ]; then echo "check-root: $fails failure(s)"; exit 1; else echo "check-root: ok"; fi
