# GitHub Copilot / AI agent instructions for AnyRouter

简短目标：帮助 AI 代码代理快速定位本项目的核心结构、运行/测试流程、约定与常见坑，以便进行小范围修复、改进或新增 Provider 支持。

## 一句概览 ✅
- 这是一个「多账号自动签到」脚本集合，入口为 `checkin.py`。核心流程：读取环境变量 `ANYROUTER_ACCOUNTS`（单行 JSON），对每个账号准备 cookies（必要时用 Playwright 获取 WAF cookies），调用 provider 的 check-in 接口或 user-info 接口，然后按策略发送通知。

## 主要文件（快速上手） 🔧
- `checkin.py` — 主入口。关键逻辑：cookies 准备、WAF 绕过、优先使用 `checkin_path`（新接口），失败后降级到 `sign_in_path`（旧接口），并计算 `balance_hash.txt` 以监测余额变化。
- `utils/config.py` — `ProviderConfig` 与 `AppConfig`：默认内置 `anyrouter` 与 `agentrouter`，可通过 `PROVIDERS` 环境变量（JSON object）覆盖或新增 provider。
- `utils/notify.py` — 多渠道通知实现（邮箱、PushPlus、Server酱、钉钉、飞书、企业微信）。
- `get_user/auto_login.py` — 用 Playwright 批量登录并导出 `anyrouter_accounts.json`。
- `get_user/merge_accounts.py` — 将 `anyrouter_accounts.json` 转成单行 JSON（`anyrouter_accounts.txt`），便于复制到 `ANYROUTER_ACCOUNTS` secret。
- `pyproject.toml` — 依赖与 dev 依赖（Playwright、httpx、pytest、ruff 等）。

## 运行 / 开发命令（具体且可复制） ▶️
- 安装依赖（本项目使用 `uv` 环境管理）：
  - 本地/CI 同步依赖： `uv sync --dev` 或 `uv sync`（CI 使用 `uv sync`）。
  - 安装 Playwright 浏览器： `uv run playwright install chromium`（或加 `--with-deps` 在 CI 上）。
- 本地运行签到： `uv run checkin.py`（等同于 `python checkin.py`，推荐使用 `uv run` 保持与 CI 一致）。
- 生成 / 合并账号：
  - `python get_user/auto_login.py` → 输出 `get_user/anyrouter_accounts.json`
  - `python get_user/merge_accounts.py` → 输出 `get_user/anyrouter_accounts.txt`（单行 JSON，直接用于 `ANYROUTER_ACCOUNTS` secret）
- 测试： `pytest`（项目使用 `pytest`，真实接口测试需设置 `ENABLE_REAL_TEST=true` 并配置相应 `.env`/Secrets）。

## 环境变量与 Secrets（关键项） 🔐
- MUST: `ANYROUTER_ACCOUNTS` — 单行 JSON 数组，每个项必须含 `cookies` 与 `api_user`（可选 `provider`、`name`）。示例：
  - `[{"cookies":{"session":"abc"},"api_user":"user123"}]`
- OPTIONAL: `PROVIDERS` — JSON object，用于覆盖/添加 provider（参考 `ProviderConfig.from_dict` 的字段：`domain`, `login_path`, `sign_in_path`, `checkin_path`, `user_info_path`, `api_user_key`, `bypass_method`）。
- 通知相关： `ALWAYS_NOTIFY`, `EMAIL_USER`, `EMAIL_PASS`, `EMAIL_TO`, `CUSTOM_SMTP_SERVER`, `PUSHPLUS_TOKEN`, `SERVERPUSHKEY`, `DINGDING_WEBHOOK`, `FEISHU_WEBHOOK`, `WEIXIN_WEBHOOK`。

## Provider / WAF 要点 ⚠️
- 如果 provider 的 `bypass_method` 为 `waf_cookies`：脚本会通过 Playwright 打开页面并尝试获取 WAF cookies（`acw_tc`, `cdn_sec_tc`, `acw_sc__v2`）。见 `checkin.get_waf_cookies_with_playwright`。
- 默认内置：
  - `anyrouter`：`bypass_method='waf_cookies'`（需要 Playwright）
  - `agentrouter`：`bypass_method=None`（直接使用 cookies）

## 重要行为/实现约定（对修改必须小心） 🧭
- 签到优先级：尝试 `checkin_path`（若存在）；若返回失败（但非“已签到”），会回退到旧的 `sign_in_path`。
- `get_user_info` 用于获取 `quota` / `used_quota` 并用于余额监测（`generate_balance_hash` 会基于 `quota` 计算短 hash 并保存到 `balance_hash.txt`）。
- `parse_cookies` 支持两种输入：字典或一段 cookie 字符串（格式 `a=b; c=d`）。
- HTTP 使用 `httpx.Client(http2=True)`；请求头会包含 provider 的 `api_user_key`（一般是 `new-api-user`）。
- 日志输出以 `print` 为主，包含 emoji（用于 Actions 日志阅读友好），许多 try/except 使用宽捕获，修改时注意不要破坏通知/错误传播逻辑。

## CI 注意事项（`.github/workflows/checkin.yml`） 🛠️
- Workflow 在 `windows-2025` 上运行，并使用 `astral-sh/setup-uv` 与 `actions/setup-python` 来安装环境。
- Playwright 浏览器有缓存步骤（缓存路径、版本），安装命令带 `--with-deps`。
- `balance_hash.txt` 被缓存在 workflow 中以便跨运行检测余额变化。

## 测试与调试建议 🔍
- 单元测试：`pytest`（项目 mock 网络请求，能在无真实外部依赖下跑）。
- 若要跑集成/真实通知测试：设置 `ENABLE_REAL_TEST=true` 与真实 `.env`/Secrets。小心不要把真实凭据推到公开仓库。
- 调试 Playwright：在本地把 `HEADLESS=False` 以便观察浏览器行为（`get_user/auto_login.py` 与 `checkin.py` 的 Playwright 都支持无头控制）。

## 变更小贴士给 AI 代理 💡
- 添加 provider：优先在 `utils/config.py` 的 `AppConfig.load_from_env` 保持默认并允许通过 `PROVIDERS` 覆盖，增加单元测试覆盖 `needs_waf_cookies()` 行为。
- 修改签名逻辑：保留“新接口优先、失败回退旧接口”的流程（这是本项目的容错策略）。
- 修改通知：`utils/notify.py` 使用同步 httpx 客户端，若改为异步需同步更新调用方 `checkin.py`。注意测试需要相应调整 mock。

---

如果这些点有遗漏或你想补充特定的编辑/重构指引（例如补充更多单元测试或添加 Provider 模板），告诉我具体方向，我会迭代更新本文件。✅
