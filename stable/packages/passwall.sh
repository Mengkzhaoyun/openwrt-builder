#!/bin/bash

# PassWall2 安装脚本

echo "开始下载 PassWall2..."

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
echo "获取 PassWall2 最新版本..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/xiaorouji/openwrt-passwall2/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "最新版本: $LATEST_VERSION"

# 下载 PassWall2 主程序 (适用于 OpenWrt 24.10)
# 从 GitHub API 获取实际的文件名，而不是猜测格式

echo "获取 PassWall2 实际文件名..."

# 获取 release 中的所有文件名
RELEASE_FILES=$(curl -s "https://api.github.com/repos/xiaorouji/openwrt-passwall2/releases/latest" | grep '"name"' | grep '\.ipk"' | cut -d'"' -f4)

# 搜索匹配的主程序文件
PASSWALL_MAIN=$(echo "$RELEASE_FILES" | grep "luci-24.10_luci-app-passwall2_.*_all.ipk" | head -1)

# 搜索匹配的语言包文件  
PASSWALL_LANG=$(echo "$RELEASE_FILES" | grep "luci-24.10_luci-i18n-passwall2-zh-cn_.*_all.ipk" | head -1)

echo "找到主程序文件: $PASSWALL_MAIN"
echo "找到语言包文件: $PASSWALL_LANG"

if [ -z "$PASSWALL_MAIN" ] || [ -z "$PASSWALL_LANG" ]; then
    echo "警告: 未找到匹配的 PassWall2 文件，跳过下载"
    echo "可用文件列表:"
    echo "$RELEASE_FILES"
    exit 0
fi

# 生成重命名后的文件名（完全去掉 luci-24.10_ 前缀）
PASSWALL_MAIN_RENAMED=$(echo "$PASSWALL_MAIN" | sed 's/luci-24\.10_//')
PASSWALL_LANG_RENAMED=$(echo "$PASSWALL_LANG" | sed 's/luci-24\.10_//')

echo "重命名后的主程序文件: $PASSWALL_MAIN_RENAMED"
echo "重命名后的语言包文件: $PASSWALL_LANG_RENAMED"

# 下载主程序
if [ -f "$PASSWALL_MAIN_RENAMED" ]; then
    echo "PassWall2 主程序已存在于缓存中，跳过下载: $PASSWALL_MAIN_RENAMED"
else
    echo "下载 PassWall2 主程序..."
    if wget "https://github.com/xiaorouji/openwrt-passwall2/releases/download/${LATEST_VERSION}/$PASSWALL_MAIN"; then
        echo "重命名主程序文件: $PASSWALL_MAIN -> $PASSWALL_MAIN_RENAMED"
        mv "$PASSWALL_MAIN" "$PASSWALL_MAIN_RENAMED"
        echo "PassWall2 主程序下载并重命名成功"
    else
        echo "警告: PassWall2 主程序下载失败"
    fi
fi

# 下载中文语言包
if [ -f "$PASSWALL_LANG_RENAMED" ]; then
    echo "PassWall2 中文语言包已存在于缓存中，跳过下载: $PASSWALL_LANG_RENAMED"
else
    echo "下载 PassWall2 中文语言包..."
    if wget "https://github.com/xiaorouji/openwrt-passwall2/releases/download/${LATEST_VERSION}/$PASSWALL_LANG"; then
        echo "重命名语言包文件: $PASSWALL_LANG -> $PASSWALL_LANG_RENAMED"
        mv "$PASSWALL_LANG" "$PASSWALL_LANG_RENAMED"
        echo "PassWall2 中文语言包下载并重命名成功"
    else
        echo "警告: PassWall2 中文语言包下载失败"
    fi
fi

# 下载 PassWall2 依赖包
echo "下载 PassWall2 依赖包..."
if [ "$ARCH" = "aarch64_generic" ]; then
    DEPS_FILE="passwall_packages_ipk_aarch64_generic.zip"
elif [ "$ARCH" = "x86_64" ]; then
    DEPS_FILE="passwall_packages_ipk_x86_64.zip"
else
    echo "警告: 架构 $ARCH 没有对应的 PassWall2 依赖包，跳过依赖包下载"
    DEPS_FILE=""
fi

if [ -n "$DEPS_FILE" ]; then
    if [ -f "$DEPS_FILE" ]; then
        echo "PassWall2 依赖包已存在，跳过下载: $DEPS_FILE"
    else
        wget "https://github.com/xiaorouji/openwrt-passwall2/releases/download/${LATEST_VERSION}/$DEPS_FILE"
    fi
    
    if [ -f "$DEPS_FILE" ]; then
        echo "解压依赖包..."
        # 创建临时目录解压，避免覆盖已有文件
        mkdir -p temp_passwall_deps
        unzip -o "$DEPS_FILE" -d temp_passwall_deps
        
        # 只移动不存在的 IPK 文件
        if [ -d temp_passwall_deps ]; then
            for ipk_file in temp_passwall_deps/*.ipk; do
                if [ -f "$ipk_file" ]; then
                    filename=$(basename "$ipk_file")
                    if [ ! -f "$filename" ]; then
                        echo "添加依赖包: $filename"
                        mv "$ipk_file" .
                    else
                        echo "跳过已存在的文件: $filename"
                    fi
                fi
            done
            rm -rf temp_passwall_deps
        fi
        
        rm "$DEPS_FILE"
        echo "依赖包解压完成"
    fi
fi

echo "PassWall2 下载完成，文件保存在 bin/packages/ 目录"
ls -la ${ROOT_DIR}/bin/packages/luci-app-passwall2*