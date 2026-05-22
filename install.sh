#!/usr/bin/env bash
set -euo pipefail

# ── vibe-skill installer ────────────────────────────────────────────────────
# Interactive install/update for target projects.
# Safe: never overwrites user-configured project state (scheduler.yaml,
# research.jsonl, knowledge.md, etc.)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

info()  { echo -e "${CYAN}▸${RESET} $1"; }
ok()    { echo -e "${GREEN}✓${RESET} $1"; }
warn()  { echo -e "${YELLOW}!${RESET} $1"; }
err()   { echo -e "${RED}✗${RESET} $1"; }
header(){ echo -e "\n${BOLD}$1${RESET}"; }

# ── Gather input ────────────────────────────────────────────────────────────

header "vibe-skill installer"
echo ""

# Project path
if [ -n "${1:-}" ] && [ -d "$1" ]; then
    TARGET="$(cd "$1" && pwd)"
else
    read -rp "Project folder path: " TARGET
    TARGET="${TARGET/#\~/$HOME}"
    TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || { err "Directory not found: $TARGET"; exit 1; }
fi

if [ ! -d "$TARGET" ]; then
    err "Directory not found: $TARGET"
    exit 1
fi

PROJECT_NAME="$(basename "$TARGET")"
echo ""
info "Target: ${BOLD}$PROJECT_NAME${RESET} ($TARGET)"

# Detect existing install
EXISTING=false
if [ -d "$TARGET/.claude/vibe-skill/tools" ]; then
    EXISTING=true
    ok "Existing installation detected — will update"
else
    info "Fresh install"
fi

# Platform selection
echo ""
header "Which platforms do you use?"
echo "  1) Claude Code only"
echo "  2) Codex only"
echo "  3) Both Claude Code and Codex"
echo ""
read -rp "Select [1-3]: " PLATFORM_CHOICE

INSTALL_CLAUDE=false
INSTALL_CODEX=false
case "$PLATFORM_CHOICE" in
    1) INSTALL_CLAUDE=true ;;
    2) INSTALL_CODEX=true ;;
    3) INSTALL_CLAUDE=true; INSTALL_CODEX=true ;;
    *) err "Invalid choice"; exit 1 ;;
esac

# ── File lists ──────────────────────────────────────────────────────────────

# Tools: always overwrite (these are the framework code)
TOOLS=(
    delegate
    delegate-ast-check
    delegate-audit
    delegate-batch
    delegate-chain
    delegate-check-brief
    delegate-check-duplicates
    delegate-clean
    delegate-contracts
    delegate-correct
    delegate-dashboard
    delegate-distill
    delegate-failures
    delegate-knowledge
    delegate-learnings
    delegate-parallel
    delegate-reject
    delegate-replay
    delegate-report
    delegate-research
    delegate-rollback
    delegate-router
    delegate-scheduler
    delegate-watch
    delegate-research-intake
    jina-search
    vibe-delegate
)

ADAPTERS=(codex opencode pi vibe)

# Chain YAMLs: always overwrite (framework-provided workflows)
CHAINS=(
    architect.yaml
    docs.yaml
    fix.yaml
    fortress.yaml
    ironclad.yaml
    quick.yaml
    race.yaml
    steady.yaml
    tournament.yaml
    web.yaml
)

# Codex skills: always overwrite
CODEX_SKILLS=(
    vibe
    vibe-audit
    vibe-mode
    vibe-model-clear
    vibe-model-pick
    vibe-reindex
    vibe-report
    vibe-research
    vibe-research-intake
    vibe-scheduler
    vibeoff
    vibeon
    vibestatus
)

# Project state: NEVER overwrite if exists (user-configured)
PROJECT_STATE=(
    scheduler.yaml
    project-brief.md
    correction-prompt.txt
    runs.jsonl
    failures.jsonl
    learnings.jsonl
    auto.flag
    model.flag
    mode.flag
    knowledge.md
    knowledge-meta.json
    audit-findings.jsonl
    audit.pid
    research.jsonl
    research.pid
    scheduler.pid
    scheduler-state.json
    scheduler.log
    plan.md
    research-state.json
    web-research-raw.md
    web-research-report.md
    delegate.pid
    active-model
    timeout
)

