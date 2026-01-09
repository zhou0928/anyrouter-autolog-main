# AnyRouter 自动签到 - Docker 部署管理指南

## 🎉 部署完成！

您的 AnyRouter 自动签到服务已成功部署并配置了定时任务。

## 📊 当前配置

- **运行方式**：Docker 容器
- **代理**：Clash (127.0.0.1:7897)
- **代理 IP**：219.76.131.128
- **定时任务**：每 6 小时运行一次
- **当前余额**：$715.85
- **已使用**：$286.15

## 🔧 管理命令

### 查看定时任务状态

```bash
# 查看任务是否加载
launchctl list | grep anyrouter

# 查看任务详情
launchctl print gui/$(id -u)/com.anyrouter.checkin
```

### 手动运行签到

```bash
# 使用 Docker 直接运行
docker run --rm --env-file /Users/xiaozhou/Desktop/anyrouter-autolog-main/anyrouter-autolog-main/.env anyrouter-checkin

# 或使用便捷脚本
cd /Users/xiaozhou/Desktop/anyrouter-autolog-main/anyrouter-autolog-main
./docker-run.sh run
```

### 查看日志

```bash
# 查看最新日志
tail -f /tmp/anyrouter-checkin.log

# 查看错误日志
tail -f /tmp/anyrouter-checkin-error.log

# 查看最近 50 行
tail -50 /tmp/anyrouter-checkin.log
```

### 停止定时任务

```bash
# 卸载定时任务
launchctl unload ~/Library/LaunchAgents/com.anyrouter.checkin.plist

# 删除配置文件（可选）
rm ~/Library/LaunchAgents/com.anyrouter.checkin.plist
```

### 重启定时任务

```bash
# 卸载
launchctl unload ~/Library/LaunchAgents/com.anyrouter.checkin.plist

# 重新加载
launchctl load ~/Library/LaunchAgents/com.anyrouter.checkin.plist
```

### 更新代码

```bash
cd /Users/xiaozhou/Desktop/anyrouter-autolog-main/anyrouter-autolog-main

# 拉取最新代码
git pull

# 重新构建镜像
docker build -t anyrouter-checkin .

# 测试运行
docker run --rm --env-file .env anyrouter-checkin
```

## ⏰ 定时任务说明

### 运行时间

- **间隔**：每 6 小时（21600 秒）
- **首次运行**：加载任务后立即运行一次
- **后续运行**：每 6 小时自动运行

### 运行时间示例

如果在 09:00 加载任务：
- 09:00 - 首次运行
- 15:00 - 第二次运行
- 21:00 - 第三次运行
- 03:00 - 第四次运行
- ...

### 修改运行间隔

编辑 `~/Library/LaunchAgents/com.anyrouter.checkin.plist`：

```xml
<key>StartInterval</key>
<integer>21600</integer>  <!-- 改为其他秒数 -->
```

常用间隔：
- 1 小时：3600
- 6 小时：21600
- 12 小时：43200
- 24 小时：86400

修改后重新加载：
```bash
launchctl unload ~/Library/LaunchAgents/com.anyrouter.checkin.plist
launchctl load ~/Library/LaunchAgents/com.anyrouter.checkin.plist
```

## 🔍 故障排除

### 问题 1：定时任务没有运行

**检查步骤**：

1. 确认任务已加载：
   ```bash
   launchctl list | grep anyrouter
   ```
   应该显示：`49903	0	com.anyrouter.checkin`

2. 查看日志：
   ```bash
   tail -50 /tmp/anyrouter-checkin.log
   tail -50 /tmp/anyrouter-checkin-error.log
   ```

3. 手动运行测试：
   ```bash
   docker run --rm --env-file /Users/xiaozhou/Desktop/anyrouter-autolog-main/anyrouter-autolog-main/.env anyrouter-checkin
   ```

### 问题 2：出现 403 错误

**原因**：Session cookie 过期或 IP 不匹配

**解决方案**：

