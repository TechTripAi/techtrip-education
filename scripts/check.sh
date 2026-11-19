#!/usr/bin/env bash
# Repository health check for techtrip-education. Read-only; exits non-zero on any failure.
# Usage: bash scripts/check.sh
set -eu
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"
fails=0
tour=study-orientation   # the tour skill; its name is fixed by the catalog's docs/packaging.md
ok()   { printf 'ok    %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }
warn() { printf 'warn  %s\n' "$1"; }

# 1. shell syntax
for f in scripts/*.sh skills/*/scripts/*.sh skills/*/scripts/lib/*.sh tests/*.sh; do
    [ -f "$f" ] || continue
    if bash -n "$f" 2>/dev/null; then ok "syntax $f"; else fail "syntax $f"; fi
done

# 2. frontmatter: name equals dir, description length, model-invocable, README + tour coverage
for skill in skills/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"; md="$skill/SKILL.md"
    [ -f "$md" ] || { fail "$name: no SKILL.md"; continue; }
    fm_name="$(awk 'NR>1 && /^---/{exit} /^name:/{sub(/^name:[ \t]*/,""); print}' "$md" | tr -d '\r')"
    [ "$fm_name" = "$name" ] && ok "$name: name matches directory" || fail "$name: frontmatter name '$fm_name' != directory"
    desc="$(awk 'NR>1 && /^---/{exit} /^description:/{d=1; sub(/^description:[ \t]*/,""); s=$0; next} d && /^[a-z_-]+:/{d=0} d{s=s " " $0} END{print s}' "$md")"
    len=${#desc}
    [ "$len" -le 1024 ] && ok "$name: description $len chars" || fail "$name: description $len chars (max 1024)"
    grep -q '^disable-model-invocation: true' "$md" && fail "$name: must stay model-invocable" || ok "$name: model-invocable"
    grep -q "\*\*\`$name\`\*\*" README.md && ok "$name: listed in README" || fail "$name: not in README Skills included"
    if [ "$name" != "$tour" ] && [ -f "skills/$tour/SKILL.md" ]; then
        grep -q "$name" "skills/$tour/SKILL.md" && ok "$name: covered by $tour" || fail "$name: not mentioned in $tour"
    fi
done
# the tour skill exists and can be reached in plain words
if [ -f "skills/$tour/SKILL.md" ]; then
    ok "tour skill $tour present"
    tdesc="$(awk 'NR>1 && /^---/{exit} /^description:/{print}' "skills/$tour/SKILL.md")"
    for w in "tour" "how do I use"; do
        case "$tdesc" in *"$w"*) ok "$tour: description carries '$w'" ;; *) fail "$tour: description lacks '$w'" ;; esac
    done
else fail "no tour skill at skills/$tour"; fi
[ ! -d skills/brain-dump ] && ok "no skill named brain-dump (that name belongs to another plugin)" || fail "skills/brain-dump exists; the tour here is $tour"

# 2b. every format lives once: no ledger or overview table header outside references/
for f in skills/*/SKILL.md skills/*/roles/*.md; do
    [ -f "$f" ] || continue
    if grep -qE '^\| Step \| Phase \||^\| Subject \| Title \| Status \||^\| Id \| Source \||^\*\*(Target date|Stopped at):\*\*' "$f"; then fail "$f: embeds a format skeleton; point at references/ instead"
    else ok "$f: no embedded format skeleton"; fi
done

# 2c. every script the study-partner skill names exists; every reference and role it names exists
sp=skills/study-partner
if [ -f "$sp/SKILL.md" ]; then
    for s in $(grep -oE '<scripts>/[a-z-]+\.sh' "$sp/SKILL.md" | sed 's|<scripts>/||' | sort -u); do
        [ -f "$sp/scripts/$s" ] && ok "study-partner: script $s exists" || fail "study-partner: SKILL.md names scripts/$s, which does not exist"
    done
    for r in $(grep -ohE '(roles|references)/[a-z-]+\.md' "$sp/SKILL.md" "$sp"/roles/*.md "skills/$tour/SKILL.md" 2>/dev/null | sort -u); do
        [ -f "$sp/$r" ] && ok "study-partner: $r exists" || fail "a skill names $r, which does not exist"
    done
    lines="$(wc -l < "$sp/SKILL.md" | tr -d ' ')"
    [ "$lines" -le 160 ] && ok "study-partner: SKILL.md is $lines lines" || warn "study-partner: SKILL.md is $lines lines; move detail into roles/ or references/"
fi

# 2d. Agent Skills spec conformance (reference validator), claude-only keys stripped.
#     Stripped copies go under a fresh mktemp directory that the OS temp cleaner owns;
#     nothing here deletes anything.
if command -v uvx >/dev/null 2>&1; then
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/tted-check.XXXXXX")"
    for skill in skills/*/; do
        name="$(basename "$skill")"
        mkdir -p "$tmp/$name"
        awk 'NR==1{print; next} !fm && /^---/{fm=1} !fm && /^(argument-hint|disable-model-invocation):/{next} {print}' "$skill/SKILL.md" > "$tmp/$name/SKILL.md"
        if out="$(uvx --from skills-ref agentskills validate "$tmp/$name" 2>&1)"; then ok "$name: Agent Skills spec"
        else fail "$name: Agent Skills spec"; printf '%s\n' "$out" | sed 's/^/      /'; fi
    done
