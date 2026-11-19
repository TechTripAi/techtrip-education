#!/usr/bin/env bash
# End-to-end test of the study-partner scripts on a scratch study root with two subjects.
# Builds everything under a fresh mktemp directory with its own registry, so the real
# ~/.study-roots is never touched. Deletes nothing; the OS temp cleaner owns the directory.
# Exit 0 when every assertion holds.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
S="$HERE/../skills/study-partner/scripts"
T="$(mktemp -d "${TMPDIR:-/tmp}/tted-test.XXXXXX")"
T="$(cd "$T" && pwd)"
export STUDY_ROOTS="$T/registry" STUDY_TODAY=2026-11-13
unset STUDY_CONFIG 2>/dev/null || true
R="$T/root"
fails=0
pass() { printf 'ok    %s\n' "$1"; }
bad()  { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }
is()   { if [ "$2" = "$3" ]; then pass "$1"; else bad "$1: expected '$3', got '$2'"; fi; }
has()  { if printf '%s' "$2" | grep -qF -- "$3"; then pass "$1"; else bad "$1: '$3' not found"; fi; }
hasnt(){ if printf '%s' "$2" | grep -qF -- "$3"; then bad "$1: '$3' should not appear"; else pass "$1"; fi; }
code() { set +e; "$@" >/dev/null 2>&1; c=$?; set -e; printf '%s' "$c"; }
exists() { if [ -e "$2" ]; then pass "$1"; else bad "$1: $2 missing"; fi; }
absent() { if [ -e "$2" ]; then bad "$1: $2 should not exist"; else pass "$1"; fi; }

cd "$T"

# --- no study root yet
is "overview with no root exits 2" "$(code bash "$S/overview.sh" --stdout)" 2

# --- set up a root and two subjects
bash "$S/write-config.sh" "$R" STUDY_NAME=Me LEARNER_NAME=Learner >/dev/null
exists "study.config written" "$R/study.config"
has "root registered by kebab name" "$(cat "$STUDY_ROOTS")" "me=$R/study.config"
is "write-config refuses to overwrite" "$(code bash "$S/write-config.sh" "$R")" 3
bash "$S/write-config.sh" "$R" REVIEW_INTERVALS="2 5" --force >/dev/null
has "--force keeps other keys" "$(cat "$R/study.config")" "LEARNER_NAME='Learner'"
has "--force updates the given key" "$(cat "$R/study.config")" "REVIEW_INTERVALS='2 5'"
bash "$S/write-config.sh" "$R" REVIEW_INTERVALS="1 3 7 14 30" --force >/dev/null

bash "$S/new-subject.sh" "AWS Solutions Architect" --slug aws-sa --kind certification --target 2027-01-15 >/dev/null
bash "$S/new-subject.sh" "Rust Programming" --slug rust >/dev/null
A="$R/subjects/aws-sa"
for d in brief.md sources.md glossary.md lessons sheets quizzes materials; do exists "new subject has $d" "$A/$d"; done
has "target date recorded" "$(cat "$A/brief.md")" "**Target date:** 2027-01-15"
has "open-ended by default" "$(cat "$R/subjects/rust/brief.md")" "**Target date:** none"
is "new-subject refuses an existing subject" "$(code bash "$S/new-subject.sh" "AWS" --slug aws-sa)" 3
is "new-subject rejects a bad target date" "$(code bash "$S/new-subject.sh" "Bad" --target tomorrow)" 1

# --- resolving a subject
is "resolve by directory name" "$(bash "$S/resolve-subject.sh" aws-sa)" "$A"
is "resolve by title fragment" "$(bash "$S/resolve-subject.sh" architect)" "$A"
is "resolve with root prefix" "$(bash "$S/resolve-subject.sh" me:rust)" "$R/subjects/rust"
is "resolve returns one directory only" "$(bash "$S/resolve-subject.sh" rust | wc -l | tr -d ' ')" 1
is "ambiguous reference exits 4" "$(code bash "$S/resolve-subject.sh" r)" 4
is "unknown subject exits 2" "$(code bash "$S/resolve-subject.sh" basket-weaving)" 2
is "no subject named exits 5" "$(code bash "$S/resolve-subject.sh")" 5

# --- the plan and the ledger
cat > "$A/plan.md" <<'PLAN'
# AWS Solutions Architect: study plan

**Status:** ready (updated 2026-11-13)
**Source:** brief.md

## Phase A: Core services

1. **[Learn] Compute options.** EC2, Lambda, containers. Sources: S1, S3.
   Done when: you can choose between them for a given workload and say why.
2. **[Apply] Launch and size an instance.** Hands-on. Sources: S2.
   Done when: you have launched, resized and terminated an instance.

Checkpoint A: quiz on steps 1 to 2.

## Phase B: Networking. Builds on Phase A.

