#!/bin/bash

# Argon Theme 安装脚本

echo "开始下载 Argon Theme..."

cd ${ROOT_DIR}/bin/packages

# Argon Theme 版本信息
ARGON_VERSION="v2.3.2"
ARGON_DATE="r20250207"
ARGON_FILE="luci-theme-argon_2.3.2-${ARGON_DATE}_all.ipk"

echo "下载 Argon Theme 版本: $ARGON_VERSION"

# 下载 Argon Theme
if [ -f "$ARGON_FILE" ]; then
    echo "Argon Theme 已存在于缓存中，跳过下载: $ARGON_FILE"
else
    echo "下载 Argon Theme..."
    if wget --no-check-certificate "https://github.com/jerrykuku/luci-theme-argon/releases/download/${ARGON_VERSION}/${ARGON_FILE}"; then
        echo "Argon Theme 下载成功: $ARGON_FILE"
    else
        echo "警告: Argon Theme 下载失败"
        exit 1
    fi
fi

echo "Argon Theme 下载完成，文件保存在 bin/packages/ 目录"
ls -la ${ROOT_DIR}/bin/packages/luci-theme-argon*