else
    warn "uvx not on PATH; skipped Agent Skills reference validator"
fi

# 3. versions and descriptions agree
if command -v node >/dev/null 2>&1; then
    v_root="$(node -e 'console.log(require("./plugin.json").version)')"
    v_claude="$(node -e 'console.log(require("./.claude-plugin/plugin.json").version)')"
    v_mkt="$(node -e 'console.log(require("./.claude-plugin/marketplace.json").plugins[0].version)')"
    v_log="$(grep -m1 -oE '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | tr -d '#[] ')"
    if [ "$v_root" = "$v_claude" ] && [ "$v_root" = "$v_log" ] && [ "$v_root" = "$v_mkt" ]; then ok "version $v_root agrees across both manifests, the marketplace entry and CHANGELOG"; else fail "version mismatch: plugin.json=$v_root claude=$v_claude marketplace=$v_mkt changelog=$v_log"; fi
    d_root="$(node -e 'console.log(require("./plugin.json").description)')"
    d_claude="$(node -e 'console.log(require("./.claude-plugin/plugin.json").description)')"
    [ "$d_root" = "$d_claude" ] && ok "descriptions agree across manifests" || fail "manifest descriptions differ"
    node -e 'const m=require("./plugin.json"); const allowed=new Set(["$schema","name","version","description","author","homepage","repository","license","keywords","extensions"]); const bad=Object.keys(m).filter(k=>!allowed.has(k)); if(bad.length){console.error("unknown fields: "+bad.join(",")); process.exit(1)} if(m.$schema!=="https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"){console.error("bad $schema"); process.exit(1)}' && ok "plugin.json conforms to Agent Plugins 1.0.0 field set" || fail "plugin.json does not conform to Agent Plugins 1.0.0"
else
    warn "node not on PATH; skipped manifest checks"
fi

# 3a. the Claude Code hooks file parses, and every script it calls exists
if [ -f hooks/hooks.json ] && command -v node >/dev/null 2>&1; then
    if node -e 'JSON.parse(require("fs").readFileSync("hooks/hooks.json","utf8"))' 2>/dev/null; then ok "hooks/hooks.json parses"; else fail "hooks/hooks.json is not valid JSON"; fi
    for s in $(grep -oE 'CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]+\.sh' hooks/hooks.json | sed 's|^CLAUDE_PLUGIN_ROOT}/||' | sort -u); do
        [ -f "$s" ] && ok "hooks: $s exists" || fail "hooks/hooks.json calls $s, which does not exist"
    done
fi

# 3c. no script reaches another machine
if grep -nE '(git|cp_git)[^#|]*[[:space:]](push|pull|fetch|clone|remote[[:space:]]+add)([[:space:]]|$)' skills/*/scripts/*.sh skills/*/scripts/lib/*.sh >/dev/null 2>&1; then
    fail "a script pushes, pulls, fetches, clones or adds a remote"
else ok "no script pushes, pulls, fetches, clones or adds a remote"; fi

# 3b. incubator never referenced by manifests
if grep -q incubator .claude-plugin/plugin.json plugin.json 2>/dev/null; then fail "manifests reference incubator/"; else ok "manifests do not reference incubator/"; fi

# 4. governance twins stay identical below their title line
if [ "$(tail -n +2 AGENTS.md)" = "$(tail -n +2 CLAUDE.md)" ]; then ok "AGENTS.md and CLAUDE.md agree"; else fail "AGENTS.md and CLAUDE.md differ below the title"; fi

# 5. line endings: no CR in tracked or new text
cr_scan() {
    { git ls-files 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | while IFS= read -r f; do
        [ -f "$f" ] || continue
        case "$f" in *.png|*.jpg|*.gif) continue ;; esac
        if grep -qI $'\r' -- "$f" 2>/dev/null; then printf '%s\n' "$f"; fi
    done
}
cr_hits="$(cr_scan)"
if [ -n "$cr_hits" ]; then fail "CR line endings in: $(printf '%s' "$cr_hits" | tr '\n' ' ')"; else ok "no CR line endings"; fi

# 6. tests
ran=0
for t in tests/*.sh; do
    [ -f "$t" ] || continue
    ran=1
    if out="$(bash "$t" 2>&1)"; then ok "test $t"; else fail "test $t"; printf '%s\n' "$out" | tail -15 | sed 's/^/      /'; fi
done
[ "$ran" = 1 ] || warn "no tests yet"

# 7. Claude Code validation, tolerating the one known warning
if command -v claude >/dev/null 2>&1; then
    out="$(claude plugin validate . 2>&1 || true)"
    filtered="$(printf '%s\n' "$out" | grep -iE 'warning|error' | grep -v 'CLAUDE.md at the plugin root' || true)"
    if printf '%s' "$out" | grep -qiE '\berror\b'; then fail "claude plugin validate reported errors:"; printf '%s\n' "$out"
    elif [ -n "$filtered" ]; then warn "claude plugin validate warnings:"; printf '%s\n' "$filtered"
    else ok "claude plugin validate"; fi
else
    warn "claude not on PATH; skipped plugin validate"
fi

echo
if [ "$fails" -gt 0 ]; then echo "check: $fails failure(s)"; exit 1; else echo "check: all green"; fi