3. **[Learn] VPC basics.** Subnets and routing. Sources: S1.
   Done when: you can sketch a two-tier VPC.
PLAN
printf '# Rust: study plan\r\n\r\n## Phase A: Basics\r\n\r\n1. **[Learn] Ownership.** Sources: S1.\r\n   Done when: you can explain a move.\r\n' > "$R/subjects/rust/plan.md"

dry="$(bash "$S/init-progress.sh" aws-sa --dry-run 2>/dev/null)"
has "dry run lists a Learn step" "$dry" "| A1 | A | Learn | Compute options | pending | 0 | - | - | |"
has "dry run lists an Apply step" "$dry" "| A2 | A | Apply | Launch and size an instance | pending | 0 | - | - | |"
has "dry run lists a step in phase B" "$dry" "| B3 | B | Learn | VPC basics | pending | 0 | - | - | |"
has "dry run lists the checkpoint" "$dry" "| CP-A | quiz on steps 1 to 2. | pending |"
absent "dry run writes nothing" "$A/progress.md"
bash "$S/init-progress.sh" aws-sa >/dev/null
bash "$S/init-progress.sh" rust >/dev/null
has "CRLF plan parses" "$(cat "$R/subjects/rust/progress.md")" "| A1 | A | Learn | Ownership | pending | 0 | - | - | |"
is "init-progress is idempotent" "$(bash "$S/init-progress.sh" aws-sa | grep -c 'already has every step')" 1

# --- lessons
L="$(bash "$S/open-lesson.sh" aws a1)"
is "lesson file is named for the step" "$L" "$A/lessons/A1-compute-options.md"
lesson="$(cat "$L")"
has "lesson header carries Done when" "$lesson" "**Done when:** you can choose between them for a given workload and say why."
has "lesson header carries sources" "$lesson" "**Sources:** S1, S3"
has "lesson starts unstarted" "$lesson" "**Stopped at:** not started"
has "opening a lesson marks the step in progress" "$(cat "$A/progress.md")" "| A1 | A | Learn | Compute options | in progress | 0 | 2026-11-13 | - |"
printf '\n## My own heading\n\ntext\n' >> "$L"
bash "$S/open-lesson.sh" aws-sa A1 >/dev/null
has "an existing lesson is never changed" "$(cat "$L")" "## My own heading"
bash "$S/open-lesson.sh" aws-sa B3 >/dev/null
is "several lessons can be in progress" "$(grep -c '| in progress |' "$A/progress.md")" 2
is "unknown step exits 1" "$(code bash "$S/open-lesson.sh" aws-sa Z9)" 1

# --- step and checkpoint status
has "a step closes on request" "$(bash "$S/set-step.sh" aws-sa A1 done)" "A1  Compute options: done"
has "a skip records its reason" "$(bash "$S/set-step.sh" aws-sa a2 skipped --note "already do this at work")" "skipped (already do this at work)"
has "a checkpoint can be declined" "$(bash "$S/set-step.sh" aws-sa CP-A skipped)" "CP-A: skipped 2026-11-13"
is "an unknown status is refused" "$(code bash "$S/set-step.sh" aws-sa A1 finished)" 1
is "an unknown step is refused" "$(code bash "$S/set-step.sh" aws-sa Z9 done)" 1

# --- review suggestions
has "pass moves up a level" "$(bash "$S/record-review.sh" aws-sa A1 pass)" "level 1, next suggested review 2026-11-14"
has "second pass uses the next gap" "$(bash "$S/record-review.sh" aws-sa A1 pass)" "level 2, next suggested review 2026-11-16"
has "fail drops to level 1" "$(bash "$S/record-review.sh" aws-sa A1 fail --date 2026-11-10)" "level 1, next suggested review 2026-11-11"
has "a review never changes status" "$(cat "$A/progress.md")" "| A1 | A | Learn | Compute options | done | 1 | 2026-11-10 | 2026-11-11 |"
for i in 1 2 3 4 5; do bash "$S/record-review.sh" rust A1 pass >/dev/null; done
has "after the last level nothing more is suggested" "$(bash "$S/record-review.sh" rust A1 pass)" "level 5, next suggested review -"
has "month rollover" "$(bash "$S/record-review.sh" aws-sa B3 fail --date 2026-12-31)" "next suggested review 2027-01-01"
bash "$S/record-review.sh" aws-sa B3 pass >/dev/null

rev="$(bash "$S/reviews.sh")"
has "reviews lists the suggested step" "$rev" "Compute options"
hasnt "reviews omits a step suggested for later" "$rev" "VPC basics"
has "reviews summarises each subject" "$rev" "aws-sa                 1 suggested, 1 in progress, 1 done of 3 steps"
hasnt "reviews for one subject omits the other" "$(bash "$S/reviews.sh" --subject rust)" "aws-sa"

