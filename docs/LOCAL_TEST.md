# 本地测试 GitHub Actions workflow（模拟）

这个文档说明如何在本地模拟 `.github/workflows/check-in.yml` 的关键步骤并运行 `checkin.py`，不需要实际触发 GitHub Actions。

前提：
- 已激活项目虚拟环境，或使用项目内 `.venv` 的 Python：`./.venv/bin/python`
- 已安装依赖（`python -m pip install -r requirements.txt`），并且 Playwright 可选安装（`python -m playwright install --with-deps`）

快速运行（推荐）：

1. 运行脚本

```bash
chmod +x scripts/run-workflow-sim.sh
./scripts/run-workflow-sim.sh
```

脚本会：
- 备份当前 `.env`（如果存在）为 `.env.bak`
- 从 `.env.bak` 中复制 workflow 关心的环境变量到新的 `.env`
- 运行 `checkin.py`
- 运行完成后恢复原 `.env`

2. 如果你希望强制发送通知以验证推送：

```bash
# 设置为始终通知（手动测试）
export ALWAYS_NOTIFY=true
./scripts/run-workflow-sim.sh
```

3. 恢复工作目录

脚本会自动恢复 `.env`，但如果出问题可以手动恢复：

```bash
mv .env.bak .env
```

安全与注意事项：
- 请勿在公共仓库中提交包含真实凭证的 `.env` 文件；使用 GitHub Secrets 来保存敏感信息。 
- 若你不想向外网推送通知，请在运行前取消 `.env` 中相应的 webhook/凭证，或使用 `ALWAYS_NOTIFY=false` 来避免发送通知。

---
如果你需要我把这些改动提交并创建 PR，我可以继续。