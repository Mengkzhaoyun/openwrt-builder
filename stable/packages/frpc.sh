#!/bin/bash

# FRPC (awecloud-access-client) 配置脚本

echo "配置 FRPC (awecloud-access-client)..."

# 版本信息
FRPC_VERSION="v6.2.9"
FRPC_BASE_URL="https://github.com/open-beagle/awecloud-access/releases/download/${FRPC_VERSION}"

# 检测系统架构 - 与 packages.sh 保持一致
detect_architecture_frpc() {
    case "$PROFILE" in
        x86_64/*|*x86-64*)
            echo "amd64"
            ;;
        *aarch64*|*arm64*|*rockchip-armv8*)
            echo "arm64"
            ;;
        *)
            echo "arm64"  # 默认使用 arm64
            ;;
    esac
}

# 下载 FRPC 客户端
download_frpc() {
    local arch=$(detect_architecture_frpc)
    local filename="awecloud-access-client-${FRPC_VERSION}-linux-${arch}"
    local download_url="${FRPC_BASE_URL}/${filename}"
    local target_dir="${ROOT_DIR}/files/usr/bin"
    local target_file="${target_dir}/frpc"
    
    echo "检测到系统架构: $arch"
    echo "下载URL: $download_url"
    
    # 创建目标目录
    mkdir -p "$target_dir"
    
    # 下载文件
    echo "正在下载 awecloud-access-client..."
    if command -v wget >/dev/null 2>&1; then
        wget -O "$target_file" "$download_url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$target_file" "$download_url"
    else
        echo "错误: 未找到 wget 或 curl 命令" >&2
        exit 1
    fi
    
    # 检查下载是否成功
    if [ ! -f "$target_file" ]; then
        echo "错误: 下载失败" >&2
        exit 1
    fi
    
    # 给予执行权限
    chmod +x "$target_file"
    
    echo "FRPC 客户端下载完成: $target_file"
    echo "文件大小: $(ls -lh "$target_file" | awk '{print $5}')"
}

# 执行主函数
download_frpc