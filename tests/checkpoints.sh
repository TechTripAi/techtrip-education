#!/usr/bin/env bash
# Test of checkpoints (checkpoint.sh, the notes about them, and session-hook.sh) on scratch
# study roots under a fresh mktemp directory, with their own registry and an empty git
# configuration, so the real ~/.study-roots and the developer's git settings play no part.
# Deletes nothing; the OS temp cleaner owns the directory. Skips when git is not installed.
# Exit 0 when every assertion holds.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
S="$HERE/../skills/study-partner/scripts"
command -v git >/dev/null 2>&1 || { echo "checkpoints: git not installed; skipped"; exit 0; }
T="$(mktemp -d "${TMPDIR:-/tmp}/tted-cp.XXXXXX")"
T="$(cd "$T" && pwd -P)"
: > "$T/gitconfig"
export STUDY_ROOTS="$T/registry" STUDY_TODAY=2026-11-13 STUDY_MACHINE=desk
export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1
unset STUDY_CONFIG CLAUDE_PROJECT_DIR 2>/dev/null || true
fails=0
pass() { printf 'ok    %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }
is()   { if [ "$2" = "$3" ]; then pass "$1"; else bad "$1: expected '$3', got '$2'"; fi; }
has()  { if printf '%s' "$2" | grep -qF -- "$3"; then pass "$1"; else bad "$1: '$3' not found in '$2'"; fi; }
hasnt(){ if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1: '$3' should not appear"; else pass "$1"; fi; }
code() { set +e; "$@" >/dev/null 2>&1; c=$?; set -e; printf '%s' "$c"; }
exists() { if [ -e "$2" ]; then pass "$1"; else bad "$1: $2 missing"; fi; }
absent() { if [ -e "$2" ]; then bad "$1: $2 should not exist"; else pass "$1"; fi; }
at() { GIT_AUTHOR_DATE="$1T10:00:00" GIT_COMMITTER_DATE="$1T10:00:00" "${@:2}"; }
count() { git -C "$1" rev-list --count HEAD 2>/dev/null || echo 0; }

R="$T/root"
cd "$T"
bash "$S/write-config.sh" "$R" STUDY_NAME=Me LEARNER_NAME=Learner >/dev/null
bash "$S/new-subject.sh" "Rust Programming" --slug rust >/dev/null
N="$R/subjects/rust/glossary.md"
CP="bash $S/checkpoint.sh --dir $R"

# --- never asked: an offer, and nothing happens by itself
has "a new root has not been asked" "$($CP --status)" "not-asked"
has "overview carries the offer" "$(bash "$S/overview.sh" --stdout 2>&1 >/dev/null)" "overview: offer: checkpoints"
has "check-root shows them as not turned on" "$(bash "$S/check-root.sh" "$R")" "PASS  checkpoints                  not turned on"
has "saving while off says so" "$($CP)" "checkpoints are off"
absent "saving while off starts no history" "$R/.git"
is "the session-end hook does nothing while off" "$(cd "$R" && bash "$S/session-hook.sh" end; echo $?)" 0
absent "the hook starts no history" "$R/.git"

# --- the learner says no: recorded, and not offered again
has "--disable records the answer" "$($CP --disable)" "checkpoints are off"
has "the answer is in study.config" "$(cat "$R/study.config")" "AUTO_CHECKPOINT='0'"
is "status is off" "$($CP --status)" "off"
hasnt "no offer after a no" "$(bash "$S/overview.sh" --stdout 2>&1 >/dev/null)" "overview: offer"
bash "$S/write-config.sh" "$R" LEARNER_NAME=Learner --force >/dev/null
has "write-config --force keeps the answer" "$(cat "$R/study.config")" "AUTO_CHECKPOINT='0'"
has "other keys are kept when the answer is recorded" "$(cat "$R/study.config")" "STUDY_NAME='me'"

# --- the learner says yes
out="$(at 2026-11-10 $CP --enable)"
has "--enable says checkpoints are on" "$out" "checkpoints are on"
has "--enable saves a first checkpoint" "$out" "saved ("
exists "a history is started" "$R/.git"
exists "operating system files are kept out" "$R/.gitignore"
has "study.config says on" "$(cat "$R/study.config")" "AUTO_CHECKPOINT='1'"
is "AUTO_CHECKPOINT is written once" "$(grep -c '^AUTO_CHECKPOINT=' "$R/study.config")" 1
is "one checkpoint saved" "$(count "$R")" 1
is "with no git identity the learner's name is used" "$(git -C "$R" log -1 --format=%an)" "Learner"
has "status is on" "$($CP --status)" "on: 1 checkpoint(s) saved"
has "check-root shows them on" "$(bash "$S/check-root.sh" "$R")" "PASS  checkpoints                  on; 1 saved"
hasnt "no offer once on" "$(bash "$S/overview.sh" --stdout 2>&1 >/dev/null)" "overview: offer"
is "a saved root has nothing unsaved to report" "$(bash "$S/overview.sh" --stdout 2>&1 >/dev/null | grep -c 'not committed' || true)" 0
has "nothing changed, nothing saved" "$($CP)" "nothing new to save"
is "still one checkpoint" "$(count "$R")" 1

# --- saving
echo "first version" > "$N"
has "a change is saved with the message given" "$(at 2026-11-11 $CP --message "rust: session 1")" "saved (1 change(s)): rust: session 1"
echo "second version" > "$N"
at 2026-11-12 $CP --message "rust: session 2" >/dev/null
is "three checkpoints" "$(count "$R")" 3
is "--quiet prints nothing" "$($CP --quiet)" ""
is "the remote is never set" "$(git -C "$R" remote | wc -l | tr -d ' ')" 0

# --- looking back
list="$($CP --list)"
has "the list shows a message" "$list" "rust: session 2"
has "the list shows a date" "$list" "2026-11-11"
has "the list for one file" "$($CP --list subjects/rust/glossary.md)" "rust: session 1"
hasnt "the list for one file leaves out other saves" "$($CP --list subjects/rust/brief.md)" "rust: session 2"
is "a file as it was on a day" "$($CP --show subjects/rust/glossary.md --at 2026-11-11)" "first version"
is "a file by absolute path" "$($CP --show "$N" --at 2026-11-12)" "second version"
is "a day before the first checkpoint is refused" "$(code $CP --show subjects/rust/glossary.md --at 2026-01-01)" 1
is "a file that was not there is refused" "$(code $CP --show subjects/rust/nothing.md --at 2026-11-11)" 1
is "a path outside the root is refused" "$(code $CP --show /etc/hosts --at 2026-11-11)" 1
is "a path with .. is refused" "$(code $CP --show subjects/../study.config --at 2026-11-11)" 1
is "--show needs --at" "$(code $CP --show subjects/rust/glossary.md)" 1

# --- bringing back
echo "third version, not yet saved" > "$N"
echo "made later" > "$R/subjects/rust/later.md"
out="$($CP --restore subjects/rust/glossary.md --at 2026-11-11)"
is "the file is as it was" "$(cat "$N")" "first version"
has "the present state was saved first" "$($CP --list)" "Before bringing back subjects/rust/glossary.md as of 2026-11-11"
has "the restore is itself a checkpoint" "$out" "Brought back subjects/rust/glossary.md as of 2026-11-11"
exists "a file made since is kept" "$R/subjects/rust/later.md"
before="$(git -C "$R" rev-list -1 --grep='Before bringing back' HEAD)"
is "the unsaved version can still be got back" "$($CP --show subjects/rust/glossary.md --at "$before")" "third version, not yet saved"
$CP --restore . --at 2026-11-10 >/dev/null
has "bringing back the whole root leaves checkpoints on" "$(cat "$R/study.config")" "AUTO_CHECKPOINT='1'"
exists "bringing back the whole root deletes nothing" "$N"
is "nothing is left unsaved after a restore" "$(git -C "$R" status --porcelain | wc -l | tr -d ' ')" 0
is "restoring a file that was not there is refused" "$(code $CP --restore subjects/rust/nothing.md --at 2026-11-11)" 1

# --- the session hooks
E="$T/elsewhere"; mkdir -p "$E"
is "the start hook is silent outside a study root" "$(cd "$E" && bash "$S/session-hook.sh" start 2>&1)" ""
is "the hooks never fail a session" "$(cd "$E" && bash "$S/session-hook.sh" end >/dev/null 2>&1; echo $?)" 0
echo "changed in a session" >> "$N"
n="$(count "$R")"
(cd "$E" && bash "$S/session-hook.sh" end)
is "the end hook leaves another directory's root alone" "$(count "$R")" "$n"
has "the start hook reports unsaved changes inside a root" "$(cd "$R/subjects/rust" && bash "$S/session-hook.sh" start)" "not saved to this study root's history yet"
(cd "$R/subjects/rust" && bash "$S/session-hook.sh" end)
is "the end hook saves a checkpoint inside a root" "$(count "$R")" "$((n + 1))"
has "its message says the session was not recorded" "$(git -C "$R" log -1 --format=%s)" "session not recorded"
is "the start hook is silent when there is nothing to say" "$(cd "$R" && bash "$S/session-hook.sh" start 2>&1)" ""
echo "again" >> "$N"
(cd "$E" && CLAUDE_PROJECT_DIR="$R" bash "$S/session-hook.sh" end)
is "the end hook follows the tool's project directory" "$(count "$R")" "$((n + 2))"

# --- where checkpoints cannot be kept
D="$T/Dropbox/root"
bash "$S/write-config.sh" "$D" STUDY_NAME=synced >/dev/null
DP="bash $S/checkpoint.sh --dir $D"
has "a file-sync folder is recognised" "$($DP --status)" "unavailable (sync-folder)"
is "--enable refuses there" "$(code $DP --enable)" 3
has "--enable says why in plain words" "$($DP --enable || true)" "a file-sync service keeps copied"
absent "no history is started in a sync folder" "$D/.git"
hasnt "no offer where they cannot be kept" "$(STUDY_CONFIG="$D/study.config" bash "$S/overview.sh" --stdout 2>&1 >/dev/null)" "overview: offer"
has "check-root says why, without a warning" "$(bash "$S/check-root.sh" "$D")" "PASS  checkpoints                  not kept here"

O="$T/outer"; mkdir -p "$O"; git -C "$O" init -q 2>/dev/null
bash "$S/write-config.sh" "$O/inner" STUDY_NAME=inner >/dev/null
has "a root inside another history is recognised" "$(bash "$S/checkpoint.sh" --dir "$O/inner" --status)" "unavailable (nested)"
is "--enable refuses a nested root" "$(code bash "$S/checkpoint.sh" --dir "$O/inner" --enable)" 3
absent "no history is started inside another" "$O/inner/.git"

B="$T/copied"
bash "$S/write-config.sh" "$B" STUDY_NAME=copied >/dev/null
printf "AUTO_CHECKPOINT='1'\n" >> "$B/study.config"
has "on with no history here is reported" "$(bash "$S/checkpoint.sh" --dir "$B" --status)" "broken (no-history)"
is "saving there exits 3" "$(code bash "$S/checkpoint.sh" --dir "$B")" 3
has "overview notes it" "$(STUDY_CONFIG="$B/study.config" bash "$S/overview.sh" --stdout 2>&1 >/dev/null)" "overview: note: checkpoints are turned on for this study root and cannot be saved here"
has "check-root warns" "$(bash "$S/check-root.sh" "$B")" "WARN  checkpoints"
is "it is not a failure" "$(code bash "$S/check-root.sh" "$B")" 0
bash "$S/checkpoint.sh" --dir "$B" --enable >/dev/null
has "--enable on this machine mends it" "$(bash "$S/checkpoint.sh" --dir "$B" --status)" "on: 1 checkpoint(s) saved"

echo
if [ "$fails" -gt 0 ]; then echo "checkpoints: $fails failure(s)"; exit 1; else echo "checkpoints: all assertions hold"; fi
