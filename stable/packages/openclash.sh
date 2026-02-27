#!/bin/bash

# OpenClash 安装脚本

echo "开始下载 OpenClash..."

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

# 检测 Meta 内核架构
detect_meta_arch() {
    case "$PROFILE" in
        *x86_64*|*x86-64*|x86/64)
            echo "amd64"
            ;;
        *aarch64*|*arm64*|*rockchip-armv8*)
            echo "arm64"
            ;;
        *)
            echo "arm64"
            ;;
    esac
}

ARCH=$(detect_arch)
META_ARCH=$(detect_meta_arch)
echo "检测到架构: $ARCH (Meta: $META_ARCH)"

# 创建必要的目录
mkdir -p ${ROOT_DIR}/bin/packages
mkdir -p ${ROOT_DIR}/files/etc/openclash/core
mkdir -p ${ROOT_DIR}/files/etc/openclash

cd ${ROOT_DIR}/bin/packages

# ==================== 下载 OpenClash IPK ====================
echo "获取 OpenClash 最新版本..."
OPENCLASH_VERSION=$(curl -s https://api.github.com/repos/vernesong/OpenClash/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "OpenClash 最新版本: $OPENCLASH_VERSION"

OPENCLASH_IPK="luci-app-openclash_${OPENCLASH_VERSION#v}_all.ipk"
if [ -f "$OPENCLASH_IPK" ]; then
    echo "OpenClash IPK 已存在于缓存中，跳过下载: $OPENCLASH_IPK"
else
    echo "下载 OpenClash IPK..."
    if wget "https://github.com/vernesong/OpenClash/releases/download/${OPENCLASH_VERSION}/${OPENCLASH_IPK}"; then
        echo "OpenClash IPK 下载成功"
    else
        echo "警告: OpenClash IPK 下载失败"
    fi
fi

# ==================== 下载 Clash Meta 内核 ====================
echo "获取 Clash Meta 内核最新版本..."
META_VERSION=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "Clash Meta 最新版本: $META_VERSION"

META_FILE="mihomo-linux-${META_ARCH}-${META_VERSION}.gz"
META_TARGET="${ROOT_DIR}/files/etc/openclash/core/clash_meta"

echo "下载 Clash Meta 内核..."
if wget "https://github.com/MetaCubeX/mihomo/releases/download/${META_VERSION}/${META_FILE}"; then
    echo "内核下载成功，开始解压..."
    gunzip -c "$META_FILE" > "$META_TARGET"
    chmod +x "$META_TARGET"
    rm "$META_FILE"
    echo "Clash Meta 内核已安装到: $META_TARGET"
    ls -lh "$META_TARGET"
else
    echo "警告: Clash Meta 内核下载失败"
fi

# ==================== 下载 GEO 数据库 ====================
echo "下载 GEO 数据库..."

# GeoIP.dat
GEO_TARGET="${ROOT_DIR}/files/etc/openclash"
echo "下载 GeoIP 数据库..."
if wget -O "${GEO_TARGET}/GeoIP.dat" "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat"; then
    echo "GeoIP 数据库下载成功"
    ls -lh "${GEO_TARGET}/GeoIP.dat"
else
    echo "警告: GeoIP 数据库下载失败"
fi

# GeoSite.dat
echo "下载 GeoSite 数据库..."
if wget -O "${GEO_TARGET}/GeoSite.dat" "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat"; then
    echo "GeoSite 数据库下载成功"
    ls -lh "${GEO_TARGET}/GeoSite.dat"
else
    echo "警告: GeoSite 数据库下载失败"
fi

# Country.mmdb
echo "下载 Country MMDB 数据库..."
if wget -O "${GEO_TARGET}/Country.mmdb" "https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country.mmdb"; then
    echo "Country MMDB 数据库下载成功"
    ls -lh "${GEO_TARGET}/Country.mmdb"
else
    echo "警告: Country MMDB 数据库下载失败"
fi

echo ""
echo "==================== OpenClash 下载完成 ===================="
echo "IPK 包:"
ls -lh ${ROOT_DIR}/bin/packages/luci-app-openclash* 2>/dev/null || echo "  未找到 OpenClash IPK 文件"
echo ""
echo "Meta 内核:"
ls -lh ${ROOT_DIR}/files/etc/openclash/core/clash_meta 2>/dev/null || echo "  未找到 Clash Meta 内核"
echo ""
echo "GEO 数据库:"
ls -lh ${ROOT_DIR}/files/etc/openclash/*.dat ${ROOT_DIR}/files/etc/openclash/*.mmdb 2>/dev/null || echo "  未找到 GEO 数据库"
echo "============================================================"
