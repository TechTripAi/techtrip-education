#!/usr/bin/env bash
# Shared helpers for the study-partner scripts: find a study root by name or by walking up,
# load its study.config, resolve a subject reference, read brief fields, parse a study plan
# and the progress ledger, and do date arithmetic without depending on the local `date`.
#
# Source it; never execute it. Bash 3.2 compatible (no arrays). Nothing here reads or writes
# anything but study.config files, the per-user registry, and files inside a study root.
#
# Registry: $STUDY_ROOTS (default ~/.study-roots), one "name=/abs/path/study.config" per
# line. Written by write-config.sh. Per machine, per user, never part of the plugin, no secrets.

registry_file() { printf '%s' "${STUDY_ROOTS:-$HOME/.study-roots}"; }

# registry_lookup <name>: prints the config path for a registered study root, or nothing
registry_lookup() {
    f="$(registry_file)"
    [ -f "$f" ] || return 0
    sed -n "s/^$1=//p" "$f" | head -1
}

# registry_names: prints every registered name, one per line
registry_names() {
    f="$(registry_file)"
    [ -f "$f" ] || return 0
    sed -n 's/^\([^=#][^=]*\)=.*/\1/p' "$f"
}

# registry_upsert <name> <config-path>: adds or replaces the line for <name>; also drops any
# other name that points at the same config (a rename)
registry_upsert() {
    f="$(registry_file)"
    if [ ! -f "$f" ]; then (umask 077; : > "$f"); fi
    tmp="$f.tmp.$$"
    grep -v -e "^$1=" -e "=$2\$" "$f" > "$tmp" 2>/dev/null || true
    printf '%s=%s\n' "$1" "$2" >> "$tmp"
    mv "$tmp" "$f"
    chmod 600 "$f"
}

# find_config [name]: with a name, the registry. Without: $STUDY_CONFIG, then walk up from
# $PWD, then the registry when exactly one study root is registered (a learner usually
# starts the AI tool from somewhere other than the study root).
find_config() {
    if [ -n "${1:-}" ]; then
        registry_lookup "$1"; return 0
    fi
    if [ -n "${STUDY_CONFIG:-}" ] && [ -f "$STUDY_CONFIG" ]; then printf '%s' "$STUDY_CONFIG"; return 0; fi
    d="$PWD"
    while [ "$d" != "/" ] && [ -n "$d" ]; do
        if [ -f "$d/study.config" ]; then printf '%s' "$d/study.config"; return 0; fi
        d="$(dirname "$d")"
    done
    n="$(registry_names | sed '/^$/d' | wc -l | tr -d ' ')"
    if [ "$n" -eq 1 ]; then registry_lookup "$(registry_names | head -1)"; fi
    return 0
}

