# GitHub Actions 自托管 Runner 设置指南

## 为什么需要自托管 Runner？

由于 tribiosapi 的 session cookie 绑定了 IP 地址，使用 GitHub 托管的 Runner（Azure 数据中心 IP）会导致 403 错误。使用自托管 Runner 可以让自动化脚本在您的本地机器上运行，使用与手动测试相同的 IP 地址。

## 设置步骤

### 1. 在 GitHub 仓库中添加 Self-hosted Runner

1. 打开您的 GitHub 仓库：https://github.com/zhou0928/anyrouter-autolog-main
2. 点击 **Settings** → **Actions** → **Runners**
3. 点击 **New self-hosted runner** 按钮
4. 选择操作系统（根据您的电脑选择）：
   - **macOS** (您当前使用的系统)
   - Windows
   - Linux

### 2. 在本地机器上安装 Runner

GitHub 会显示详细的安装命令，以 macOS 为例：

```bash
# 创建 runner 目录
mkdir actions-runner && cd actions-runner

# 下载最新的 runner 包
curl -o actions-runner-osx-x64-2.321.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-osx-x64-2.321.0.tar.gz

# 解压
tar xzf ./actions-runner-osx-x64-2.321.0.tar.gz

# 配置 runner（使用 GitHub 页面显示的命令，包含您的 token）
./config.sh --url https://github.com/zhou0928/anyrouter-autolog-main --token YOUR_TOKEN

# 启动 runner
./run.sh
```

**重要提示**：
- `YOUR_TOKEN` 会在 GitHub 页面上显示，每次都不同
- 配置时可以使用默认的 runner 名称，或自定义名称（如 `mac-runner`）
- 配置时可以添加标签（如 `self-hosted,macOS`）

### 3. 将 Runner 设置为服务（可选但推荐）

为了让 runner 在后台持续运行，建议将其设置为系统服务：

**macOS:**
```bash
# 安装服务
sudo ./svc.sh install

# 启动服务
sudo ./svc.sh start

# 查看服务状态
sudo ./svc.sh status

# 停止服务（如需要）
sudo ./svc.sh stop

# 卸载服务（如需要）
sudo ./svc.sh uninstall
```

**Windows:**
```powershell
# 以管理员身份运行 PowerShell
.\svc.sh install
.\svc.sh start
```

**Linux:**
```bash
sudo ./svc.sh install
sudo ./svc.sh start
```

### 4. 验证 Runner 状态

1. 返回 GitHub 仓库的 **Settings** → **Actions** → **Runners**
2. 您应该看到新添加的 runner，状态为 **Idle**（空闲）或 **Active**（活动）
3. 如果状态为 **Offline**（离线），检查本地 runner 是否正在运行

### 5. 更新 GitHub Actions 工作流

工作流文件已更新为使用自托管 runner（见下一节）。

## 工作流配置说明

更新后的 `.github/workflows/checkin.yml` 使用 `runs-on: self-hosted`，这意味着：

- ✅ 使用您本地机器的 IP 地址
- ✅ 使用您本地的 Python 环境和依赖
- ✅ 避免 403 错误
- ⚠️ 需要确保本地机器在定时任务运行时保持开机和联网

## 环境要求

确保您的本地机器已安装：

1. **Python 3.14+**（已安装 ✅）
2. **依赖包**：
   ```bash
   pip install httpx playwright python-dotenv
   playwright install chromium
   ```
3. **环境变量**：在 runner 目录创建 `.env` 文件或设置系统环境变量

## 使用本地 .env 文件（推荐）

由于使用自托管 runner，您可以直接使用本地的 `.env` 文件，无需在 GitHub Secrets 中配置：

1. 确保项目根目录有 `.env` 文件
2. 配置正确的 `ANYROUTER_ACCOUNTS`
3. Runner 会自动读取本地 `.env` 文件

## 测试自托管 Runner

1. 手动触发工作流：
   - 进入 **Actions** 标签
   - 选择 **AnyRouter 自动签到** 工作流
   - 点击 **Run workflow** → **Run workflow**

2. 查看运行日志：
   - 应该显示 "This job is running on a self-hosted runner"
   - 检查是否成功执行签到

## 故障排除

### Runner 显示离线
```bash
# 检查 runner 进程
ps aux | grep Runner.Listener

# 重启 runner 服务
sudo ./svc.sh restart
```

### 工作流无法找到 Python
确保 Python 在系统 PATH 中：
```bash
which python3
# 应该显示 Python 路径
```

### 依赖包未找到
在 runner 目录手动安装：
```bash
pip3 install httpx playwright python-dotenv
playwright install chromium
```

### 403 错误仍然出现
1. 确认 runner 正在本地机器上运行
2. 检查 `.env` 文件中的 session cookie 是否最新
3. 手动运行 `python3 checkin.py` 测试

## 定时任务说明

工作流配置为每 6 小时运行一次：
- 00:00 UTC (北京时间 08:00)
- 06:00 UTC (北京时间 14:00)
- 12:00 UTC (北京时间 20:00)
- 18:00 UTC (北京时间 02:00)

**注意**：自托管 runner 需要在这些时间点保持运行状态。

## 安全建议

1. **不要在公共网络上运行 runner**
2. **定期更新 runner 版本**
3. **监控 runner 日志**
4. **使用专用账户运行 runner 服务**
5. **定期检查 GitHub 的 runner 活动日志**

## 卸载 Runner

如果需要移除 runner：

```bash
# 停止服务
sudo ./svc.sh stop
sudo ./svc.sh uninstall

# 移除 runner 配置
./config.sh remove --token YOUR_REMOVAL_TOKEN

# 删除 runner 目录
cd ..
rm -rf actions-runner
```

## 参考资料

- [GitHub Actions Self-hosted Runners 官方文档](https://docs.github.com/en/actions/hosting-your-own-runners)
- [配置 Self-hosted Runner 为服务](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/configuring-the-self-hosted-runner-application-as-a-service)
