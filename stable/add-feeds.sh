#!/bin/bash

# 添加第三方软件源到 ImageBuilder

echo "添加第三方软件源..."

# 自动检测架构
detect_arch() {
    # 从 PROFILE 环境变量中检测架构
    if [ -n "$PROFILE" ]; then
        case "$PROFILE" in
            *x86_64*|*x86-64*)
                echo "x86_64"
                ;;
            *aarch64*|*arm64*|*rockchip-armv8*)
                echo "aarch64_generic"
                ;;
            *arm*)
                echo "arm_cortex-a9"  # 默认 ARM 架构
                ;;
            *)
                echo "aarch64_generic"  # 默认架构
                ;;
        esac
    else
        # 从系统架构检测
        case "$(uname -m)" in
            x86_64)
                echo "x86_64"
                ;;
            aarch64|arm64)
                echo "aarch64_generic"
                ;;
            armv7l)
                echo "arm_cortex-a9"
                ;;
            *)
                echo "aarch64_generic"  # 默认架构
                ;;
        esac
    fi
}

ARCH=$(detect_arch)
echo "检测到架构: $ARCH"

# 直接追加到 repositories.conf（最兼容的方式）
if [ -f "repositories.conf" ]; then
    echo "备份原始 repositories.conf..."
    cp repositories.conf repositories.conf.backup
    
    echo "添加第三方源到 repositories.conf..."
    cat >> repositories.conf << EOF

## 第三方软件源 - 无签名文件（官方源保持签名验证）
# OpenWrt.ai kiddin9 源 (包含 PassWall2, MosDNS, Argon 主题, WOL Plus 等)
src/gz openwrt_ai_kiddin9 https://dl.openwrt.ai/packages-24.10/${ARCH}/kiddin9
EOF
    
    echo "第三方源添加完成（保持官方源签名验证）"
else
    echo "警告: repositories.conf 文件不存在"
    exit 1
fi

echo "第三方软件源添加完成"

# ImageBuilder 会在构建时自动处理软件包索引
# 不需要手动运行 opkg update