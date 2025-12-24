#!/usr/bin/env bash
set -euo pipefail

# Local simulation script for GitHub Actions workflow "AnyRouter 自动签到"
# Usage: ./scripts/run-workflow-sim.sh

# Backup existing .env if present
cp .env .env.bak || true

# Create simplified .env from existing .env.bak (keys the workflow uses)
awk -F= '/^(ANYROUTER_ACCOUNTS|PROVIDERS|ALWAYS_NOTIFY|EMAIL_USER|EMAIL_PASS|CUSTOM_SMTP_SERVER|EMAIL_TO|DINGDING_WEBHOOK|FEISHU_WEBHOOK|WEIXIN_WEBHOOK|PUSHPLUS_TOKEN|SERVERPUSHKEY)=/ {print}' .env.bak > .env || true

echo '--- Generated .env preview ---'
if [ -s .env ]; then sed -n '1,120p' .env; else echo '(no relevant vars found)'; fi

# Optional: ensure playwright browsers installed (uncomment if needed)
# python -m playwright install --with-deps

# Run checkin
./.venv/bin/python checkin.py
EXIT=$?

# Restore original .env
if [ -f .env.bak ]; then mv .env.bak .env; else rm -f .env; fi
exit $EXIT