# load_config <config-path>: sources it and sets defaults; sets ST_CONFIG, ST_ROOT,
# ST_SUBJECTS, ST_ARCHIVE, ST_PACKETS
load_config() {
    ST_CONFIG="$1"
    ST_ROOT="$(cd "$(dirname "$1")" && pwd)"
    SUBJECTS_DIR=""; STUDY_NAME=""; LEARNER_NAME=""; REVIEW_INTERVALS=""
    # shellcheck disable=SC1090
    . "$1"
    : "${SUBJECTS_DIR:=subjects}"
    : "${STUDY_NAME:=$(basename "$ST_ROOT")}"
    : "${LEARNER_NAME:=}"
    : "${REVIEW_INTERVALS:=1 3 7 14 30}"
    case "$SUBJECTS_DIR" in /*) ST_SUBJECTS="$SUBJECTS_DIR" ;; *) ST_SUBJECTS="$ST_ROOT/$SUBJECTS_DIR" ;; esac
    ST_ARCHIVE="$ST_ROOT/archive"
    ST_PACKETS="$ST_ROOT/packets"
}

# open_root [name]: find and load a study root, or exit 2 with a message that says what to do
open_root() {
    cfg="$(find_config "${1:-}")"
    if [ -z "$cfg" ] || [ ! -f "$cfg" ]; then
        if [ -n "${1:-}" ]; then
            echo "study: no study root named '$1'. Registered: $(registry_names | tr '\n' ' ')" >&2
        elif [ -n "$(registry_names)" ]; then
            echo "study: more than one study root is registered; say which: $(registry_names | tr '\n' ' ')" >&2
        else
            echo "study: no study root yet. Create one with write-config.sh <directory>, or register one that is already on this machine with write-config.sh --register <directory>." >&2
        fi
        return 2
    fi
    load_config "$cfg"
}

# load_root_for <subject-dir>: load the study root a subject belongs to. Scripts call this
# after resolving a subject, because the resolver runs in a subshell and its settings do not
# reach the caller.
load_root_for() {
    cfg="$(cd "$1" && STUDY_CONFIG='' find_config)"
    if [ -n "$cfg" ] && [ -f "$cfg" ]; then load_config "$cfg"; else return 1; fi
}

# sync_notes <study-root>: one "LEVEL<TAB>text" line for each sign that the study root was
# changed in two places, or holds work another machine cannot see yet. Read-only. Prints
# nothing when there is none. FAIL is a file the scripts parse that holds merge markers;
# everything else is WARN. It reports and never blocks: nothing calls it to stop work.
sync_notes() {
    sn_root="$1"; sn_tab="$(printf '\t')"
    # copies a file-sync tool leaves when two machines changed the same file
    find "$sn_root" \( -name .git -o -name materials -o -name packets \) -prune -o -type f \
        \( -name '*.sync-conflict-*' -o -name '*conflicted copy*' -o -name '* [0-9].md' \) -print 2>/dev/null |
        sort | while IFS= read -r sn_f; do
            printf 'WARN%s%s looks like a conflict copy from a sync tool; compare it with the original, keep what is right, then move it out\n' "$sn_tab" "${sn_f#"$sn_root"/}"
        done
    # merge markers left in a file the scripts read
    for sn_f in "$sn_root"/overview.md "$ST_SUBJECTS"/*/brief.md "$ST_SUBJECTS"/*/plan.md \
        "$ST_SUBJECTS"/*/progress.md "$ST_SUBJECTS"/*/sources.md "$ST_SUBJECTS"/*/glossary.md; do
        [ -f "$sn_f" ] || continue
        if tr -d '\r' < "$sn_f" | grep -qE '^(<<<<<<<|>>>>>>>) '; then
            printf 'FAIL%s%s holds unresolved merge markers; resolve them before more is recorded\n' "$sn_tab" "${sn_f#"$sn_root"/}"
        fi
    done
    # when the study root is its own git repository: work that is not merged, committed or pushed
    command -v git >/dev/null 2>&1 || return 0
    sn_up="$(git -C "$sn_root" rev-parse --show-cdup 2>/dev/null)" || return 0
    [ -z "$sn_up" ] || return 0
    sn_n="$(git -C "$sn_root" ls-files -u 2>/dev/null | cut -f2 | sort -u | sed '/^$/d' | wc -l | tr -d ' ')"
    [ "$sn_n" -eq 0 ] || printf 'WARN%sgit: %s file(s) with an unfinished merge\n' "$sn_tab" "$sn_n"
    sn_n="$(git -C "$sn_root" status --porcelain 2>/dev/null | sed '/^$/d' | wc -l | tr -d ' ')"
    [ "$sn_n" -eq 0 ] || printf 'WARN%sgit: %s change(s) not committed; another machine will not see them until they are committed and synced\n' "$sn_tab" "$sn_n"
    sn_n="$(git -C "$sn_root" rev-list --count '@{u}..HEAD' 2>/dev/null)" || sn_n=0
    [ "${sn_n:-0}" -eq 0 ] || printf 'WARN%sgit: %s commit(s) not pushed\n' "$sn_tab" "$sn_n"
    return 0
}

# kebab <text>: lowercase, non-alphanumerics to "-", at most 40 characters
kebab() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-40 | sed -E 's/-+$//'; }

# today: the current date, or $STUDY_TODAY (YYYY-MM-DD) when set, which the tests use
today() { printf '%s' "${STUDY_TODAY:-$(date +%Y-%m-%d)}"; }

# The date functions are pure awk, so they behave the same with BSD date, GNU date and Git Bash.
AWK_DATES='
function d2n(y,m,d,   a,yy,mm){ a=int((14-m)/12); yy=y+4800-a; mm=m+12*a-3
    return d+int((153*mm+2)/5)+365*yy+int(yy/4)-int(yy/100)+int(yy/400)-32045 }
function n2d(j,   a,b,c,d,e,m){ a=j+32044; b=int((4*a+3)/146097); c=a-int(146097*b/4)
    d=int((4*c+3)/1461); e=c-int(1461*d/4); m=int((5*e+2)/153)
    return sprintf("%04d-%02d-%02d", 100*b+d-4800+int(m/10), m+3-12*int(m/10), e-int((153*m+2)/5)+1) }
