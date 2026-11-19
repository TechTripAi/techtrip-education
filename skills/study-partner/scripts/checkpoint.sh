#!/usr/bin/env bash
# Checkpoints for a study root: a history of its files kept inside it, so an earlier
# version of anything can be looked at or brought back. Off until the learner says yes.
# Git is the engine; the learner never has to know. This script never pushes, pulls or
# contacts another machine, and never deletes a file from the study root.
#
# Usage: checkpoint.sh [--message "<text>"] [--quiet]   save one, if on and something changed
#        checkpoint.sh --status          on | off | not-asked | unavailable | broken, and why
#        checkpoint.sh --enable          turn on: start the history if there is none, save one
#        checkpoint.sh --disable         turn off, or record that the learner said no
#        checkpoint.sh --list [<path>]   the saved checkpoints, newest first, for a file if named
#        checkpoint.sh --show <path> --at <YYYY-MM-DD | id>      print a file as it was
#        checkpoint.sh --restore <path> --at <YYYY-MM-DD | id>   bring a file or folder back
#   Any form also takes --root <study root name> or --dir <study root directory>.
#   <path> is relative to the study root; "." is all of it. A date means the last checkpoint
#   saved on or before that day. --restore saves the present state first and then saves the
#   restored one, so it can itself be undone; files created since are left where they are.
# Exit 0: done, or nothing to do. Exit 1: bad usage, or no such checkpoint or file.
# Exit 2: no study root. Exit 3: checkpoints cannot be saved here; the message says why.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

mode=save; msg=""; quiet=0; rootname=""; dir=""; path=""; at=""
while [ $# -gt 0 ]; do
    case "$1" in
        --status|--enable|--disable) mode="${1#--}"; shift ;;
        --list) mode=list; shift; case "${1:-}" in ""|--*) ;; *) path="$1"; shift ;; esac ;;
        --show|--restore) mode="${1#--}"; path="${2:-}"; [ -n "$path" ] || { echo "checkpoint: $1 needs a path" >&2; exit 1; }; shift 2 ;;
        --at) at="${2:-}"; [ -n "$at" ] || { echo "checkpoint: --at needs a date or an id" >&2; exit 1; }; shift 2 ;;
        --message) msg="${2:-}"; shift 2 ;;
        --quiet) quiet=1; shift ;;
        --root) rootname="${2:-}"; shift 2 ;;
        --dir) dir="${2:-}"; shift 2 ;;
        *) echo "checkpoint: unknown option $1" >&2; exit 1 ;;
    esac
done
if [ -n "$dir" ]; then
    [ -f "$dir/study.config" ] || { echo "checkpoint: no study.config in $dir" >&2; exit 2; }
    load_config "$dir/study.config"
else open_root "$rootname" || exit 2
fi
say() { [ "$quiet" -eq 1 ] || printf 'checkpoint: %s\n' "$1"; }
reason() { printf '%s' "$1" | cut -f3; }

# commit <message>: save everything that changed. Uses the learner's own git identity when
# there is one; otherwise a name for this one save, so a first checkpoint never fails.
commit() {
    cp_git add -A >/dev/null 2>&1 || return 1
    if [ -n "$(cp_git config user.name 2>/dev/null || true)" ] && [ -n "$(cp_git config user.email 2>/dev/null || true)" ]; then
        cp_git commit -q -m "$1" >/dev/null 2>&1
    else
        cp_git -c user.name="${LEARNER_NAME:-Study partner}" -c user.email="study-partner@localhost" commit -q -m "$1" >/dev/null 2>&1
    fi
}
half_merged() { [ -n "$(cp_git ls-files -u 2>/dev/null)" ] || [ -f "$ST_ROOT/.git/MERGE_HEAD" ]; }
changes() { cp_git status --porcelain 2>/dev/null | sed '/^$/d' | wc -l | tr -d ' '; }

# save <message>: 0 saved or nothing to save, 3 cannot
save() {
    st="$(cp_state)"
    case "$st" in
        on) ;;
        broken*) say "not saved: $(reason "$st")"; return 3 ;;
        *) say "checkpoints are off for this study root; nothing saved"; return 0 ;;
    esac
    if half_merged; then say "not saved: some files were changed in two places and are only half combined; finish that first"; return 3; fi
    n="$(changes)"
    if [ "$n" -eq 0 ]; then say "nothing new to save"; return 0; fi
    if commit "$1"; then say "saved ($n change(s)): $1"; return 0; fi
    say "not saved: the history refused the save; the files themselves are untouched"; return 3
}

