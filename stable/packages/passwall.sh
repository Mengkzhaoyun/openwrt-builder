#!/bin/bash

# PassWall2 安装脚本

echo "开始下载 PassWall2..."

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
mkdir -p packages/passwall
cd packages/passwall

# 获取最新版本号
echo "获取 PassWall2 最新版本..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/xiaorouji/openwrt-passwall2/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "最新版本: $LATEST_VERSION"

# 下载 PassWall2 主程序 (适用于 OpenWrt 24.10)
echo "下载 PassWall2 主程序..."
wget "https://github.com/xiaorouji/openwrt-passwall2/releases/download/${LATEST_VERSION}/luci-24.10_luci-app-passwall2_${LATEST_VERSION}_all.ipk"

# 下载 PassWall2 中文语言包
echo "下载 PassWall2 中文语言包..."
wget "https://github.com/xiaorouji/openwrt-passwall2/releases/download/${LATEST_VERSION}/luci-24.10_luci-i18n-passwall2-zh-cn_${LATEST_VERSION}_all.ipk"

# 下载 PassWall2 依赖包
echo "下载 PassWall2 依赖包..."
if [ "$ARCH" = "aarch64_generic" ]; then
    wget -O passwall_deps.zip "https://github.com/xiaorouji/openwrt-passwall2/releases/download/${LATEST_VERSION}/passwall_packages_ipk_aarch64_generic.zip"
elif [ "$ARCH" = "x86_64" ]; then
    wget -O passwall_deps.zip "https://github.com/xiaorouji/openwrt-passwall2/releases/download/${LATEST_VERSION}/passwall_packages_ipk_x86_64.zip"
else
    echo "警告: 架构 $ARCH 没有对应的 PassWall2 依赖包，跳过依赖包下载"
fi

if [ -f passwall_deps.zip ]; then
    echo "解压依赖包..."
    unzip -o passwall_deps.zip
    rm passwall_deps.zip
    echo "依赖包解压完成"
fi

cd ../..

echo "PassWall2 下载完成，文件保存在 packages/passwall/ 目录"
ls -la packages/passwall/