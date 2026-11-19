#!/usr/bin/env bash
# Create or update a study root: writes <dir>/study.config, creates the subjects directory,
# and registers the root by name in the per-user registry.
#
# Usage: write-config.sh <directory> [KEY=VALUE ...] [--force]
#        write-config.sh --register <directory>
#   Keys: STUDY_NAME, SUBJECTS_DIR, LEARNER_NAME, REVIEW_INTERVALS
# An existing study.config is left alone unless --force is given; with --force, keys that
# are not passed keep their current values. STUDY_FORMAT is written by the script and is
# not a key to pass.
# --register is for a study root that already exists, such as one copied or synced from
# another machine: it adds the root to this machine's registry and changes no file in it.
# Exit 1: bad usage. Exit 2: --register and no study.config in the directory.
# Exit 3: study.config exists and neither --force nor --register was given.
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"

dir=""; force=0; register=0
n_name=""; n_subjects=""; n_learner=""; n_intervals=""
for a in "$@"; do
    case "$a" in
        --force) force=1 ;;
        --register) register=1 ;;
        STUDY_NAME=*) n_name="${a#*=}" ;;
        SUBJECTS_DIR=*) n_subjects="${a#*=}" ;;
        LEARNER_NAME=*) n_learner="${a#*=}" ;;
        REVIEW_INTERVALS=*) n_intervals="${a#*=}" ;;
        *=*) echo "write-config: unknown key ${a%%=*}" >&2; exit 1 ;;
        -*) echo "write-config: unknown option $a" >&2; exit 1 ;;
        *) [ -z "$dir" ] && dir="$a" || { echo "write-config: one directory only" >&2; exit 1; } ;;
    esac
done
[ -n "$dir" ] || { echo "usage: write-config.sh <directory> [KEY=VALUE ...] [--force] | --register <directory>" >&2; exit 1; }
if [ "$register" -eq 1 ]; then
    if [ "$force" -eq 1 ] || [ -n "$n_name$n_subjects$n_learner$n_intervals" ]; then
        echo "write-config: --register takes a directory and nothing else" >&2; exit 1
    fi
    [ -f "$dir/study.config" ] || { echo "write-config: no study.config in $dir; without --register this script creates a study root there" >&2; exit 2; }
    dir="$(cd "$dir" && pwd)"
    load_config "$dir/study.config"
    registry_upsert "$STUDY_NAME" "$dir/study.config"
    echo "write-config: registered $STUDY_NAME in $(registry_file)"
    exit 0
fi
mkdir -p "$dir"
dir="$(cd "$dir" && pwd)"
cfg="$dir/study.config"

if [ -f "$cfg" ]; then
    if [ "$force" -ne 1 ]; then
        echo "write-config: $cfg exists; pass --force to update it, or --register to add it to this machine's registry unchanged" >&2; exit 3
    fi
    load_config "$cfg"
else
    SUBJECTS_DIR="subjects"; STUDY_NAME="$(kebab "$(basename "$dir")")"; LEARNER_NAME=""; REVIEW_INTERVALS="1 3 7 14 30"
    STUDY_FORMAT="$STUDY_FORMAT_CURRENT"
fi
[ -n "$n_name" ] && STUDY_NAME="$(kebab "$n_name")"
[ -n "$n_subjects" ] && SUBJECTS_DIR="$n_subjects"
[ -n "$n_learner" ] && LEARNER_NAME="$n_learner"
[ -n "$n_intervals" ] && REVIEW_INTERVALS="$n_intervals"
case "$REVIEW_INTERVALS" in *[!0-9\ ]*|"") echo "write-config: REVIEW_INTERVALS must be whole numbers of days separated by spaces" >&2; exit 1 ;; esac

q() { printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"; }
{
    echo "# study.config: settings for the study-partner skill."
    echo "# KEY=value, sourceable by sh. Paths are relative to this file's directory unless absolute."
    echo "# Never put secrets or credentials here; AI tools read this file."
    echo
    echo "# Name of this study root. Qualifies subject references as <name>:<subject> from any directory."
    echo "STUDY_NAME=$(q "$STUDY_NAME")"
    echo
    echo "# Where subject directories are created."
    echo "SUBJECTS_DIR=$(q "$SUBJECTS_DIR")"
    echo
    echo "# Optional: what the study partner calls you."
    echo "LEARNER_NAME=$(q "$LEARNER_NAME")"
    echo
    echo "# Days until a step is next suggested for review, as it moves up a level after each"
    echo "# review that goes well. After the last level no further review is suggested."
    echo "REVIEW_INTERVALS=$(q "$REVIEW_INTERVALS")"
    echo
    echo "# The format of this study root's files. Written by the scripts; leave it alone."
    echo "STUDY_FORMAT=$(q "$STUDY_FORMAT")"
} > "$cfg"
case "$SUBJECTS_DIR" in /*) mkdir -p "$SUBJECTS_DIR" ;; *) mkdir -p "$dir/$SUBJECTS_DIR" ;; esac
registry_upsert "$STUDY_NAME" "$cfg"
echo "write-config: wrote $cfg"
echo "write-config: registered $STUDY_NAME in $(registry_file)"
