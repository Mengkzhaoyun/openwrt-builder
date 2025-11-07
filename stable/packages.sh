#!/bin/bash

# OpenWrt 软件包配置脚本
# 在这里配置需要安装的软件包

echo "配置软件包列表..."

PACKAGES=""

# 基础系统包
PACKAGES="$PACKAGES -dnsmasq"           # 移除默认dnsmasq
PACKAGES="$PACKAGES dnsmasq-full"       # 安装完整版dnsmasq
PACKAGES="$PACKAGES -uhttpd"            # 移除默认uhttpd web服务器
PACKAGES="$PACKAGES -uhttpd-mod-ubus"   # 移除uhttpd ubus模块
PACKAGES="$PACKAGES nginx-ssl"          # 安装nginx (支持SSL)
PACKAGES="$PACKAGES luci-nginx"         # LuCI nginx配置
PACKAGES="$PACKAGES luci"               # Web管理界面
PACKAGES="$PACKAGES ca-bundle"          # CA证书包

# 网络工具
PACKAGES="$PACKAGES curl"               # HTTP客户端
PACKAGES="$PACKAGES ip-full"            # 完整版ip命令
PACKAGES="$PACKAGES yq"                 # YAML处理工具

# 内核模块
PACKAGES="$PACKAGES kmod-tun"           # TUN/TAP支持
PACKAGES="$PACKAGES kmod-inet-diag"     # 网络诊断模块
PACKAGES="$PACKAGES kmod-nft-tproxy"    # 透明代理支持

# 官方中文语言包
PACKAGES="$PACKAGES luci-i18n-base-zh-cn"           # 基础中文包
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"       # 防火墙中文包
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn" # 软件包管理中文包

# 官方应用程序
PACKAGES="$PACKAGES luci-app-ttyd"                  # Web终端
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"           # TTYD中文语言包
PACKAGES="$PACKAGES luci-app-frpc"                  # FRP客户端

# === 官方主题 ===
PACKAGES="$PACKAGES luci-theme-material"            # Material 现代化主题

# === 第三方软件包 ===
# 注意: 以下三个包通过 ipk_download.sh 单独下载安装，不在这里配置
# - luci-app-passwall2 (PassWall2 代理工具)
# - luci-app-wolplus (网络唤醒增强版)
# - luci-app-mosdns (MosDNS DNS分流)

# 可选软件包 - 根据需要取消注释
PACKAGES="$PACKAGES wget-ssl"          # 支持SSL的wget
PACKAGES="$PACKAGES nano"              # 文本编辑器
PACKAGES="$PACKAGES htop"              # 系统监控工具
PACKAGES="$PACKAGES iperf3"            # 网络性能测试
PACKAGES="$PACKAGES tcpdump"           # 网络抓包工具
# PACKAGES="$PACKAGES wireguard-tools"   # WireGuard VPN工具

echo "软件包列表配置完成"
echo "包含的软件包: $PACKAGES"

# 导出PACKAGES变量供build.sh使用
export PACKAGES