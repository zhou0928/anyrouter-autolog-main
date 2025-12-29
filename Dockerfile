# 使用 Python 3.11 作为基础镜像
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 安装系统依赖（Playwright 需要）
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libwayland-client0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY pyproject.toml uv.lock ./
COPY checkin.py ./
COPY utils/ ./utils/
COPY get_user/ ./get_user/

# 安装 UV 包管理器
RUN pip install --no-cache-dir uv

# 使用 UV 安装 Python 依赖
RUN uv sync --frozen

# 安装 Playwright 浏览器
RUN uv run playwright install chromium --with-deps

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8

# 创建非 root 用户
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser

# 默认命令
CMD ["uv", "run", "checkin.py"]
