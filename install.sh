#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  AI 安全规范一键部署脚本
#  用法: curl -fsSL https://raw.githubusercontent.com/$(gh_user)/ai-security-rules/main/install.sh | bash
#  或:   git clone ... && cd ai-security-rules && bash install.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${GREEN}[✓]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[!]${NC} %s\n" "$1"; }
error() { printf "${RED}[✗]${NC} %s\n" "$1"; }

# ---------- 定位 VS Code Server / Desktop 的 User 目录 ----------
detect_vscode_user_dir() {
    local candidates=(
        # VS Code Server (Remote SSH / WSL)
        "$HOME/.vscode-server/data/User"
        # VS Code Desktop (Linux)
        "$HOME/.config/Code/User"
        "$HOME/.config/Code - Insiders/User"
        # VS Code Desktop (macOS)
        "$HOME/Library/Application Support/Code/User"
        "$HOME/Library/Application Support/Code - Insiders/User"
        # VS Code Desktop (Windows via Git Bash / MSYS)
        "$APPDATA/Code/User"
    )

    for dir in "${candidates[@]}"; do
        if [[ -d "$dir" ]]; then
            printf '%s' "$dir"
            return 0
        fi
    done
    return 1
}

# ---------- 获取规范文件来源 ----------
get_rules_dir() {
    # 如果是从 clone 的仓库运行
    if [[ -d "$SCRIPT_DIR/rules" ]]; then
        printf '%s' "$SCRIPT_DIR/rules"
        return 0
    fi
    # 如果是通过 curl 管道运行，下载到临时目录
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local repo_url="https://github.com/nice1st/ai-security-rules"
    warn "未找到本地规范文件，正在从 GitHub 下载..."
    if command -v git &>/dev/null; then
        git clone --depth 1 "$repo_url" "$tmp_dir/repo" 2>/dev/null
        printf '%s' "$tmp_dir/repo/rules"
    elif command -v curl &>/dev/null; then
        curl -fsSL "$repo_url/archive/refs/heads/main.tar.gz" | tar xz -C "$tmp_dir"
        printf '%s' "$tmp_dir/ai-security-rules-main/rules"
    else
        error "需要 git 或 curl 来下载规范文件"
        return 1
    fi
}

# ---------- 安装用户级规范 ----------
install_user_rules() {
    local vscode_dir="$1"
    local rules_dir="$2"
    local prompts_dir="$vscode_dir/prompts"

    mkdir -p "$prompts_dir"

    local count=0
    for f in "$rules_dir"/ai-security.instructions.md "$rules_dir"/security-review.instructions.md; do
        if [[ -f "$f" ]]; then
            local fname
            fname="$(basename "$f")"
            if [[ -f "$prompts_dir/$fname" ]]; then
                # 备份已有文件
                cp "$prompts_dir/$fname" "$prompts_dir/$fname.bak.$(date +%s)"
                warn "已备份旧文件: $fname"
            fi
            cp "$f" "$prompts_dir/$fname"
            info "已安装: $prompts_dir/$fname"
            count=$((count + 1))
        fi
    done

    if [[ $count -eq 0 ]]; then
        error "未找到用户级规范文件"
        return 1
    fi
    info "共安装 $count 个用户级规范文件"
}

# ---------- 安装工作区级规范（可选） ----------
install_workspace_rules() {
    local rules_dir="$1"
    local target_dir="$2"

    local github_dir="$target_dir/.github"
    mkdir -p "$github_dir"

    local src="$rules_dir/copilot-instructions.md.example"
    local dst="$github_dir/copilot-instructions.md"

    if [[ ! -f "$src" ]]; then
        warn "未找到工作区级模板，跳过"
        return 0
    fi

    if [[ -f "$dst" ]]; then
        warn "$dst 已存在，跳过（不覆盖项目配置）"
        return 0
    fi

    cp "$src" "$dst"
    info "已安装工作区级规范: $dst"
}

# ---------- 主流程 ----------
main() {
    printf '\n'
    printf '  ╔══════════════════════════════════════╗\n'
    printf '  ║   AI 安全规范一键部署工具 v1.0       ║\n'
    printf '  ╚══════════════════════════════════════╝\n'
    printf '\n'

    # 1. 检测 VS Code User 目录
    local vscode_dir
    if ! vscode_dir="$(detect_vscode_user_dir)"; then
        error "未检测到 VS Code 安装目录"
        error "请手动指定: VSCODE_USER_DIR=/path/to/User bash install.sh"
        exit 1
    fi

    # 允许环境变量覆盖
    vscode_dir="${VSCODE_USER_DIR:-$vscode_dir}"
    info "VS Code User 目录: $vscode_dir"

    # 2. 获取规范文件
    local rules_dir
    if ! rules_dir="$(get_rules_dir)"; then
        error "无法获取规范文件"
        exit 1
    fi
    info "规范文件来源: $rules_dir"

    # 3. 安装用户级规范（全局生效）
    printf '\n--- 安装用户级规范（全局生效）---\n'
    install_user_rules "$vscode_dir" "$rules_dir"

    # 4. 安装工作区级规范（可选）
    if [[ -n "${WORKSPACE_DIR:-}" ]]; then
        printf '\n--- 安装工作区级规范 ---\n'
        install_workspace_rules "$rules_dir" "$WORKSPACE_DIR"
    else
        printf '\n'
        warn "如需安装工作区级规范，请运行:"
        warn "  WORKSPACE_DIR=/path/to/project bash install.sh"
    fi

    # 5. 完成
    printf '\n'
    info "部署完成！安全规范将在下次 AI 对话时自动生效。"
    printf '\n'
    printf '  已部署的规范:\n'
    printf '  • ai-security.instructions.md    — 全面安全规范 (OWASP Top10, 加密, 注入防护等)\n'
    printf '  • security-review.instructions.md — 代码审查检查清单 (自动触发)\n'
    if [[ -n "${WORKSPACE_DIR:-}" ]]; then
        printf '  • .github/copilot-instructions.md — 工作区级安全规范\n'
    fi
    printf '\n'
}

main "$@"