# ── Install functions ───────────────────────────────────────────────────────

install_tools() {
    header "Installing tools..."
    local dest="$TARGET/.claude/vibe-skill/tools"
    mkdir -p "$dest/adapters"

    local count=0
    for tool in "${TOOLS[@]}"; do
        if [ -f "$SCRIPT_DIR/tools/$tool" ]; then
            cp "$SCRIPT_DIR/tools/$tool" "$dest/$tool"
            chmod +x "$dest/$tool"
            count=$((count + 1))
        fi
    done

    for adapter in "${ADAPTERS[@]}"; do
        if [ -f "$SCRIPT_DIR/tools/adapters/$adapter" ]; then
            cp "$SCRIPT_DIR/tools/adapters/$adapter" "$dest/adapters/$adapter"
            chmod +x "$dest/adapters/$adapter"
            count=$((count + 1))
        fi
    done

    ok "$count tools installed"
}

install_chains() {
    header "Installing chain configs..."
    local dest="$TARGET/.claude/vibe-skill/.delegate/chains"
    mkdir -p "$dest"

    local count=0
    for chain in "${CHAINS[@]}"; do
        if [ -f "$SCRIPT_DIR/.delegate/chains/$chain" ]; then
            cp "$SCRIPT_DIR/.delegate/chains/$chain" "$dest/$chain"
            count=$((count + 1))
        fi
    done

    ok "$count chains installed"
}

install_scheduler_default() {
    local dest="$TARGET/.claude/vibe-skill/.delegate/scheduler.yaml"
    if [ -f "$dest" ]; then
        warn "scheduler.yaml exists — keeping your config"
    else
        cp "$SCRIPT_DIR/.delegate/scheduler.yaml" "$dest"
        ok "Default scheduler.yaml created"
    fi
}

install_project_state() {
    header "Setting up project state..."
    local dest="$TARGET/.delegate"
    mkdir -p "$dest/sessions"

    # Only create scheduler.yaml if it doesn't exist
    if [ ! -f "$dest/scheduler.yaml" ]; then
        cp "$SCRIPT_DIR/.delegate/scheduler.yaml" "$dest/scheduler.yaml"
        ok "Default scheduler.yaml created in .delegate/"
    else
        warn "scheduler.yaml exists in .delegate/ — keeping your config"
    fi

    ok "Project state directory ready (.delegate/)"
}

install_claude_code() {
    header "Installing Claude Code skill..."

    # SKILL.md goes to the commands directory
    local commands_dir="$TARGET/.claude/commands"
    mkdir -p "$commands_dir"

    # Copy SKILL.md as the /vibe command
    cp "$SCRIPT_DIR/SKILL.md" "$commands_dir/vibe.md"
    ok "Installed /vibe command"

    # Copy sub-command skill files if they exist
    for f in "$SCRIPT_DIR"/VIBE-*.md "$SCRIPT_DIR"/VIBEON.md "$SCRIPT_DIR"/VIBEOFF.md "$SCRIPT_DIR"/VIBESTATUS.md; do
        if [ -f "$f" ]; then
            local basename
            basename="$(basename "$f" .md)"
            local lower
            lower="$(echo "$basename" | tr '[:upper:]' '[:lower:]' | tr '-' '-')"
            cp "$f" "$commands_dir/$lower.md"
        fi
    done

    ok "Claude Code skills installed to .claude/commands/"
}

