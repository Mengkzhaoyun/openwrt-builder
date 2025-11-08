#!/bin/bash

# OpenWrt 软件包配置脚本
# 在这里配置需要安装的软件包
# 
# 注意: 由于签名验证问题，已移除所有第三方软件包
# 只使用官方源的软件包

echo "配置软件包列表..."

PACKAGES=""

# 基础系统包
PACKAGES="$PACKAGES bash"                 # 安装bash shell
PACKAGES="$PACKAGES -dnsmasq"             # 移除默认dnsmasq
PACKAGES="$PACKAGES dnsmasq-full"         # 安装完整版dnsmasq
PACKAGES="$PACKAGES -uhttpd"              # 移除默认uhttpd web服务器
PACKAGES="$PACKAGES -uhttpd-mod-ubus"     # 移除uhttpd ubus模块
PACKAGES="$PACKAGES nginx-ssl"            # 安装nginx (支持SSL)
PACKAGES="$PACKAGES luci-nginx"           # LuCI nginx配置
PACKAGES="$PACKAGES luci"                 # Web管理界面
PACKAGES="$PACKAGES ca-bundle"            # CA证书包
PACKAGES="$PACKAGES openssh-sftp-server"  # SFTP服务器

# 网络工具
PACKAGES="$PACKAGES curl"               # HTTP客户端
PACKAGES="$PACKAGES ip-full"            # 完整版ip命令
PACKAGES="$PACKAGES yq"                 # YAML处理工具

# 内核模块
PACKAGES="$PACKAGES kmod-tun"           # TUN/TAP支持
PACKAGES="$PACKAGES kmod-inet-diag"     # 网络诊断模块
PACKAGES="$PACKAGES kmod-nft-tproxy"    # 透明代理支持
PACKAGES="$PACKAGES kmod-nft-socket"    # 透明代理支持

# 官方中文语言包
PACKAGES="$PACKAGES luci-i18n-base-zh-cn"           # 基础中文包
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"       # 防火墙中文包
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn" # 软件包管理中文包

# 官方应用程序
PACKAGES="$PACKAGES luci-app-ttyd luci-i18n-ttyd-zh-cn"         # Web终端
PACKAGES="$PACKAGES luci-app-frpc luci-i18n-frpc-zh-cn"         # FRP客户端
PACKAGES="$PACKAGES luci-app-upnp luci-i18n-upnp-zh-cn"         # Upnp服务


# Argon Theme 依赖包
PACKAGES="$PACKAGES luci-compat"                    # LuCI 兼容性库
PACKAGES="$PACKAGES luci-lib-ipkg"                  # LuCI IPKG 库

# === 官方主题 ===
# PACKAGES="$PACKAGES luci-theme-material"          # Material 现代化主题 (已禁用，使用 Argon)

# 可选软件包 - 根据需要取消注释
PACKAGES="$PACKAGES wget-ssl"          # 支持SSL的wget
PACKAGES="$PACKAGES nano"              # 文本编辑器
PACKAGES="$PACKAGES htop"              # 系统监控工具
PACKAGES="$PACKAGES iperf3"            # 网络性能测试
PACKAGES="$PACKAGES tcpdump"           # 网络抓包工具
# PACKAGES="$PACKAGES wireguard-tools"   # WireGuard VPN工具

# 集成第三方软件包到构建中
integrate_custom_packages() {
    echo "集成第三方软件包..."
    
    # 检查第三方包目录
    if [ ! -d "${ROOT_DIR}/bin/packages" ]; then
        echo "未找到第三方软件包目录"
        return 0
    fi
    
    # 检查是否有 IPK 文件需要安装
    if [ ! "$(ls -A ${ROOT_DIR}/bin/packages/ 2>/dev/null)" ]; then
        echo "未找到第三方软件包文件"
        return 0
    fi
    
    echo "找到以下第三方软件包:"
    ls -1 ${ROOT_DIR}/bin/packages/*.ipk | xargs -I {} basename {} .ipk
    
    # 将第三方包集成到 ImageBuilder 的包目录中
    echo "集成第三方包到 ImageBuilder..."
    
    # 检测架构
    local arch_dir
    case "$PROFILE" in
        x86_64/*|*x86-64*)
            arch_dir="x86_64"
            ;;
        *aarch64*|*arm64*|*rockchip-armv8*)
            arch_dir="aarch64_generic"
            ;;
        *)
            arch_dir="aarch64_generic"
            ;;
    esac
    
    # 创建架构特定的包目录
    local packages_dir="${ROOT_DIR}/packages/packages/${arch_dir}"
    mkdir -p "$packages_dir"
    
    # 复制第三方包到 ImageBuilder 的包目录
    echo "复制第三方包到: $packages_dir"
    cp ${ROOT_DIR}/bin/packages/*.ipk "$packages_dir/" 2>/dev/null || true
    
    # 在包目录中生成索引
    cd "$packages_dir"
    if command -v opkg-make-index >/dev/null 2>&1; then
        echo "生成包索引..."
        opkg-make-index . > Packages
        gzip -c Packages > Packages.gz
    else
        echo "警告: 未找到 opkg-make-index，跳过索引生成"
    fi
    
    cd ${ROOT_DIR}
    echo "第三方包集成完成"
    
    # 从 IPK 文件名提取包名并添加到 PACKAGES
    local custom_packages=""
    declare -A seen_packages  # 用于去重
    
    for ipk in ${ROOT_DIR}/bin/packages/*.ipk; do
        if [ -f "$ipk" ]; then
            # 提取包名（处理不同的命名格式）
            local filename=$(basename "$ipk" .ipk)
            local pkg_name
            
            # 处理标准的 package-name_version_arch.ipk 格式
            if [[ "$filename" =~ ^([^_]+)_[0-9] ]]; then
                pkg_name="${BASH_REMATCH[1]}"
            # 处理复杂包名，如 package-name-with-dashes_version_arch.ipk
            else
                pkg_name=$(echo "$filename" | sed 's/_[0-9].*$//')
            fi
            
            # 去重处理
            if [ -z "${seen_packages[$pkg_name]}" ]; then
                echo "提取包名: $filename -> $pkg_name"
                custom_packages="$custom_packages $pkg_name"
                seen_packages[$pkg_name]=1
            fi
        fi
    done
    
    # 更新 PACKAGES 变量
    if [ -n "$custom_packages" ]; then
        PACKAGES="$PACKAGES $custom_packages"
        echo "已将第三方软件包添加到构建列表: $custom_packages"
    fi
}

echo "软件包列表配置完成"
echo "包含的软件包: $PACKAGES"

# 导出PACKAGES变量供build.sh使用
export PACKAGES