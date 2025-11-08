#!/bin/bash

# WOL Plus 安装脚本

echo "开始下载 WOL Plus..."
cd ${ROOT_DIR}/bin/packages

# 获取最新版本号
echo "获取 WOL Plus 最新版本..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/animegasan/luci-app-wolplus/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "最新版本: $LATEST_VERSION"

# 下载 WOL Plus (从官方 GitHub 源码仓库下载)
WOLPLUS_FILE="luci-app-wolplus_${LATEST_VERSION}_all.ipk"
if [ -f "$WOLPLUS_FILE" ]; then
    echo "WOL Plus 文件已存在于缓存中，跳过下载: $WOLPLUS_FILE"
else
    echo "下载 WOL Plus 官方版本..."
    if wget "https://github.com/animegasan/luci-app-wolplus/releases/download/${LATEST_VERSION}/$WOLPLUS_FILE"; then
        echo "WOL Plus 下载成功"
    else
        echo "警告: WOL Plus 下载失败，将跳过此软件包"
    fi
fi

echo "WOL Plus 下载完成，文件保存在 bin/packages/ 目录"
ls -la ${ROOT_DIR}/bin/packages/luci-app-wolplus*