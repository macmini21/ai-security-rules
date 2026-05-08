# AI 安全规范 (AI Security Rules)

一键部署 VS Code / GitHub Copilot AI 安全规范，确保每次 AI 辅助编码都遵循安全最佳实践。

## 覆盖内容

- **OWASP Top 10** 全面防护
- 输入验证、输出编码、注入防护
- 机密信息管理（禁止硬编码凭据）
- Python / Shell / JavaScript / Docker / Git 专项安全规则
- 加密算法与密钥管理
- 网络安全（HTTPS、安全头、CORS、CSRF）
- 代码审查检查清单（自动触发）
- AI 特定安全（提示注入防护、数据最小化）

## 快速安装

### 方法一：一行命令安装

```bash
git clone https://github.com/nice1st/ai-security-rules.git /tmp/ai-security-rules && bash /tmp/ai-security-rules/install.sh
```

### 方法二：手动安装

```bash
git clone https://github.com/nice1st/ai-security-rules.git
cd ai-security-rules
bash install.sh
```

### 安装到指定工作区

```bash
WORKSPACE_DIR=/path/to/your/project bash install.sh
```

### 自定义 VS Code 目录

```bash
VSCODE_USER_DIR=/path/to/vscode/User bash install.sh
```

## 卸载

```bash
bash uninstall.sh
```

## 文件说明

| 文件 | 作用 | 安装位置 |
|------|------|----------|
| `ai-security.instructions.md` | 全面安全规范（全局强制） | `~/.vscode-server/data/User/prompts/` |
| `security-review.instructions.md` | 代码审查检查清单 | `~/.vscode-server/data/User/prompts/` |
| `copilot-instructions.md.example` | 工作区级安全模板 | 项目 `.github/` 目录 |

## 生效机制

- **用户级规范**：通过 `applyTo: "**"` 匹配所有文件，每次 AI 交互自动加载
- **代码审查清单**：匹配代码文件 (`*.py, *.sh, *.js` 等)，编码时自动触发
- **工作区级规范**：放入项目 `.github/copilot-instructions.md` 后自动识别

安装后无需任何额外配置，下次 AI 对话即生效。

## License

MIT
