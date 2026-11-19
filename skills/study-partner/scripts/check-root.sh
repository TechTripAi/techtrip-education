#!/usr/bin/env bash
# Health check for a study root. One PASS/WARN/FAIL row per check. Read-only unless
# --upgrade is given.
#
# Usage: check-root.sh [<directory> | --root <study root name>] [--upgrade]
#   --upgrade brings a study root in an older format up to the one these scripts write. It
#   says what it does, copies aside any file it rewrites, deletes nothing, and is safe to
#   run again. On a root that is already current it only records the format in study.config.
# Exit 1: at least one FAIL, or bad usage. Exit 2: no study root found.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

fails=0
row() { printf '%-5s %-28s %s\n' "$1" "$2" "$3"; [ "$1" = FAIL ] && fails=$((fails + 1)) || true; }
dir=""; rootname=""; upgrade=0
while [ $# -gt 0 ]; do
    case "$1" in
        --root) rootname="${2:-}"; [ -n "$rootname" ] || { echo "check-root: --root needs a name" >&2; exit 1; }; shift 2 ;;
        --upgrade) upgrade=1; shift ;;
        -*) echo "check-root: unknown option $1" >&2; exit 1 ;;
        *) [ -z "$dir" ] && dir="$1" || { echo "check-root: one directory only" >&2; exit 1; }; shift ;;
    esac
done
if [ -n "$rootname" ]; then open_root "$rootname" || exit 2
elif [ -n "$dir" ]; then
    [ -f "$dir/study.config" ] || { echo "check-root: no study.config in $dir" >&2; exit 2; }
    load_config "$dir/study.config"
else open_root "" || exit 2
fi

# --upgrade: one block per format step, oldest first. Each block must be safe to run twice,
# must copy aside any learner file it rewrites, and must delete nothing. There are no steps
# yet: every release so far reads the files of the one before it.
if [ "$upgrade" -eq 1 ]; then
    if [ "$STUDY_FORMAT" -gt "$STUDY_FORMAT_CURRENT" ]; then
        echo "check-root: this study root is format $STUDY_FORMAT and these scripts write format $STUDY_FORMAT_CURRENT; update the plugin on this machine. Nothing was changed."
    else
        f="$STUDY_FORMAT"
        while [ "$f" -lt "$STUDY_FORMAT_CURRENT" ]; do
            # case "$f" in 1) ... format 1 to 2 ... ;; esac
            f=$((f + 1))
        done
        if grep -q "^STUDY_FORMAT='$STUDY_FORMAT_CURRENT'\$" "$ST_CONFIG" 2>/dev/null; then
            echo "check-root: already format $STUDY_FORMAT_CURRENT; nothing to upgrade"
        else
            set_config_key "$ST_CONFIG" STUDY_FORMAT "$STUDY_FORMAT_CURRENT"
            echo "check-root: recorded format $STUDY_FORMAT_CURRENT in $ST_CONFIG; no file needed changing"
            STUDY_FORMAT="$STUDY_FORMAT_CURRENT"
        fi
    fi
    echo
fi
row PASS "study.config" "$ST_CONFIG"
row PASS "STUDY_NAME" "$STUDY_NAME"
fn="$(format_note)"
if [ -z "$fn" ]; then row PASS "format" "$STUDY_FORMAT"; else row WARN "format" "$fn"; fi
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
if [ -z "$notes" ]; then row PASS "sync" "no sign of changes made in two places, and nothing waiting to be sent"
else
    while IFS="$(printf '\t')" read -r lvl txt; do row "$lvl" "sync" "$txt"; done <<NOTES
$notes
NOTES
fi
cps="$(cp_state)"
case "$cps" in
    on) row PASS "checkpoints" "on; $(cp_git rev-list --count HEAD 2>/dev/null || echo 0) saved" ;;
    off) row PASS "checkpoints" "off" ;;
    not-asked) row PASS "checkpoints" "not turned on; checkpoint.sh --enable turns them on" ;;
    unavailable*) row PASS "checkpoints" "not kept here: $(printf '%s' "$cps" | cut -f3)" ;;
    broken*) row WARN "checkpoints" "turned on, and cannot be saved here: $(printf '%s' "$cps" | cut -f3)" ;;
esac
echo
if [ "$fails" -gt 0 ]; then echo "check-root: $fails failure(s)"; exit 1; else echo "check-root: ok"; fi
