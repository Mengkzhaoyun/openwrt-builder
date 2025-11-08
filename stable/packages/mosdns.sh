#!/bin/bash

# MosDNS 安装脚本 - 直接下载安装包

echo "开始下载 MosDNS..."

# 检测架构
detect_arch() {
    case "$PROFILE" in
        *x86_64*|*x86-64*|x86/64)
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

cd ${ROOT_DIR}/bin/packages

# 获取最新版本号
echo "获取 MosDNS 最新版本..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/sbwml/luci-app-mosdns/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "最新版本: $LATEST_VERSION"

# 下载 MosDNS 安装包
if [ "$ARCH" = "aarch64_generic" ]; then
    MOSDNS_FILE="openwrt-24.10-aarch64_generic.tar.gz"
elif [ "$ARCH" = "x86_64" ]; then
    MOSDNS_FILE="openwrt-24.10-x86_64.tar.gz"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

# 检查是否已有 MosDNS 相关文件
if ls *mosdns*.ipk >/dev/null 2>&1; then
    echo "MosDNS 文件已存在于缓存中，跳过下载"
else
    echo "下载 MosDNS 安装包..."
    if wget -O "$MOSDNS_FILE" "https://github.com/sbwml/luci-app-mosdns/releases/download/${LATEST_VERSION}/$MOSDNS_FILE"; then
        echo "下载成功，解压安装包..."
        tar -xzf "$MOSDNS_FILE"
        rm "$MOSDNS_FILE"
        
        # 将解压出的 ipk 文件移动到当前目录
        if [ -d packages_ci ]; then
            mv packages_ci/*.ipk . 2>/dev/null || true
            rm -rf packages_ci
        fi
        
        # 检查是否成功解压出 ipk 文件
        if ! ls *mosdns*.ipk >/dev/null 2>&1; then
            echo "警告: 未找到 MosDNS IPK 文件，可能下载或解压失败"
        fi
    else
        echo "警告: MosDNS 下载失败，将跳过此软件包"
    fi
fi

echo "MosDNS 下载完成，文件保存在 bin/packages/ 目录"
ls -la ${ROOT_DIR}/bin/packages/luci-app-mosdns*