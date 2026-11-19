#!/usr/bin/env bash
# Called by an AI tool's own session hooks, where the tool has them. It acts only when the
# session's directory is inside a study root, and is silent everywhere else. It never fails
# a session: every path ends in exit 0.
#
# Usage: session-hook.sh start   print what overview.sh would note about the study root
#        session-hook.sh end     save a checkpoint, if the learner turned checkpoints on
# The study root is found by walking up from $CLAUDE_PROJECT_DIR, or else the current
# directory. The registry is not consulted, so a session elsewhere on the machine does
# nothing here.
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)" || exit 0
. "$SCRIPT_DIR/lib/resolve.sh" || exit 0

d="${CLAUDE_PROJECT_DIR:-$PWD}"
cfg=""
while [ -n "$d" ] && [ "$d" != "/" ]; do
    if [ -f "$d/study.config" ]; then cfg="$d/study.config"; break; fi
    d="$(dirname "$d")"
done
[ -n "$cfg" ] || exit 0
load_config "$cfg" 2>/dev/null || exit 0

# start_notes: one line per thing worth passing on. A function, not an inline block, because
# bash 3.2 cannot parse a case statement inside a command substitution.
start_notes() {
    format_note
    sync_notes "$ST_ROOT" | cut -f2
    sn_cps="$(cp_state 2>/dev/null || true)"
    case "$sn_cps" in
        broken*) printf 'checkpoints are turned on for this study root and cannot be saved here: %s\n' "$(printf '%s' "$sn_cps" | cut -f3)" ;;
        not-asked) echo "checkpoints, a history of the study files, can be kept for this study root, and the learner has not been asked yet; the study-partner skill says how to offer it" ;;
    esac
}

case "${1:-}" in
start)
    notes="$(start_notes 2>/dev/null | sed 's/^/- /')"
    [ -n "$notes" ] || exit 0
    printf 'Study root "%s" at %s. Notes from the study partner scripts, to pass on in plain words when the learner studies:\n%s\n' "$STUDY_NAME" "$ST_ROOT" "$notes" ;;
end)
    bash "$SCRIPT_DIR/checkpoint.sh" --dir "$ST_ROOT" --quiet \
        --message "Study checkpoint $(today) (saved when the session closed; session not recorded)" >/dev/null 2>&1 || true ;;
esac
exit 0
