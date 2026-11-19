#!/usr/bin/env bash
# Build or extend a subject's progress.md from its plan.md.
# With no progress.md, writes the whole ledger. With one, adds a row for every plan step and
# checkpoint that is not in it yet, and brings the description of an existing checkpoint
# into line with the plan when the plan's wording changed. A checkpoint's status, every step
# row and the session entries are never changed, so a plan can change over time.
#
# Usage: init-progress.sh <subject ref or directory> [--dry-run]
# Exit 1: bad usage or a plan that does not parse. Exit 2/4: the subject did not resolve.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

ref=""; dry=0
for a in "$@"; do
    case "$a" in --dry-run) dry=1 ;; -*) echo "init-progress: unknown option $a" >&2; exit 1 ;; *) ref="$a" ;; esac
done
[ -n "$ref" ] || { echo "usage: init-progress.sh <subject ref or directory> [--dry-run]" >&2; exit 1; }
rc=0; sdir="$(resolve_subject "$ref")" || rc=$?
[ "$rc" -eq 0 ] || exit "$rc"
[ -f "$sdir/plan.md" ] || { echo "init-progress: $sdir has no plan.md yet" >&2; exit 1; }

tab="$(printf '\t')"
steps="$(plan_steps "$sdir")"
cps="$(plan_checkpoints "$sdir")"
count="$(printf '%s\n' "$steps" | sed '/^$/d' | wc -l | tr -d ' ')"
[ "$count" -gt 0 ] || { echo "init-progress: plan.md has no steps. A step is a line such as: 1. **[Learn] Title.** ..." >&2; exit 1; }
dups="$(printf '%s\n' "$steps" | cut -f1 | sed 's/^[A-Z]*//' | sort | uniq -d | tr '\n' ' ')"
[ -z "$dups" ] || { echo "init-progress: step numbers used twice in plan.md: $dups" >&2; exit 1; }
if printf '%s\n' "$steps" | awk -F'\t' '$2=="-"{f=1} END{exit f?0:1}'; then
    echo "init-progress: warning: a step appears before the first '## Phase X: Title' heading" >&2
fi
odd="$(printf '%s\n' "$steps" | awk -F'\t' '$3!="Learn" && $3!="Apply" {printf "%s ", $1}')"
[ -z "$odd" ] || echo "init-progress: warning: steps without a [Learn] or [Apply] tag: $odd" >&2
srow() { printf '| %s | %s | %s | %s | pending | 0 | - | - | |\n' "$1" "$2" "$3" "$4"; }
crow() { printf '| %s | %s | pending |\n' "$1" "$2"; }

if [ ! -f "$sdir/progress.md" ]; then
    out="$( {
        echo "# $(subject_title "$sdir"): progress"
        echo
        echo "**Last session:** -"
        echo
        echo "## Steps"
        echo
        echo "| Step | Phase | Kind | Title | Status | Level | Last worked | Next review | Note |"
        echo "|---|---|---|---|---|---|---|---|---|"
        printf '%s\n' "$steps" | while IFS="$tab" read -r id ph kind title; do srow "$id" "$ph" "$kind" "$title"; done
        echo
        echo "## Checkpoints"
        echo
        echo "| Checkpoint | Covers | Status |"
        echo "|---|---|---|"
        printf '%s\n' "$cps" | sed '/^$/d' | while IFS="$tab" read -r id text; do crow "$id" "$text"; done
        echo
        echo "## Sessions"
    } )"
    if [ "$dry" -eq 1 ]; then printf '%s\n' "$out"; echo "init-progress: dry run, nothing written ($count steps)" >&2
    else printf '%s\n' "$out" > "$sdir/progress.md"; echo "init-progress: wrote $sdir/progress.md ($count steps)"; fi
    exit 0
fi

have="$(step_rows "$sdir" | cut -f1)"
havec="$(checkpoint_rows "$sdir" | cut -f1)"
news="$(printf '%s\n' "$steps" | while IFS="$tab" read -r id ph kind title; do
    printf '%s\n' "$have" | grep -qx "$id" || srow "$id" "$ph" "$kind" "$title"
