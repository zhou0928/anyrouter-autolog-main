#!/bin/bash

# AnyRouter 自动签到 - Docker 运行脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 .env 文件
check_env() {
    if [ ! -f ".env" ]; then
        print_error ".env 文件不存在！"
        print_info "请创建 .env 文件并配置账号信息"
        print_info "参考 .env.example 或 DOCKER_DEPLOYMENT.md"
        exit 1
    fi
}

# 检查 Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装！"
        print_info "请安装 Docker Desktop 或 OrbStack"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        print_error "Docker 未运行！"
        print_info "请启动 Docker Desktop 或 OrbStack"
        exit 1
    fi
}

# 构建镜像
build() {
    print_info "开始构建 Docker 镜像..."
    docker-compose build
    print_info "镜像构建完成！"
}

# 运行一次
run_once() {
    print_info "运行签到任务..."
    docker-compose run --rm anyrouter-checkin
}

# 后台运行
start() {
    print_info "启动容器（后台运行）..."
    docker-compose up -d
    print_info "容器已启动！"
}

# 停止
stop() {
    print_info "停止容器..."
    docker-compose stop
    print_info "容器已停止！"
}

# 重启
restart() {
    print_info "重启容器..."
    docker-compose restart
    print_info "容器已重启！"
}

# 查看日志
logs() {
    print_info "查看日志（Ctrl+C 退出）..."
    docker-compose logs -f --tail=100
}

# 查看状态
status() {
    print_info "容器状态："
    docker-compose ps
}

# 进入容器
shell() {
    print_info "进入容器 shell..."
    docker-compose exec anyrouter-checkin /bin/bash
}

# 清理
clean() {
    print_warn "这将删除容器和镜像，是否继续？(y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        print_info "清理容器和镜像..."
        docker-compose down --rmi all
        print_info "清理完成！"
    else
        print_info "取消清理"
    fi
}

# 更新
update() {
    print_info "更新项目..."
    git pull
    print_info "重新构建镜像..."
    docker-compose build --no-cache
    print_info "重启容器..."
    docker-compose up -d
    print_info "更新完成！"
}

# 测试代理
test_proxy() {
    print_info "测试代理连接..."
    docker-compose run --rm anyrouter-checkin /bin/bash -c "curl -x \$PROXY_URL https://api.ipify.org?format=json"
}

# 显示帮助
show_help() {
    cat << EOF
AnyRouter 自动签到 - Docker 管理脚本

用法: $0 [命令]

命令:
  build       构建 Docker 镜像
  run         运行一次签到任务
  start       启动容器（后台运行）
  stop        停止容器
  restart     重启容器
  logs        查看日志
  status      查看容器状态
  shell       进入容器 shell
  clean       清理容器和镜像
  update      更新项目并重新构建
  test-proxy  测试代理连接
  help        显示此帮助信息

示例:
  $0 build      # 首次使用，构建镜像
  $0 run        # 运行一次签到
  $0 start      # 后台运行
  $0 logs       # 查看日志

EOF
}

# 主函数
main() {
    check_docker
    check_env

    case "${1:-help}" in
        build)
            build
            ;;
        run)
            run_once
            ;;
        start)
            start
            ;;
        stop)
            stop
            ;;
        restart)
            restart
            ;;
        logs)
            logs
            ;;
        status)
            status
            ;;
        shell)
            shell
            ;;
        clean)
            clean
            ;;
        update)
            update
            ;;
        test-proxy)
            test_proxy
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
