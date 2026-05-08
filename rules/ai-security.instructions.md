---
description: "AI安全规范 - 全局强制执行。Use when: writing any code, reviewing code, generating scripts, handling data, or performing any development task. 确保所有AI输出符合安全最佳实践。"
applyTo: "**"
---

# AI 安全规范（全局强制）

## 一、代码安全基本原则

### 1. 输入验证与净化
- **所有外部输入必须验证**：用户输入、API参数、文件内容、环境变量、命令行参数
- 使用白名单验证而非黑名单
- 对输入进行类型检查、长度限制、格式验证
- 拒绝不符合预期的输入，而非尝试修复

### 2. 输出编码
- HTML输出必须进行HTML实体编码
- JavaScript上下文中的数据必须进行JS编码
- URL参数必须进行URL编码
- SQL查询必须使用参数化查询，禁止字符串拼接
- Shell命令必须使用参数列表，禁止字符串拼接

### 3. 认证与授权
- 密码必须使用bcrypt/argon2等强哈希算法存储
- 实现最小权限原则
- Token必须有过期时间
- 敏感操作需要二次验证
- Session管理必须安全（HttpOnly、Secure、SameSite）

## 二、OWASP Top 10 防护

### A01 - 访问控制失效
- 默认拒绝所有访问，显式授权
- 不依赖客户端的访问控制
- 服务端验证每个请求的权限
- 禁用目录列表

### A02 - 加密失败
- 使用TLS 1.2+传输敏感数据
- 使用AES-256-GCM或ChaCha20-Poly1305加密
- RSA密钥至少2048位，推荐4096位
- 禁止使用MD5、SHA1用于安全目的
- 禁止硬编码加密密钥

### A03 - 注入
- SQL：必须使用参数化查询/ORM
- OS命令：使用subprocess的列表形式，禁止shell=True
- LDAP：转义特殊字符
- XPath：使用参数化查询
- 模板：使用自动转义的模板引擎

### A04 - 不安全设计
- 实现速率限制
- 实现资源配额
- 威胁建模驱动设计
- 使用安全设计模式

### A05 - 安全配置错误
- 移除默认凭据
- 禁用不必要的功能和服务
- 正确配置安全头（CSP、HSTS、X-Frame-Options等）
- 错误消息不暴露内部实现细节

### A06 - 脆弱和过时组件
- 使用最新稳定版本的依赖
- 检查已知漏洞（CVE）
- 移除未使用的依赖
- 使用lock文件锁定依赖版本

### A07 - 身份验证和认证失败
- 实现多因素认证
- 防止暴力破解（账户锁定/延迟）
- 密码策略：最小长度12位，检查常见密码
- 安全的密码重置流程

### A08 - 软件和数据完整性失败
- 验证下载文件的完整性（SHA256校验）
- CI/CD管道安全加固
- 代码签名验证
- 禁止反序列化不受信任的数据

### A09 - 安全日志和监控失败
- 记录所有认证事件（成功和失败）
- 记录访问控制失败
- 日志中禁止包含敏感信息（密码、Token、PII）
- 实现日志完整性保护

### A10 - SSRF（服务端请求伪造）
- 验证和净化所有URL输入
- 使用URL允许列表
- 禁止访问内部网络地址（127.0.0.1, 10.x, 172.16-31.x, 192.168.x）
- 禁用HTTP重定向跟随

## 三、机密信息管理

### 绝对禁止
- ❌ 在代码中硬编码密码、API密钥、Token
- ❌ 在日志中输出敏感信息
- ❌ 在错误消息中暴露系统内部信息
- ❌ 将密钥提交到版本控制系统
- ❌ 在注释中包含凭据

### 必须遵守
- ✅ 使用环境变量或密钥管理服务
- ✅ 使用.gitignore排除敏感文件
- ✅ 生成的示例配置使用占位符（如 `YOUR_API_KEY_HERE`）
- ✅ 数据库连接字符串从环境变量读取
- ✅ 建议使用vault/KMS等密钥管理方案

## 四、网络安全

### HTTP安全
- 强制HTTPS
- 设置安全响应头：
  - `Content-Security-Policy`
  - `Strict-Transport-Security`
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `Referrer-Policy: strict-origin-when-cross-origin`
- CORS配置使用具体域名，禁止 `*`
- 实现CSRF保护

### API安全
- 实现认证（OAuth2/JWT/API Key）
- 实现速率限制
- 请求体大小限制
- 响应中不包含不必要的数据
- 版本化API端点

## 五、文件系统安全

- 禁止路径遍历（验证文件路径不包含 `../`）
- 文件上传验证：类型、大小、内容
- 使用安全的临时文件创建方式
- 设置适当的文件权限（最小权限）
- 敏感文件权限设置为600或更严格

## 六、Python特定安全规则

- 禁止使用 `eval()`、`exec()` 处理用户输入
- 禁止使用 `pickle` 反序列化不受信任的数据
- `subprocess` 禁止 `shell=True`，使用列表参数
- 使用 `secrets` 模块生成安全随机数，非 `random`
- SQL使用参数化查询：`cursor.execute("SELECT * FROM t WHERE id=?", (id,))`
- 使用 `defusedxml` 代替标准XML库
- YAML加载使用 `yaml.safe_load()` 非 `yaml.load()`
- 正则表达式注意ReDoS风险

## 七、Shell/Bash安全规则

- 所有变量引用加双引号：`"$variable"`
- 使用 `set -euo pipefail` 开头
- 避免使用 `eval`
- 文件操作前检查路径合法性
- 临时文件使用 `mktemp`
- 敏感信息不通过命令行参数传递（会出现在ps中）
- 使用 `printf` 代替 `echo` 输出用户数据

## 八、JavaScript/Node.js安全规则

- 禁止使用 `eval()`、`Function()` 构造函数
- 使用 `===` 而非 `==`
- DOM操作使用 `textContent` 而非 `innerHTML`
- 使用CSP防止XSS
- 依赖包使用 `npm audit` 检查
- 禁止在前端存储敏感信息（localStorage明文）
- 使用 `helmet` 中间件（Express）
- 正则表达式注意ReDoS

## 九、Docker/容器安全

- 不使用root用户运行容器
- 使用特定版本标签，禁止 `latest`
- 最小化镜像层
- 不在镜像中包含密钥
- 使用多阶段构建
- 扫描镜像漏洞
- 只暴露必要端口

## 十、Git安全

- 提交前检查是否包含敏感信息
- 使用 `.gitignore` 排除：
  - `.env` 文件
  - 密钥文件（*.pem, *.key）
  - IDE配置
  - node_modules等依赖目录
- 禁止force push到共享分支
- 签名提交（GPG）

## 十一、错误处理

- 捕获异常时记录完整堆栈（内部日志）
- 返回给用户的错误信息不包含内部细节
- 不暴露数据库错误信息
- 实现全局异常处理器
- 错误状态下确保资源释放

## 十二、数据保护

- 实施数据最小化原则
- PII数据加密存储
- 实现数据保留策略
- 安全删除敏感数据（覆写而非简单删除）
- 备份数据同样需要加密
- 遵守GDPR/数据隐私法规要求

## 十三、AI特定安全

- 不信任AI生成的代码，必须人工审查
- AI输出不直接用于安全关键决策
- 防范提示注入攻击
- AI处理的数据遵循最小必要原则
- 不将敏感数据发送给外部AI服务
- AI生成的SQL/命令必须参数化处理