# need_history: stop unless there is a history with at least one checkpoint
need_history() {
    command -v git >/dev/null 2>&1 && cp_is_repo && cp_git rev-parse -q --verify HEAD >/dev/null 2>&1 \
        || { echo "checkpoint: this study root has no checkpoints yet" >&2; exit 1; }
}
# rel_path <path>: the path relative to the study root, refusing anything outside it
rel_path() {
    rp="$1"
    case "$rp" in "$ST_ROOT") rp="." ;; "$ST_ROOT"/*) rp="${rp#"$ST_ROOT"/}" ;; /*) echo "checkpoint: $rp is not inside the study root" >&2; exit 1 ;; esac
    case "/$rp/" in */../*) echo "checkpoint: a path may not contain .." >&2; exit 1 ;; esac
    printf '%s' "$rp"
}
# rev_at <date or id>: the checkpoint meant
rev_at() {
    if is_date "$1"; then r="$(cp_git rev-list -1 --before="$1 23:59:59" HEAD 2>/dev/null || true)"
    else r="$(cp_git rev-parse -q --verify "$1^{commit}" 2>/dev/null || true)"; fi
    [ -n "$r" ] || { echo "checkpoint: no checkpoint for '$1'; --list shows the ones there are" >&2; exit 1; }
    printf '%s' "$r"
}

case "$mode" in
save)
    [ -n "$msg" ] || msg="Study checkpoint $(today)"
    rc=0; save "$msg" || rc=$?; exit "$rc" ;;
status)
    st="$(cp_state)"
    case "$st" in
        on) echo "on: $(cp_git rev-list --count HEAD 2>/dev/null || echo 0) checkpoint(s) saved" ;;
        off) echo "off" ;;
        not-asked) echo "not-asked: checkpoints can be kept here and the learner has not been asked" ;;
        unavailable*) echo "unavailable ($(printf '%s' "$st" | cut -f2)): $(reason "$st")" ;;
        broken*) echo "broken ($(printf '%s' "$st" | cut -f2)): turned on, and cannot be saved here: $(reason "$st")" ;;
    esac ;;
enable)
    b="$(cp_blocker)"
    if [ -n "$b" ]; then echo "checkpoint: checkpoints cannot be kept here: $(printf '%s' "$b" | cut -f2)"; exit 3; fi
    if ! cp_is_repo; then
        git -C "$ST_ROOT" init -q >/dev/null 2>&1 || { echo "checkpoint: could not start a history in $ST_ROOT" >&2; exit 3; }
        say "started a history for $ST_ROOT"
    fi
    if [ ! -f "$ST_ROOT/.gitignore" ]; then
        printf '%s\n' "# Files the operating system and the scripts leave behind; not part of your study files." ".DS_Store" "Thumbs.db" "desktop.ini" "*.tmp.*" > "$ST_ROOT/.gitignore"
    fi
    set_config_key "$ST_CONFIG" AUTO_CHECKPOINT 1; AUTO_CHECKPOINT=1
    say "checkpoints are on"
    rc=0; save "Study checkpoint $(today): checkpoints turned on" || rc=$?; exit "$rc" ;;
disable)
    set_config_key "$ST_CONFIG" AUTO_CHECKPOINT 0
    say "checkpoints are off; the history saved so far is kept" ;;
list)
    need_history
    if [ -n "$path" ]; then cp_git log --date=short --pretty='%h  %ad  %s' -n 50 -- "$(rel_path "$path")"
    else cp_git log --date=short --pretty='%h  %ad  %s' -n 50; fi ;;
show)
    need_history
    [ -n "$at" ] || { echo "checkpoint: --show needs --at <YYYY-MM-DD | id>" >&2; exit 1; }
    rel="$(rel_path "$path")"; rev="$(rev_at "$at")"
    cp_git show "$rev:$rel" 2>/dev/null || { echo "checkpoint: $rel was not in the study root at that checkpoint" >&2; exit 1; } ;;
restore)
    need_history
    [ -n "$at" ] || { echo "checkpoint: --restore needs --at <YYYY-MM-DD | id>" >&2; exit 1; }
    rel="$(rel_path "$path")"; rev="$(rev_at "$at")"
    [ "$(cp_state)" = on ] || { echo "checkpoint: turn checkpoints on first (--enable), so that the present state is saved before anything is brought back" >&2; exit 3; }
    if [ "$rel" != "." ]; then
        cp_git cat-file -e "$rev:$rel" 2>/dev/null || { echo "checkpoint: $rel was not in the study root at that checkpoint" >&2; exit 1; }
    fi
    rc=0; save "Before bringing back $rel as of $at" || rc=$?
    [ "$rc" -eq 0 ] || exit "$rc"
    cp_git checkout -q "$rev" -- "$rel" 2>/dev/null || { echo "checkpoint: could not bring back $rel" >&2; exit 1; }
    # bringing back the whole root must not switch checkpoints off or change the format stamp
    set_config_key "$ST_CONFIG" AUTO_CHECKPOINT 1
    set_config_key "$ST_CONFIG" STUDY_FORMAT "$STUDY_FORMAT"
    rc=0; save "Brought back $rel as of $at" || rc=$?; exit "$rc" ;;
esac