function ymd(s,   p){ split(s,p,"-"); return d2n(p[1]+0,p[2]+0,p[3]+0) }'

# date_add <YYYY-MM-DD> <days>: the date that many days later
date_add() { awk -v s="$1" -v n="$2" "$AWK_DATES"' BEGIN { print n2d(ymd(s)+n) }'; }

# days_between <from> <to>: whole days from the first date to the second (negative if earlier)
days_between() { awk -v a="$1" -v b="$2" "$AWK_DATES"' BEGIN { print ymd(b)-ymd(a) }'; }

# is_date <text>: true when the text is YYYY-MM-DD
is_date() { case "$1" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) return 0 ;; *) return 1 ;; esac; }

# brief_field <subject-dir> <Label>: the value of a "**Label:** value" line in brief.md
brief_field() { [ -f "$1/brief.md" ] && tr -d '\r' < "$1/brief.md" | sed -nE "s/^\*\*$2:\*\* *//p" | head -1 || true; }

# progress_field <subject-dir> <Label>: the same, from progress.md
progress_field() { [ -f "$1/progress.md" ] && tr -d '\r' < "$1/progress.md" | sed -nE "s/^\*\*$2:\*\* *//p" | head -1 || true; }

# subject_title <subject-dir>: the first "# " heading of brief.md, or the directory name
subject_title() {
    t=""
    [ -f "$1/brief.md" ] && t="$(tr -d '\r' < "$1/brief.md" | sed -nE 's/^# +//p' | head -1)"
    [ -n "$t" ] && printf '%s' "$t" || basename "$1"
}

# set_brief_field <subject-dir> <Label> <value>: replace the value of a "**Label:**" line
set_brief_field() {
    tmp="$1/brief.md.tmp.$$"
    tr -d '\r' < "$1/brief.md" | awk -v l="**$2:**" -v v="$3" 'index($0,l)==1 && !done { print l " " v; done=1; next } { print }' > "$tmp"
    mv "$tmp" "$1/brief.md"
}

# plan_steps <subject-dir>: the steps of plan.md as  id<TAB>phase<TAB>kind<TAB>title
# A phase is a "## Phase X: Title" heading; a step is a column-zero
# "N. **[Learn] Title.** ..." line. The id is the phase letter plus the number: A1, B3.
plan_steps() {
    [ -f "$1/plan.md" ] || return 0
    tr -d '\r' < "$1/plan.md" | awk '
        /^## +Phase +[A-Za-z]+/ { p=$0; sub(/^## +Phase +/,"",p); sub(/[^A-Za-z].*$/,"",p); phase=toupper(p); next }
        /^[0-9]+\. +\*\*/ {
            n=$0; sub(/\..*$/,"",n)
            t=$0; sub(/^[0-9]+\. +\*\*/,"",t); sub(/\*\*.*$/,"",t)
            kind="-"
            if (t ~ /^\[/) { kind=t; sub(/^\[/,"",kind); sub(/\].*$/,"",kind); sub(/^\[[^]]*\] */,"",t) }
            sub(/[.:]+$/,"",t); gsub(/\|/,"/",t)
            ph=(phase==""?"-":phase)
            printf "%s%d\t%s\t%s\t%s\n", (phase==""?"X":phase), n+0, ph, kind, t }'
}

# plan_step_detail <subject-dir> <id>: three lines for one step: title, done-when, sources
plan_step_detail() {
    tr -d '\r' < "$1/plan.md" | awk -v want="$2" '
        /^## +Phase +[A-Za-z]+/ { p=$0; sub(/^## +Phase +/,"",p); sub(/[^A-Za-z].*$/,"",p); phase=toupper(p); grab=0; next }
        /^[0-9]+\. +\*\*/ {
            if (grab) exit
            n=$0; sub(/\..*$/,"",n)
            if (((phase==""?"X":phase) (n+0)) != want) next
            t=$0; sub(/^[0-9]+\. +\*\*/,"",t); sub(/\*\*.*$/,"",t); sub(/^\[[^]]*\] */,"",t); sub(/[.:]+$/,"",t)
            s=""; if (match($0,/Sources?: *[^.]*/)) { s=substr($0,RSTART,RLENGTH); sub(/^Sources?: */,"",s) }
            title=t; src=s; grab=1; next }
        grab && /^[ \t]+Done when:/ { d=$0; sub(/^[ \t]+Done when: */,"",d); done=d }
        grab && /^(## |Checkpoint )/ { exit }
        END { if (title!="") { print title; print done; print src } }'
}