install_codex() {
    header "Installing Codex skills..."

    # AGENTS.md (orchestration instructions)
    local codex_dir="$TARGET/.codex"
    mkdir -p "$codex_dir"
    cp "$SCRIPT_DIR/CODEX-SKILL.md" "$codex_dir/AGENTS.md"
    ok "Installed .codex/AGENTS.md"

    # Skill definitions
    local skills_dir="$TARGET/.agents/skills"
    mkdir -p "$skills_dir"

    local count=0
    for skill in "${CODEX_SKILLS[@]}"; do
        if [ -d "$SCRIPT_DIR/.agents/skills/$skill" ]; then
            mkdir -p "$skills_dir/$skill"
            cp "$SCRIPT_DIR/.agents/skills/$skill/SKILL.md" "$skills_dir/$skill/SKILL.md"
            count=$((count + 1))
        fi
    done

    ok "$count Codex skills installed to .agents/skills/"
}

update_gitignore() {
    header "Updating .gitignore..."
    local gitignore="$TARGET/.gitignore"

    # Entries that should be gitignored in the target project
    local entries=(
        ".delegate/sessions/"
        ".delegate/runs.jsonl"
        ".delegate/failures.jsonl"
        ".delegate/learnings.jsonl"
        ".delegate/audit-findings.jsonl"
        ".delegate/research.jsonl"
        ".delegate/knowledge.md"
        ".delegate/knowledge-meta.json"
        ".delegate/research-state.json"
        ".delegate/scheduler-state.json"
        ".delegate/scheduler.log"
        ".delegate/web-research-raw.md"
        ".delegate/web-research-report.md"
        ".delegate/plan.md"
        ".delegate/project-brief.md"
        ".delegate/correction-prompt.txt"
        ".delegate/*.pid"
        ".delegate/active-model"
        ".delegate/auto.flag"
        ".delegate/model.flag"
        ".delegate/mode.flag"
        ".delegate/timeout"
    )

    if [ ! -f "$gitignore" ]; then
        touch "$gitignore"
    fi

    local added=0
    for entry in "${entries[@]}"; do
        if ! grep -qF "$entry" "$gitignore" 2>/dev/null; then
            echo "$entry" >> "$gitignore"
            added=$((added + 1))
        fi
    done

    if [ "$added" -gt 0 ]; then
        ok "Added $added entries to .gitignore"
    else
        ok ".gitignore already up to date"
    fi
}

# ── Summary ─────────────────────────────────────────────────────────────────

print_summary() {
    echo ""
    header "Installation complete!"
    echo ""
    echo -e "  Project:    ${BOLD}$PROJECT_NAME${RESET}"
    echo -e "  Path:       $TARGET"
    local platforms=""
    $INSTALL_CLAUDE && platforms+="Claude Code "
    $INSTALL_CODEX && platforms+="Codex"
    echo -e "  Platforms:  $platforms"
    echo -e "  Mode:       $( $EXISTING && echo 'Update' || echo 'Fresh install' )"
    echo ""

    echo -e "${DIM}Installed layout:${RESET}"
    echo "  .claude/vibe-skill/tools/       ← framework scripts"
    echo "  .claude/vibe-skill/.delegate/   ← chain YAMLs, scheduler config"
    echo "  .delegate/                      ← project state (yours, never overwritten)"
    $INSTALL_CODEX && echo "  .codex/AGENTS.md                ← Codex orchestration instructions"
    $INSTALL_CODEX && echo "  .agents/skills/                 ← Codex skill definitions"
    $INSTALL_CLAUDE && echo "  .claude/commands/               ← Claude Code /vibe commands"
    echo ""

    if $INSTALL_CODEX; then
        echo -e "${DIM}Quick start (Codex):${RESET}"
        echo '  $vibe st: add a login page'
        echo '  $vibe-scheduler run research'
        echo '  $vibe-audit scan'
    fi
    if $INSTALL_CLAUDE; then
        echo -e "${DIM}Quick start (Claude Code):${RESET}"
        echo '  /vibe st: add a login page'
        echo '  /vibe-scheduler run research'
        echo '  /vibe-audit scan'
    fi
    echo ""
}

# ── Run ─────────────────────────────────────────────────────────────────────

echo ""
install_tools
install_chains
install_scheduler_default
install_project_state
update_gitignore

$INSTALL_CLAUDE && install_claude_code
$INSTALL_CODEX && install_codex

print_summary
