#!/bin/bash

# WOL Plus 安装脚本

echo "开始下载 WOL Plus..."

# 创建下载目录
mkdir -p packages/wolplus
cd packages/wolplus

# 获取最新版本号
echo "获取 WOL Plus 最新版本..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/animegasan/luci-app-wolplus/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
echo "最新版本: $LATEST_VERSION"

# 下载 WOL Plus (从官方 GitHub 源码仓库下载)
echo "下载 WOL Plus 官方版本..."
wget "https://github.com/animegasan/luci-app-wolplus/releases/download/${LATEST_VERSION}/luci-app-wolplus_${LATEST_VERSION}_all.ipk"

cd ../..

echo "WOL Plus 下载完成，文件保存在 packages/wolplus/ 目录"
ls -la packages/wolplus/