# plan_checkpoints <subject-dir>: "Checkpoint X: text" lines as  CP-X<TAB>text
plan_checkpoints() {
    [ -f "$1/plan.md" ] || return 0
    tr -d '\r' < "$1/plan.md" | awk '
        /^Checkpoint +[A-Za-z]+/ { c=$0; sub(/^Checkpoint +/,"",c); id=c; sub(/[^A-Za-z].*$/,"",id)
            sub(/^[A-Za-z]+[:. ]*/,"",c); gsub(/\|/,"/",c); printf "CP-%s\t%s\n", toupper(id), c }'
}

# step_rows <subject-dir>: the step table of progress.md as
#   id<TAB>phase<TAB>kind<TAB>title<TAB>status<TAB>level<TAB>last<TAB>next<TAB>note
step_rows() {
    [ -f "$1/progress.md" ] || return 0
    tr -d '\r' < "$1/progress.md" | awk -F'|' '
        function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
        /^\| *[A-Z]+[0-9]+ *\|/ { printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", trim($2),trim($3),trim($4),trim($5),trim($6),trim($7),trim($8),trim($9),trim($10) }'
}

# checkpoint_rows <subject-dir>: the checkpoint table as  id<TAB>text<TAB>status
checkpoint_rows() {
    [ -f "$1/progress.md" ] || return 0
    tr -d '\r' < "$1/progress.md" | awk -F'|' '
        function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
        /^\| *CP-[A-Z]+ *\|/ { printf "%s\t%s\t%s\n", trim($2),trim($3),trim($4) }'
}

# norm_step <text>: "a1" or "A1" to "A1"; "cp-a" to "CP-A"
norm_step() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }

# --- subject references -------------------------------------------------------------------
# resolve_subject <ref>: prints the absolute subject directory for
#   [<root>:]<subject directory name | fragment of the name or title | path>
# Exit 2: no study root or no match (message lists the subjects, and says so when the match
# is archived). Exit 4: ambiguous (message lists the matches). Exit 5: no subject named
# (caller shows the overview). Loads the study root as a side effect.
resolve_subject() {
    ref="${1:-}"; rootname=""; sub="$ref"
    case "$ref" in
        /*|./*|../*) ;;
        *:*) rootname="${ref%%:*}"; sub="${ref#*:}" ;;
    esac
    if [ -n "$sub" ] && [ -d "$sub" ] && [ -f "$sub/brief.md" ]; then
        cfg="$(cd "$sub" && STUDY_CONFIG= find_config)"
        [ -n "$cfg" ] && [ -f "$cfg" ] && load_config "$cfg" || true
        (cd "$sub" && pwd); return 0
    fi
    open_root "$rootname" || return 2
    [ -n "$sub" ] || return 5
    want="$(printf '%s' "$sub" | tr '[:upper:]' '[:lower:]')"
    exact=""; matches=""; all=""
    for sdir in "$ST_SUBJECTS"/*/; do
        [ -d "$sdir" ] || continue
        sdir="${sdir%/}"; [ -f "$sdir/brief.md" ] || continue
        base="$(basename "$sdir")"; all="$all $base"
        lc_base="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
        lc_title="$(subject_title "$sdir" | tr '[:upper:]' '[:lower:]')"
        if [ "$lc_base" = "$want" ]; then exact="$sdir"; fi
        case "$lc_base $lc_title" in *"$want"*) matches="$matches
$sdir" ;; esac
    done
    if [ -n "$exact" ]; then printf '%s' "$exact"; return 0; fi
    matches="$(printf '%s' "$matches" | sed '/^$/d')"
    count="$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')"
    if [ "$count" -eq 0 ]; then
        if [ -d "$ST_ARCHIVE/$(kebab "$sub")" ]; then
            echo "study: '$sub' is closed and archived in $STUDY_NAME; reopen it with close-subject.sh --reopen $(kebab "$sub")" >&2
        else
            echo "study: no subject matching '$sub' in $STUDY_NAME; subjects:$all" >&2
        fi
        return 2
    fi
    if [ "$count" -gt 1 ]; then
        echo "study: '$sub' is ambiguous in $STUDY_NAME; say which:" >&2
        printf '%s\n' "$matches" | while IFS= read -r m; do echo "  $STUDY_NAME:$(basename "$m")  ($(subject_title "$m"))" >&2; done
        return 4
    fi
    printf '%s' "$matches"
}
