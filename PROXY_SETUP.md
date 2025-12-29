# 使用代理解决 GitHub Actions 403 错误

## 方案概述

由于 tribiosapi 的 session cookie 绑定了 IP 地址，GitHub Actions 的服务器 IP 会导致 403 错误。使用代理可以让请求通过固定的 IP 地址发出，避免这个问题。

## 代理类型选择

### 1. HTTP/HTTPS 代理（推荐）
- ✅ 配置简单
- ✅ 支持认证
- ✅ 成本较低
- ⚠️ 需要购买代理服务

### 2. SOCKS5 代理
- ✅ 更底层的协议
- ✅ 性能更好
- ⚠️ 配置稍复杂

## 推荐的代理服务商

### 国内代理服务
1. **快代理** (https://www.kuaidaili.com/)
   - 价格：约 ¥50-100/月
   - 支持 HTTP/HTTPS/SOCKS5
   - 提供固定 IP

2. **芝麻代理** (http://www.zhimaruanjian.com/)
   - 价格：约 ¥30-80/月
   - 支持多种协议
   - 稳定性好

3. **阿布云** (https://www.abuyun.com/)
   - 价格：按流量计费
   - 企业级服务
   - 高可用性

### 国外代理服务
1. **Bright Data** (https://brightdata.com/)
   - 价格：$500+/月
   - 企业级服务
   - 全球节点

2. **Smartproxy** (https://smartproxy.com/)
   - 价格：$75+/月
   - 住宅代理
   - 支持多地区

3. **Oxylabs** (https://oxylabs.io/)
   - 价格：$300+/月
   - 高质量代理
   - 技术支持好

### 免费代理（不推荐）
- ⚠️ 稳定性差
- ⚠️ 速度慢
- ⚠️ 安全性低
- ⚠️ 可能随时失效

## 配置步骤

### 第一步：获取代理信息

购买代理服务后，您会获得类似以下的信息：

```
代理地址: proxy.example.com
端口: 8080
用户名: your_username
密码: your_password
```

或者直接是完整的代理 URL：
```
http://username:password@proxy.example.com:8080
```

### 第二步：在 GitHub Secrets 中配置代理

1. 打开您的 GitHub 仓库
2. 进入 **Settings** → **Secrets and variables** → **Actions**
3. 点击 **New repository secret**
4. 添加以下 Secret：

**方式一：使用完整的代理 URL（推荐）**
- Name: `PROXY_URL`
- Value: `http://username:password@proxy.example.com:8080`

**方式二：分别配置（更安全）**
- Name: `PROXY_HOST`
- Value: `proxy.example.com`

- Name: `PROXY_PORT`
- Value: `8080`

- Name: `PROXY_USERNAME`
- Value: `your_username`

- Name: `PROXY_PASSWORD`
- Value: `your_password`

### 第三步：测试代理

在本地测试代理是否可用：

```bash
# 设置代理环境变量
export PROXY_URL="http://username:password@proxy.example.com:8080"

# 测试代理
curl -x $PROXY_URL https://api.ipify.org?format=json

# 应该返回代理服务器的 IP 地址
```

### 第四步：使用代理登录获取 Session

**重要**：您需要通过代理登录 tribiosapi 来获取绑定到代理 IP 的 session cookie。

```bash
# 方法 1：使用浏览器代理插件
# 1. 安装 SwitchyOmega 等代理插件
# 2. 配置代理信息
# 3. 启用代理后访问 tribiosapi 并登录
# 4. 获取 session cookie

# 方法 2：使用命令行（需要支持代理的浏览器）
# macOS/Linux
chromium --proxy-server="http://proxy.example.com:8080" https://www.tribiosapi.top/login

# Windows
chrome.exe --proxy-server="http://proxy.example.com:8080" https://www.tribiosapi.top/login
```

登录后，按 F12 打开开发者工具，获取 session cookie 和 api_user。

### 第五步：更新 GitHub Secrets

将通过代理获取的 session cookie 更新到 GitHub Secrets：

1. 进入 **Settings** → **Secrets and variables** → **Actions** → **Environments** → **production**
2. 更新 `ANYROUTER_ACCOUNTS` 中的 session 值

## 代理配置说明

### HTTP 代理格式

```python
# 无认证
proxy = "http://proxy.example.com:8080"

# 有认证
proxy = "http://username:password@proxy.example.com:8080"

# HTTPS 代理
proxy = "https://username:password@proxy.example.com:8080"
```

### SOCKS5 代理格式

```python
# 无认证
proxy = "socks5://proxy.example.com:1080"

# 有认证
proxy = "socks5://username:password@proxy.example.com:1080"
```

### 代理配置示例

在 `.env` 文件中（本地测试）：

```bash
# 代理配置
PROXY_URL=http://username:password@proxy.example.com:8080

# 或者分别配置
PROXY_HOST=proxy.example.com
PROXY_PORT=8080
PROXY_USERNAME=your_username
PROXY_PASSWORD=your_password
```

## 验证代理是否生效

### 方法 1：检查 IP 地址

在脚本中添加 IP 检查：

```python
import httpx

# 不使用代理
response = httpx.get('https://api.ipify.org?format=json')
print(f"本地 IP: {response.json()['ip']}")

# 使用代理
proxies = {"http://": proxy_url, "https://": proxy_url}
response = httpx.get('https://api.ipify.org?format=json', proxies=proxies)
print(f"代理 IP: {response.json()['ip']}")
```

### 方法 2：查看 GitHub Actions 日志

工作流会在日志中显示当前使用的 IP 地址，确认是否为代理 IP。

## 常见问题

### Q1: 代理连接超时
**原因**：
- 代理服务器不可用
- 代理认证信息错误
- 网络连接问题

**解决方案**：
```bash
# 测试代理连接
curl -v -x http://username:password@proxy.example.com:8080 https://www.google.com
```

### Q2: 仍然出现 403 错误
**原因**：
- Session cookie 不是通过代理 IP 获取的
- 代理 IP 被封禁
- Session cookie 已过期

**解决方案**：
1. 确保通过代理登录获取 session
2. 更换代理 IP
3. 重新登录获取新的 session

### Q3: 代理速度慢
**原因**：
- 代理服务器负载高
- 代理服务器地理位置远

**解决方案**：
1. 选择地理位置更近的代理节点
2. 升级代理服务套餐
3. 更换代理服务商

### Q4: Playwright 无法使用代理
**原因**：
- Playwright 需要特殊的代理配置

**解决方案**：
在代码中为 Playwright 单独配置代理（已在更新的代码中实现）

## 成本估算

### 低成本方案（¥30-50/月）
- 国内代理服务
- 共享 IP 池
- 适合个人使用

### 中等成本方案（¥100-200/月）
- 独享 IP
- 更高稳定性
- 适合多账号

### 高成本方案（$100+/月）
- 企业级代理
- 全球节点
- 高可用性保证

## 安全建议

1. **不要在代码中硬编码代理信息**
   - 使用环境变量或 GitHub Secrets

2. **定期更换代理密码**
   - 建议每月更换一次

3. **监控代理使用情况**
   - 检查异常流量
   - 防止代理被滥用

4. **使用 HTTPS 代理**
   - 加密传输数据
   - 提高安全性

5. **备用代理**
   - 配置多个代理
   - 自动切换机制

## 替代方案对比

| 方案 | 成本 | 稳定性 | 配置难度 | 推荐度 |
|------|------|--------|----------|--------|
| 代理服务 | ¥30-100/月 | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| 自托管 Runner | 电费 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| VPS + 代理 | ¥50-200/月 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| 本地 Cron | 电费 | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |

## 推荐配置

对于个人使用，推荐以下配置：

1. **代理服务商**：快代理或芝麻代理
2. **代理类型**：HTTP 代理（带认证）
3. **套餐选择**：¥50-80/月的基础套餐
4. **IP 类型**：动态 IP 池（每次请求可能不同，但都是国内 IP）

## 参考资料

- [httpx 代理文档](https://www.python-httpx.org/advanced/#http-proxying)
- [Playwright 代理配置](https://playwright.dev/python/docs/network#http-proxy)
- [GitHub Actions 环境变量](https://docs.github.com/en/actions/learn-github-actions/variables)
