#!/usr/bin/env bash
set -euo pipefail

# 卸载 AI 安全规范

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { printf "${GREEN}[✓]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[!]${NC} %s\n" "$1"; }

detect_vscode_user_dir() {
    local candidates=(
        "$HOME/.vscode-server/data/User"
        "$HOME/.config/Code/User"
        "$HOME/.config/Code - Insiders/User"
        "$HOME/Library/Application Support/Code/User"
        "$HOME/Library/Application Support/Code - Insiders/User"
    )
    if [[ -n "${APPDATA:-}" ]]; then
        candidates+=("${APPDATA}/Code/User")
    fi
    for dir in "${candidates[@]}"; do
        if [[ -d "$dir" ]]; then
            printf '%s' "$dir"
            return 0
        fi
    done
    return 1
}

main() {
    local vscode_dir
    vscode_dir="${VSCODE_USER_DIR:-$(detect_vscode_user_dir)}"
    local prompts_dir="$vscode_dir/prompts"

    for f in ai-security.instructions.md security-review.instructions.md; do
        if [[ -f "$prompts_dir/$f" ]]; then
            rm "$prompts_dir/$f"
            info "已移除: $prompts_dir/$f"
        else
            warn "未找到: $prompts_dir/$f"
        fi
    done

    info "卸载完成"
}

main "$@"