done)"
newc="$(printf '%s\n' "$cps" | sed '/^$/d' | while IFS="$tab" read -r id text; do
    printf '%s\n' "$havec" | grep -qx -- "$id" || crow "$id" "$text"
done)"
# checkpoints already in the ledger whose description no longer matches the plan
cpmap="$(printf '%s\n' "$cps" | sed '/^$/d')"
stale="$(checkpoint_rows "$sdir" | while IFS="$tab" read -r id text st; do
    new="$(printf '%s\n' "$cpmap" | CP_ID="$id" awk -F'\t' '$1==ENVIRON["CP_ID"] { print $2; exit }')"
    [ -z "$new" ] || [ "$new" = "$text" ] || printf '%s\n' "$id"
done)"
added="$(printf '%s\n' "$news" | sed '/^$/d' | wc -l | tr -d ' ')"
addedc="$(printf '%s\n' "$newc" | sed '/^$/d' | wc -l | tr -d ' ')"
stalec="$(printf '%s\n' "$stale" | sed '/^$/d' | wc -l | tr -d ' ')"
if [ "$added" -eq 0 ] && [ "$addedc" -eq 0 ] && [ "$stalec" -eq 0 ]; then echo "init-progress: progress.md already has every step ($count)"; exit 0; fi
if [ "$dry" -eq 1 ]; then
    [ -z "$news" ] || printf '%s\n' "$news"; [ -z "$newc" ] || printf '%s\n' "$newc"
    [ "$stalec" -eq 0 ] || echo "would update the description of: $(printf '%s' "$stale" | tr '\n' ' ')"
    echo "init-progress: dry run, nothing written ($added new steps, $addedc new checkpoints, $stalec checkpoint descriptions to update)" >&2; exit 0
fi
tmp="$sdir/progress.md.tmp.$$"
# The new rows reach awk through the environment: with several rows the value has newlines,
# which BSD awk (macOS) refuses in a -v assignment, and -v would also rewrite backslashes.
tr -d '\r' < "$sdir/progress.md" | ADDS="$news" ADDC="$newc" CPMAP="$cpmap" awk '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    BEGIN { adds=ENVIRON["ADDS"]; addc=ENVIRON["ADDC"]
            n=split(ENVIRON["CPMAP"], m, "\n")
            for (i=1;i<=n;i++) { t=index(m[i],"\t"); if (t) want[substr(m[i],1,t-1)]=substr(m[i],t+1) } }
    { if ($0 ~ /^## /) sect=$0
      if (sect ~ /^## Checkpoints/ && $0 ~ /^\| *CP-[A-Z]+ *\|/) {
          k=split($0, c, "|"); id=trim(c[2])
          if (k>=4 && (id in want) && trim(c[3])!=want[id]) $0="| " id " | " want[id] " | " trim(c[4]) " |" }
      lines[NR]=$0
      if (sect ~ /^## Steps/ && ($0 ~ /^\| *[A-Z]+[0-9]+ *\|/ || $0 ~ /^\|---/)) lasts=NR
      if (sect ~ /^## Checkpoints/ && ($0 ~ /^\| *CP-[A-Z]+ *\|/ || $0 ~ /^\|---/)) lastc=NR }
    END { for (i=1;i<=NR;i++) { print lines[i]
              if (i==lasts && adds!="") print adds
              if (i==lastc && addc!="") print addc } }' > "$tmp" \
    || { rm -f "$tmp"; echo "init-progress: could not add the new rows; progress.md is unchanged" >&2; exit 1; }
mv "$tmp" "$sdir/progress.md"
echo "init-progress: added $added new steps and $addedc new checkpoints to $sdir/progress.md"
[ "$stalec" -eq 0 ] || echo "init-progress: updated the description of $stalec checkpoint(s) to match the plan: $(printf '%s' "$stale" | tr '\n' ' ')"
