#!/bin/bash

# MosDNS 安装脚本 - 直接下载安装包

echo "开始下载 MosDNS..."

# 检测架构
detect_arch() {
    case "$PROFILE" in
        *x86_64*|*x86-64*)
            echo "x86_64"
            ;;
        *aarch64*|*arm64*|*rockchip-armv8*)
            echo "aarch64_generic"
            ;;
        *)
            echo "aarch64_generic"
            ;;
    esac
}

ARCH=$(detect_arch)
echo "检测到架构: $ARCH"

# 创建下载目录
mkdir -p packages/mosdns
cd packages/mosdns

# 获取最新版本号
echo "获取 MosDNS 最新版本..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/sbwml/luci-app-mosdns/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "最新版本: $LATEST_VERSION"

# 下载 MosDNS 安装包
echo "下载 MosDNS 安装包..."
if [ "$ARCH" = "aarch64_generic" ]; then
    wget -O mosdns.tar.gz "https://github.com/sbwml/luci-app-mosdns/releases/download/${LATEST_VERSION}/openwrt-24.10-aarch64_generic.tar.gz"
elif [ "$ARCH" = "x86_64" ]; then
    wget -O mosdns.tar.gz "https://github.com/sbwml/luci-app-mosdns/releases/download/${LATEST_VERSION}/openwrt-24.10-x86_64.tar.gz"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

# 解压安装包
if [ -f mosdns.tar.gz ]; then
    tar -xzf mosdns.tar.gz
    rm mosdns.tar.gz
    
    # 将解压出的 ipk 文件移动到当前目录
    if [ -d packages_ci ]; then
        mv packages_ci/*.ipk . 2>/dev/null || true
        rm -rf packages_ci
    fi
fi

cd ../..

echo "MosDNS 下载完成，文件保存在 packages/mosdns/ 目录"
ls -la packages/mosdns/