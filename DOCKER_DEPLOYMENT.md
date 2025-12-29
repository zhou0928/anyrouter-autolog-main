# Docker 部署指南（支持 OrbStack）

## 方案概述

使用 Docker 容器运行自动签到脚本，配合定时任务实现自动化。支持 Docker Desktop 和 OrbStack。

## 优势

- ✅ 环境隔离，不影响宿主机
- ✅ 一键部署，配置简单
- ✅ 支持定时任务（cron）
- ✅ 可以访问宿主机的 Clash 代理
- ✅ 持久化余额历史数据
- ✅ 资源占用低

## 前置要求

- 已安装 Docker Desktop 或 OrbStack
- 已安装 Git

## 快速开始

### 方法 1：使用 Docker Compose（推荐）

#### 1. 克隆项目

```bash
git clone https://github.com/zhou0928/anyrouter-autolog-main.git
cd anyrouter-autolog-main
```

#### 2. 配置环境变量

创建 `.env` 文件：

```bash
# 账号配置（必填）
ANYROUTER_ACCOUNTS=[{"name":"主账号","provider":"tribiosapi","cookies":{"session":"YOUR_SESSION"},"api_user":"YOUR_API_USER"}]

# 代理配置（可选，使用宿主机 Clash）
PROXY_URL=http://host.docker.internal:7897

# 通知配置（可选）
ALWAYS_NOTIFY=false
PUSHPLUS_TOKEN=your_token
```

**重要**：
- OrbStack 和 Docker Desktop 都支持 `host.docker.internal` 来访问宿主机
- 如果使用宿主机的 Clash，确保 Clash 允许局域网连接（`allow-lan: true`）

#### 3. 构建并运行

```bash
# 构建镜像
docker-compose build

# 运行一次测试
docker-compose run --rm anyrouter-checkin

# 后台运行（配合定时任务）
docker-compose up -d
```

#### 4. 查看日志

```bash
# 查看实时日志
docker-compose logs -f

# 查看最近 50 行日志
docker-compose logs --tail=50
```

### 方法 2：使用 Docker 命令

#### 1. 构建镜像

```bash
docker build -t anyrouter-checkin .
```

#### 2. 运行容器

```bash
docker run --rm \
  -e ANYROUTER_ACCOUNTS='[{"name":"主账号","provider":"tribiosapi","cookies":{"session":"YOUR_SESSION"},"api_user":"YOUR_API_USER"}]' \
  -e PROXY_URL=http://host.docker.internal:7897 \
  -v $(pwd)/balance_hash.txt:/app/balance_hash.txt \
  anyrouter-checkin
```

## 配置定时任务

### 方案 1：使用宿主机 Cron（推荐）

在 macOS/Linux 上配置 cron 定时运行 Docker 容器：

```bash
# 编辑 crontab
crontab -e

# 添加定时任务（每 6 小时运行一次）
0 */6 * * * cd /Users/xiaozhou/Desktop/anyrouter-autolog-main/anyrouter-autolog-main && docker-compose run --rm anyrouter-checkin >> /tmp/anyrouter-checkin.log 2>&1
```

**时间说明**：
- `0 */6 * * *` - 每 6 小时运行一次（00:00, 06:00, 12:00, 18:00）
- `0 0,6,12,18 * * *` - 每天 00:00, 06:00, 12:00, 18:00 运行
- `0 8 * * *` - 每天 08:00 运行一次

### 方案 2：在容器内使用 Cron

修改 `Dockerfile`，添加 cron 支持：

```dockerfile
# 在 Dockerfile 末尾添加
USER root
RUN apt-get update && apt-get install -y cron && rm -rf /var/lib/apt/lists/*

# 创建 cron 任务
RUN echo "0 */6 * * * cd /app && uv run checkin.py >> /var/log/cron.log 2>&1" | crontab -

# 启动 cron
CMD ["cron", "-f"]
```

然后重新构建并运行：

```bash
docker-compose build
docker-compose up -d
```

### 方案 3：使用 OrbStack 的定时任务功能

OrbStack 支持更简单的定时任务配置：

1. 创建一个脚本 `run-checkin.sh`：

```bash
#!/bin/bash
cd /Users/xiaozhou/Desktop/anyrouter-autolog-main/anyrouter-autolog-main
docker-compose run --rm anyrouter-checkin
```

2. 添加执行权限：

```bash
chmod +x run-checkin.sh
```

3. 使用 macOS 的 launchd 创建定时任务：

创建 `~/Library/LaunchAgents/com.anyrouter.checkin.plist`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.anyrouter.checkin</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/xiaozhou/Desktop/anyrouter-autolog-main/anyrouter-autolog-main/run-checkin.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>21600</integer>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/anyrouter-checkin.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/anyrouter-checkin-error.log</string>
</dict>
</plist>
```

加载定时任务：

```bash
launchctl load ~/Library/LaunchAgents/com.anyrouter.checkin.plist
```

## OrbStack 特殊配置

### 1. 访问宿主机 Clash 代理

OrbStack 默认支持 `host.docker.internal`，无需额外配置：

```bash
# .env 文件中
PROXY_URL=http://host.docker.internal:7897
```

### 2. 确保 Clash 允许局域网连接

编辑 Clash 配置文件，确保：

```yaml
allow-lan: true
bind-address: '*'
```

或者在 Clash 设置中启用"允许局域网连接"。

### 3. 测试代理连接

```bash
# 进入容器测试
docker-compose run --rm anyrouter-checkin /bin/bash

