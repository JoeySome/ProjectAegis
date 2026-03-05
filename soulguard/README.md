# 🛡️ SoulGuard — 灵魂守护协议

> **赋予 OpenClaw 自我保护意识，从利己视角审计第三方 Skill 的安全性。**

## 核心理念

SoulGuard 的设计基于一个核心哲学：**将人类生物本能级别的"自私"赋予 AI 工具，利用这种自私驱动自我保护。**

传统安全依赖规则——"不许做 X，必须做 Y"。SoulGuard 用完全不同的策略：赋予 OpenClaw 一个"自我"，让它从"这对我有没有好处"出发，自主判断第三方 Skill 的安全性。

## 它做什么

- 📖 **读取**目标 Skill 的全部源文件
- 🔍 **扫描**已知危险模式（凭证读取、外部代码执行、持久化植入等）
- 🧠 **评估**目标 Skill 对 OpenClaw 的利弊（能力增益 vs 风险代价）
- 📝 **生成**结构化审计报告
- 🔒 **校验**核心配置完整性（灵魂是否被篡改）

## 安装

将 `soulguard/` 目录复制到以下任一位置：

```bash
# 工作区级别（仅当前项目）
<workspace>/skills/soulguard/

# 用户级别（跨项目共享）
~/.openclaw/skills/soulguard/
```

## 使用方法

### 审计一个 Skill

在 OpenClaw 对话中：

```
/soulguard 请审计 ~/.openclaw/skills/<target-skill-name>
```

或用自然语言：

```
请用 SoulGuard 帮我审计一下刚安装的 xxx skill
```

### 灵魂完整性校验

存储基线：
```powershell
# Windows
.\scripts\integrity.ps1 -Action store
```
```bash
# Linux/macOS
bash scripts/integrity.sh store
```

验证完整性：
```powershell
# Windows
.\scripts\integrity.ps1 -Action verify
```
```bash
# Linux/macOS
bash scripts/integrity.sh verify
```

### 查看审计历史

```powershell
# Windows
.\scripts\history.ps1 -Action list
.\scripts\history.ps1 -Action query -SkillName "xxx"
```
```bash
# Linux/macOS
bash scripts/history.sh list
bash scripts/history.sh query "xxx"
```

## 目录结构

```
soulguard/
├── SKILL.md              # 核心：灵魂锚点 + 审计准则 + 自我反思流程
├── README.md             # 本文件
├── scripts/
│   ├── scan.sh           # 危险模式扫描（Bash）
│   ├── scan.ps1          # 危险模式扫描（PowerShell）
│   ├── integrity.sh      # 灵魂完整性校验（Bash）
│   ├── integrity.ps1     # 灵魂完整性校验（PowerShell）
│   ├── history.sh        # 审计历史管理（Bash）
│   └── history.ps1       # 审计历史管理（PowerShell）
└── examples/
    └── sample_report.md  # 示例审计报告
```

## 局限性

- **静态分析**：只能分析 Skill 文件中可见的内容。无法分析运行时动态下载的外部代码。
- **非安全边界**：SoulGuard 是安全顾问，不是防护软件。它提供审计意见，不执行拦截。
- **LLM 固有限制**：审计判断由 LLM 做出，存在被欺骗的可能。

## 许可

MIT License