# --- pace and overview
pace="$(bash "$S/pace.sh" aws-sa)"
has "pace shows the target date" "$pace" "Target date: 2027-01-15."
has "pace counts remaining steps" "$pace" "1 of 3 steps remaining."
has "pace gives a rate" "$pace" "63 days left"
has "no target date is open-ended" "$(bash "$S/pace.sh" rust)" "Target date: none (open-ended)."
late="$(bash "$S/pace.sh" aws-sa --date 2027-03-01)"
has "a passed date is a plain fact" "$late" "Target date: 2027-01-15."
hasnt "a passed date gives no rate" "$late" "days left"
has "pace before a plan exists" "$(bash "$S/pace.sh" --steps 40 --target 2027-01-15)" "about 5 steps a week"

ov="$(bash "$S/overview.sh" --stdout)"
has "overview shows status only for a planned subject" "$ov" "| aws-sa | AWS Solutions Architect | active | 1 of 3 | 1 | 1 | 2027-01-15 | - |"
has "overview shows an open-ended subject" "$ov" "| rust | Rust Programming | active | 0 of 1 | 0 | 0 | none | - |"
absent "--stdout writes nothing" "$R/overview.md"
bash "$S/overview.sh" >/dev/null
exists "overview.md written" "$R/overview.md"

# --- the plan changes
printf '\n4. **[Apply] Build a VPC.** Sources: S1.\n   Done when: you have built one.\n\nCheckpoint B: quiz on steps 3 to 4.\n' >> "$A/plan.md"
bash "$S/init-progress.sh" aws-sa >/dev/null
prog="$(cat "$A/progress.md")"
has "new step added to the ledger" "$prog" "| B4 | B | Apply | Build a VPC | pending | 0 | - | - | |"
has "new checkpoint added" "$prog" "| CP-B | quiz on steps 3 to 4. | pending |"
has "existing rows untouched" "$prog" "| A2 | A | Apply | Launch and size an instance | skipped | 0 | 2026-11-13 | - | already do this at work |"
has "sessions heading survives" "$prog" "## Sessions"
# several new rows at once: BSD awk (macOS) rejects a newline in a -v value
printf '\n## Phase C: Storage\n\n5. **[Learn] Object storage.** Sources: S1.\n   Done when: you can say when to use it.\n6. **[Learn] Block storage \\ volumes.** Sources: S1.\n   Done when: you can size one.\n7. **[Apply] Pick a storage class.** Sources: S1.\n   Done when: you have picked one.\n\nCheckpoint C: quiz on steps 5 to 7.\nCheckpoint D: mixed review.\n' >> "$A/plan.md"
is "several new steps at once are added" "$(code bash "$S/init-progress.sh" aws-sa)" 0
prog="$(cat "$A/progress.md")"
has "first of several new steps" "$prog" "| C5 | C | Learn | Object storage | pending | 0 | - | - | |"
has "a backslash in a title is kept" "$prog" "| C6 | C | Learn | Block storage \\ volumes | pending | 0 | - | - | |"
has "last of several new steps" "$prog" "| C7 | C | Apply | Pick a storage class | pending | 0 | - | - | |"
has "first of several new checkpoints" "$prog" "| CP-C | quiz on steps 5 to 7. | pending |"
has "last of several new checkpoints" "$prog" "| CP-D | mixed review. | pending |"
is "new step rows sit together under Steps" "$(printf '%s\n' "$prog" | awk '/^## Checkpoints/{exit} /^\| *[A-Z]+[0-9]+ *\|/{n++} END{print n+0}')" 7
has "sessions heading still survives" "$prog" "## Sessions"
is "no temporary file is left behind" "$(ls "$A" | grep -c 'progress.md.tmp' || true)" 0

# --- the packet: export at any time, refresh, close, reopen
echo "notes" > "$A/sheets/compute-cheat-sheet.md"
P="$(bash "$S/export-packet.sh" aws-sa)"
is "packet goes under packets/" "$P" "$R/packets/aws-sa"
for f in index.md brief.md sources.md plan.md glossary.md lessons/A1-compute-options.md lessons/B3-vpc-basics.md sheets/compute-cheat-sheet.md; do exists "packet has $f" "$P/$f"; done
absent "packet leaves out the working state" "$P/progress.md"
idx="$(cat "$P/index.md")"
has "index links a lesson with its status" "$idx" "| A1 | Learn | Compute options | done | [A1-compute-options.md](lessons/A1-compute-options.md) |"
has "index shows a step with no lesson yet" "$idx" "| B4 | Apply | Build a VPC | pending | - |"
has "index links a cheat sheet" "$idx" "[compute-cheat-sheet.md](sheets/compute-cheat-sheet.md)"
exists "export leaves the subject in place" "$A/progress.md"
echo "more" >> "$A/lessons/A1-compute-options.md"
bash "$S/export-packet.sh" aws-sa >/dev/null
has "exporting again refreshes the packet" "$(cat "$P/lessons/A1-compute-options.md")" "more"
O="$(bash "$S/export-packet.sh" aws-sa --to "$T/elsewhere")"
exists "export to a chosen directory" "$O/index.md"

