# 🚀 GitHub Actions 自动化签到部署指南

## 📋 部署步骤

### 1️⃣ 将项目推送到 GitHub

首先，你需要将本项目推送到你的 GitHub 仓库：

```bash
# 初始化 git 仓库（如果还没有）
git init

# 添加所有文件
git add .

# 提交更改
git commit -m "Initial commit: Add AnyRouter auto check-in project"

# 添加远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/zhou0928/anyrouter-autolog-main.git

# 推送到 GitHub
git push -u origin main
```

如果你的默认分支是 `master` 而不是 `main`，请使用：
```bash
git push -u origin main
```

### 2️⃣ 配置 GitHub Environment

1. 进入你的 GitHub 仓库页面
2. 点击 **Settings** 选项卡
3. 在左侧菜单中找到 **Environments**
4. 点击 **New environment** 创建新环境
5. 环境名称输入：`production`
6. 点击 **Configure environment**

### 3️⃣ 配置 Environment Secrets

在 `production` 环境中，点击 **Add environment secret** 添加以下必需的密钥：

#### 🔑 必需配置

**ANYROUTER_ACCOUNTS**（必需）
- 值为账号配置的 JSON 格式（必须是单行）
- 示例：
```json
[{"name":"主账号","provider":"anyrouter","cookies":{"session":"your_session_value"},"api_user":"12345"}]
```

#### 📱 可选配置 - 通知设置

根据你需要的通知方式，添加对应的 secrets：

**ALWAYS_NOTIFY**（可选）
- 值：`true` 或 `false`
- 默认为 `false`（仅在失败或余额变化时通知）

**邮箱通知：**
- `EMAIL_USER` - 发件人邮箱地址
- `EMAIL_PASS` - 发件人邮箱密码/授权码
- `EMAIL_TO` - 收件人邮箱地址
- `CUSTOM_SMTP_SERVER`（可选）- 自定义 SMTP 服务器

**钉钉机器人：**
- `DINGDING_WEBHOOK` - 钉钉机器人 Webhook 地址

**飞书机器人：**
- `FEISHU_WEBHOOK` - 飞书机器人 Webhook 地址

**企业微信机器人：**
- `WEIXIN_WEBHOOK` - 企业微信机器人 Webhook 地址

**PushPlus：**
- `PUSHPLUS_TOKEN` - PushPlus Token

**Server酱：**
- `SERVERPUSHKEY` - Server酱 SendKey

**自定义服务商（可选）：**
- `PROVIDERS` - 自定义服务商配置（JSON 格式，单行）

### 4️⃣ 启用 GitHub Actions

1. 在你的仓库中，点击 **Actions** 选项卡
2. 如果看到提示，点击 **I understand my workflows, go ahead and enable them**
3. 找到 **AnyRouter 自动签到** workflow
4. 确认工作流已启用

### 5️⃣ 测试运行

手动触发一次签到来测试配置：

1. 在 **Actions** 选项卡中，点击 **AnyRouter 自动签到**
2. 点击右侧的 **Run workflow** 下拉按钮
3. 选择分支（通常是 `main` 或 `master`）
4. 点击绿色的 **Run workflow** 按钮
5. 等待几秒钟，刷新页面查看运行状态

### 6️⃣ 查看运行日志

1. 点击正在运行或已完成的工作流
2. 点击 **check-in** 作业
3. 展开各个步骤查看详细日志
4. 在 **执行签到** 步骤中可以看到签到结果

## ⏰ 自动执行时间

工作流配置为每 6 小时自动执行一次（UTC 时间）：
- 00:00 (北京时间 08:00)
- 06:00 (北京时间 14:00)
- 12:00 (北京时间 20:00)
- 18:00 (北京时间 02:00)

注意：GitHub Actions 的定时任务可能会有 10-60 分钟的延迟。

## 🔧 获取账号配置信息

### 方法一：自动获取（推荐）

如果你的账号支持账号密码登录，可以使用本地脚本自动获取：

```bash
# 1. 复制配置文件
cd get_user
cp user.json.example user.json

# 2. 编辑 user.json，填入账号密码
# 3. 运行脚本
python auto_login.py

# 4. 查看生成的 anyrouter_accounts.json
# 5. 转换为单行格式
python merge_accounts.py

# 6. 复制 anyrouter_accounts.txt 的内容到 GitHub Secrets
```

### 方法二：手动获取

1. 打开浏览器，访问网站并登录
2. 按 F12 打开开发者工具
3. 切换到 **Application** 或 **存储** 选项卡
4. 找到 **Cookies**，复制 `session` 的值
5. 切换到 **Network** 选项卡，过滤 **Fetch/XHR**
6. 找到请求头中的 `New-Api-User` 值

## ⚠️ 注意事项

1. ✅ 确保 `ANYROUTER_ACCOUNTS` 是有效的 JSON 格式且为单行
2. 🔐 所有敏感信息都应该配置在 Secrets 中，不要直接写在代码里
3. 🍪 Session 通常 1 个月过期，过期后需要重新获取
4. 📊 可以在 Actions 页面随时查看历史运行记录
5. 🔔 配置通知后，失败或余额变化时会自动推送通知

## 🐛 故障排除

### 签到失败

1. 检查 Actions 运行日志中的错误信息
2. 确认 `session` cookie 是否过期（401 错误）
3. 确认 `api_user` 是否正确
4. 检查账号配置的 JSON 格式是否正确

### 工作流不执行

1. 确认已启用 GitHub Actions
2. 检查工作流文件语法是否正确
3. 确认环境变量 `production` 已创建
4. 检查必需的 Secrets 是否已配置

### 通知不发送

1. 确认通知相关的 Secrets 已正确配置
2. 检查 `ALWAYS_NOTIFY` 设置
3. 查看运行日志中的通知相关信息

## 📝 配置示例

### 单账号配置

```json
[{"name":"我的账号","provider":"anyrouter","cookies":{"session":"abc123"},"api_user":"12345"}]
```

### 多账号配置

```json
[{"name":"主账号","provider":"anyrouter","cookies":{"session":"abc123"},"api_user":"12345"},{"name":"备用账号","provider":"agentrouter","cookies":{"session":"xyz789"},"api_user":"67890"}]
```

## 🎉 完成

配置完成后，工作流将自动在设定的时间执行签到任务。你可以随时在 Actions 页面查看执行情况和日志。

如果遇到问题，请查看 Actions 运行日志或参考项目的 README.md 文档。