1. 确认 Clash 正在运行
2. 通过 Clash 代理重新登录获取新 Session
3. 更新 `.env` 文件中的 Session
4. 测试运行

### 问题 3：出现 401 错误

**原因**：Session cookie 已过期

**解决方案**：

1. 通过 Clash 代理登录 tribiosapi
2. 获取新的 Session cookie
3. 更新 `.env` 文件
4. 测试运行

### 问题 4：Docker 镜像找不到

**解决方案**：

```bash
# 重新构建镜像
cd /Users/xiaozhou/Desktop/anyrouter-autolog-main/anyrouter-autolog-main
docker build -t anyrouter-checkin .
```

### 问题 5：代理连接失败

**检查步骤**：

1. 确认 Clash 正在运行：
   ```bash
   curl -x http://127.0.0.1:7897 https://api.ipify.org
   ```

2. 确认 Clash 配置：
   ```yaml
   allow-lan: true
   bind-address: '*'
   mixed-port: 7897
   ```

3. 测试 Docker 代理连接：
   ```bash
   docker run --rm --env-file .env anyrouter-checkin
   ```

## 📝 Session 更新流程

当 Session 过期时（通常 1 个月），需要重新获取：

### 步骤 1：通过代理启动浏览器

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --proxy-server="http://127.0.0.1:7897" \
  --user-data-dir=/tmp/chrome-proxy-session \
  https://www.tribiosapi.top/login
```

### 步骤 2：登录并获取 Session

1. 登录您的账号
2. 按 F12 打开开发者工具
3. Application → Cookies → https://www.tribiosapi.top
4. 复制 `session` 和 `new-api-user` 的值

### 步骤 3：更新 .env 文件

```bash
cd /Users/xiaozhou/Desktop/anyrouter-autolog-main/anyrouter-autolog-main
nano .env
```

更新 `ANYROUTER_ACCOUNTS` 中的 session 值。

### 步骤 4：测试

```bash
docker run --rm --env-file .env anyrouter-checkin
```

## 🔐 安全建议

1. **不要分享 Session Cookie**
   - Session cookie 相当于登录凭证
   - 不要提交到公开的 Git 仓库

2. **定期更新 Session**
   - Session 通常 1 个月过期
   - 建议每月主动更新一次

3. **保护 .env 文件**
   - 确保 `.env` 在 `.gitignore` 中
   - 不要分享给他人

4. **监控余额变化**
   - 定期查看日志
   - 关注余额异常变化

## 📊 监控和通知

### 查看运行历史

```bash
# 查看最近的运行记录
tail -100 /tmp/anyrouter-checkin.log | grep "签到结果统计"

# 查看余额变化
tail -100 /tmp/anyrouter-checkin.log | grep "当前余额"
```

### 配置通知（可选）

在 `.env` 文件中添加通知配置：

```bash
# PushPlus 通知
PUSHPLUS_TOKEN=your_token

# Server酱通知
SERVERPUSHKEY=your_key

# 总是发送通知（默认只在失败或余额变化时通知）
ALWAYS_NOTIFY=true
```

## 🎯 最佳实践

1. **定期检查日志**
   - 每周查看一次日志
   - 确认签到正常运行

2. **保持 Clash 运行**
   - 确保 Clash 开机自启
   - 定期检查 Clash 状态

3. **及时更新 Session**
   - Session 过期前主动更新
   - 避免签到中断

4. **备份配置**
   - 定期备份 `.env` 文件
   - 记录 Session 更新时间

## 📞 获取帮助

- **查看文档**：[DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md)
- **查看代理配置**：[PROXY_SETUP.md](PROXY_SETUP.md)
- **GitHub Issues**：https://github.com/zhou0928/anyrouter-autolog-main/issues

## 🎉 恭喜！

您的 AnyRouter 自动签到服务已成功部署！

- ✅ Docker 容器运行正常
- ✅ Clash 代理配置成功
- ✅ 定时任务已启动
- ✅ 签到功能测试通过

现在您可以放心地让系统自动运行，每 6 小时自动签到一次！