bash "$S/close-subject.sh" aws-sa >/dev/null
absent "a closed subject leaves the active list" "$A"
exists "a closed subject is archived whole" "$R/archive/aws-sa/progress.md"
has "closing marks the brief" "$(cat "$R/archive/aws-sa/brief.md")" "**Status:** closed 2026-11-13"
has "closing makes a final export" "$(cat "$P/index.md")" "**Status:** closed 2026-11-13"
has "archive index records it" "$(cat "$R/archive/index.md")" "| aws-sa | AWS Solutions Architect | 2026-11-13 | closed |"
hasnt "overview drops a closed subject" "$(bash "$S/overview.sh" --stdout)" "aws-sa"
is "a closed subject does not resolve" "$(code bash "$S/resolve-subject.sh" aws-sa)" 2
bash "$S/close-subject.sh" --reopen aws-sa >/dev/null
exists "reopen brings it back" "$A/plan.md"
has "reopen marks it active" "$(cat "$A/brief.md")" "**Status:** active"

# --- another machine: register a synced copy, and report signs of two writers
C="$T/copy"
cp -R "$R" "$C"
before="$(cat "$C/study.config")"
is "--register needs a study.config" "$(code env STUDY_ROOTS="$T/registry2" bash "$S/write-config.sh" --register "$T")" 2
is "--register takes no keys" "$(code env STUDY_ROOTS="$T/registry2" bash "$S/write-config.sh" --register "$C" STUDY_NAME=x)" 1
STUDY_ROOTS="$T/registry2" bash "$S/write-config.sh" --register "$C" >/dev/null
has "--register adds the copy to that machine's registry" "$(cat "$T/registry2")" "me=$C/study.config"
is "--register changes nothing in the root" "$(cat "$C/study.config")" "$before"
is "the first machine's registry is untouched" "$(cat "$STUDY_ROOTS")" "me=$R/study.config"
is "a registered copy resolves from any directory" "$(cd / && STUDY_ROOTS="$T/registry2" bash "$S/resolve-subject.sh" rust)" "$C/subjects/rust"
has "a clean root has nothing to report" "$(bash "$S/check-root.sh" "$C")" "PASS  sync"
is "a clean root gives no overview note" "$(STUDY_ROOTS="$T/registry2" bash "$S/overview.sh" --stdout 2>&1 >/dev/null)" ""
cp "$C/subjects/rust/progress.md" "$C/subjects/rust/progress 2.md"
echo "x" > "$C/subjects/rust/materials/chapter 2.md"
note="$(STUDY_ROOTS="$T/registry2" bash "$S/overview.sh" --stdout 2>&1 >/dev/null)"
has "overview notes a conflict copy" "$note" "overview: note: subjects/rust/progress 2.md looks like a conflict copy"
hasnt "a learner's own file is not a conflict copy" "$note" "chapter 2.md"
has "the overview is still printed" "$(STUDY_ROOTS="$T/registry2" bash "$S/overview.sh" --stdout 2>/dev/null)" "| rust | Rust Programming |"
is "a conflict copy is a warning, not a failure" "$(code bash "$S/check-root.sh" "$C")" 0
has "check-root shows the conflict copy" "$(bash "$S/check-root.sh" "$C")" "WARN  sync"
if command -v git >/dev/null 2>&1 && git -C "$C" init -q 2>/dev/null; then
    has "a git study root reports uncommitted work" "$(bash "$S/check-root.sh" "$C")" "not committed"
fi
printf '<<<<<<< HEAD\n' >> "$C/subjects/rust/progress.md"
has "check-root names a file with merge markers" "$(bash "$S/check-root.sh" "$C" || true)" "subjects/rust/progress.md holds unresolved merge markers"
is "merge markers in the ledger are a failure" "$(code bash "$S/check-root.sh" "$C")" 1

# --- found from anywhere when one root is registered; health check
cd /
is "single registered root is found from any directory" "$(bash "$S/resolve-subject.sh" rust)" "$R/subjects/rust"
cd "$T"
is "check-root passes on a healthy root" "$(code bash "$S/check-root.sh" "$R")" 0
printf '4. **[Learn] Duplicate.**\n' >> "$A/plan.md"
is "duplicate step numbers are an error" "$(code bash "$S/init-progress.sh" aws-sa)" 1
is "check-root fails on a plan that does not parse" "$(code bash "$S/check-root.sh" "$R")" 1

echo
if [ "$fails" -gt 0 ]; then echo "study-root: $fails failure(s)"; exit 1; else echo "study-root: all assertions hold"; fi