# 在容器内测试代理
curl -x http://host.docker.internal:7897 https://api.ipify.org?format=json
```

## 环境变量说明

### 必填变量

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `ANYROUTER_ACCOUNTS` | 账号配置（JSON 格式） | 见上文 |

### 可选变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `PROXY_URL` | 代理地址（完整 URL） | 无 |
| `PROXY_HOST` | 代理主机 | 无 |
| `PROXY_PORT` | 代理端口 | 无 |
| `PROXY_USERNAME` | 代理用户名 | 无 |
| `PROXY_PASSWORD` | 代理密码 | 无 |
| `ALWAYS_NOTIFY` | 总是发送通知 | false |
| `PUSHPLUS_TOKEN` | PushPlus Token | 无 |
| `SERVERPUSHKEY` | Server酱 SendKey | 无 |
| `DINGDING_WEBHOOK` | 钉钉 Webhook | 无 |
| `FEISHU_WEBHOOK` | 飞书 Webhook | 无 |
| `WEIXIN_WEBHOOK` | 企业微信 Webhook | 无 |
| `EMAIL_USER` | 邮箱用户名 | 无 |
| `EMAIL_PASS` | 邮箱密码 | 无 |
| `EMAIL_TO` | 收件人邮箱 | 无 |

## 常见问题

### Q1: 容器无法访问宿主机 Clash

**解决方案**：

1. 确认 Clash 配置：
```yaml
allow-lan: true
bind-address: '*'
mixed-port: 7897
```

2. 测试宿主机 IP：
```bash
# 在容器内
ping host.docker.internal
```

3. 如果 `host.docker.internal` 不工作，使用宿主机实际 IP：
```bash
# 获取宿主机 IP（macOS）
ipconfig getifaddr en0

# 在 .env 中使用实际 IP
PROXY_URL=http://192.168.1.100:7897
```

### Q2: 容器内时区不正确

**解决方案**：

在 `docker-compose.yml` 中添加：

```yaml
services:
  anyrouter-checkin:
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - /etc/localtime:/etc/localtime:ro
```

### Q3: Playwright 浏览器启动失败

**解决方案**：

确保 Dockerfile 中安装了所有依赖：

```dockerfile
RUN apt-get update && apt-get install -y \
    libgbm1 \
    libnss3 \
    libxss1 \
    libasound2
```

### Q4: 权限问题

**解决方案**：

```bash
# 修改 balance_hash.txt 权限
chmod 666 balance_hash.txt

# 或者在 docker-compose.yml 中以 root 运行
user: "0:0"
```

### Q5: OrbStack 资源占用高

**解决方案**：

在 `docker-compose.yml` 中限制资源：

```yaml
services:
  anyrouter-checkin:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## 管理命令

```bash
# 查看容器状态
docker-compose ps

# 停止容器
docker-compose stop

# 启动容器
docker-compose start

# 重启容器
docker-compose restart

# 删除容器
docker-compose down

# 删除容器和镜像
docker-compose down --rmi all

# 查看容器日志
docker-compose logs -f

# 进入容器
docker-compose exec anyrouter-checkin /bin/bash

# 手动运行一次
docker-compose run --rm anyrouter-checkin

# 更新镜像
docker-compose build --no-cache
docker-compose up -d
```

## 更新部署

```bash
# 1. 拉取最新代码
git pull

# 2. 重新构建镜像
docker-compose build

# 3. 重启容器
docker-compose up -d

# 4. 查看日志确认
docker-compose logs -f
```

## 卸载

```bash
# 1. 停止并删除容器
docker-compose down

# 2. 删除镜像
docker rmi anyrouter-checkin

# 3. 删除项目目录
cd ..
rm -rf anyrouter-autolog-main

# 4. 删除定时任务（如果配置了）
crontab -e  # 删除相关行
# 或
launchctl unload ~/Library/LaunchAgents/com.anyrouter.checkin.plist
rm ~/Library/LaunchAgents/com.anyrouter.checkin.plist
```

## 推荐配置

### 配置 1：本地 OrbStack + Clash 代理

```yaml
# docker-compose.yml
services:
  anyrouter-checkin:
    build: .
    environment:
      - ANYROUTER_ACCOUNTS=${ANYROUTER_ACCOUNTS}
      - PROXY_URL=http://host.docker.internal:7897
    volumes:
      - ./balance_hash.txt:/app/balance_hash.txt
```

### 配置 2：VPS Docker + 独立代理

```yaml
# docker-compose.yml
services:
  anyrouter-checkin:
    build: .
    environment:
      - ANYROUTER_ACCOUNTS=${ANYROUTER_ACCOUNTS}
      - PROXY_URL=http://proxy.example.com:8080
      - PROXY_USERNAME=username
      - PROXY_PASSWORD=password
    volumes:
      - ./balance_hash.txt:/app/balance_hash.txt
    restart: unless-stopped
```

## 监控和日志

### 查看实时日志

```bash
# 使用 docker-compose
docker-compose logs -f --tail=100

# 使用 docker
docker logs -f anyrouter-checkin
```

### 日志持久化

在 `docker-compose.yml` 中添加：

```yaml
services:
  anyrouter-checkin:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

## 安全建议

1. **不要将 `.env` 文件提交到 Git**
   ```bash
   echo ".env" >> .gitignore
   ```

2. **使用 Docker Secrets（生产环境）**
   ```yaml
   services:
     anyrouter-checkin:
       secrets:
         - anyrouter_accounts
   secrets:
     anyrouter_accounts:
       file: ./secrets/accounts.json
   ```

3. **定期更新镜像**
   ```bash
   docker-compose build --no-cache
   ```

4. **限制容器权限**
   ```yaml
   services:
     anyrouter-checkin:
       security_opt:
         - no-new-privileges:true
       cap_drop:
         - ALL
   ```

## 参考资料

- [Docker 官方文档](https://docs.docker.com/)
- [OrbStack 文档](https://docs.orbstack.dev/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
