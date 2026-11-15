#!/usr/bin/env bash
# Print the absolute directory of a subject.
#
# Usage: resolve-subject.sh [<root>:]<subject name | fragment of the name or title | path>
# Exit 2: no study root or no match. Exit 4: ambiguous; the matches are listed.
# Exit 5: no subject was named; show the overview instead (overview.sh --stdout).
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
. "$SCRIPT_DIR/lib/resolve.sh"
rc=0
out="$(resolve_subject "${1:-}")" || rc=$?
if [ "$rc" -eq 5 ]; then echo "study: no subject named; run overview.sh --stdout for every subject" >&2; exit 5; fi
[ "$rc" -eq 0 ] || exit "$rc"
printf '%s\n' "$out"
