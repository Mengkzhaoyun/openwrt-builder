#!/bin/bash

export ROOT_DIR="/builder"

# 加载公共配置函数
source "${ROOT_DIR}/src/common.sh"

# 检查必需的环境变量
if [ -z "$PROFILE" ]; then
    echo "错误: 必须设置 PROFILE 环境变量"
    echo "示例: PROFILE=\"rockchip-armv8/friendlyarm_nanopi-r5s\""
    exit 1
fi

if [ -z "$ROOT_PASSWORD" ]; then
    echo "错误: 必须设置 ROOT_PASSWORD 环境变量"
    echo "示例: ROOT_PASSWORD=\"your_password\""
    exit 1
fi

if [ -z "$ROOT_PASSKEY" ]; then
    echo "错误: 必须设置 ROOT_PASSKEY 环境变量"
    echo "示例: ROOT_PASSKEY=\"ssh-rsa AAAAB3NzaC1yc2E...\""
    exit 1
fi

# 网络配置 - 使用默认值
CUSTOM_IP="${CUSTOM_IP:-192.168.1.253}"
GATEWAY="${GATEWAY:-192.168.1.1}"
DNS_SERVERS="${DNS_SERVERS:-192.168.1.1}"

# 从 PROFILE 中解析设备信息
DEVICE_ARCH=$(echo "$PROFILE" | cut -d'/' -f1)
DEVICE_NAME=$(echo "$PROFILE" | cut -d'/' -f2)
DEVICE_CONFIG="${ROOT_DIR}/src/devices/${DEVICE_ARCH}/${DEVICE_NAME}.sh"

# 签名验证配置已移除（ImageBuilder 不支持重编译 opkg）

# 加载设备配置
if [ -f "$DEVICE_CONFIG" ]; then
    echo "加载设备配置: $DEVICE_ARCH/$DEVICE_NAME"
    source "$DEVICE_CONFIG"
else
    echo "警告: 设备配置文件不存在: $DEVICE_CONFIG"
    echo "将使用通用配置"
    # 如果没有设备配置文件，使用解析出的名称作为 profile
    DEVICE_PROFILE="$DEVICE_NAME"
fi

# 显示当前配置
echo "设备配置: $PROFILE"
echo "网络配置:"
echo "  IP地址: $CUSTOM_IP"
echo "  网关地址: $GATEWAY"
echo "  DNS服务器: $DNS_SERVERS"
echo ""

mkdir -p "${ROOT_DIR}/files/etc/config"

# 应用基础系统配置
echo "应用系统配置..."

# 配置网络（始终应用）
configure_network "$CUSTOM_IP" "$GATEWAY" "$DNS_SERVERS"

# 配置DNS（始终应用）
configure_dns "$DNS_SERVERS"

# 配置防火墙（始终应用）
configure_firewall

# 配置root密码（必需）
configure_root_password "$ROOT_PASSWORD"

# 配置SSH公钥认证（必需）
configure_ssh_key "$ROOT_PASSKEY"

# 配置主机名和bash shell
configure_hostname "openwrt"
configure_bash_shell

# 加载软件包配置
[ -x "${ROOT_DIR}/src/packages.sh" ] && source "${ROOT_DIR}/src/packages.sh"

# 下载第三方软件包
echo "下载第三方软件包..."
mkdir -p ${ROOT_DIR}/bin/packages
[ -x "${ROOT_DIR}/src/packages/argon.sh" ] && "${ROOT_DIR}/src/packages/argon.sh"
[ -x "${ROOT_DIR}/src/packages/passwall.sh" ] && "${ROOT_DIR}/src/packages/passwall.sh"
[ -x "${ROOT_DIR}/src/packages/mosdns.sh" ] && "${ROOT_DIR}/src/packages/mosdns.sh"
[ -x "${ROOT_DIR}/src/packages/wolplus.sh" ] && "${ROOT_DIR}/src/packages/wolplus.sh"
[ -x "${ROOT_DIR}/src/packages/nginx.sh" ] && "${ROOT_DIR}/src/packages/nginx.sh"

# 添加设备特定的软件包
if command -v add_device_packages >/dev/null 2>&1; then
    add_device_packages
fi

# 执行设备特定配置
if command -v configure_device >/dev/null 2>&1; then
    configure_device
fi

# PROFILE 已通过环境变量传入，无需处理

# 检查设备配置文件是否存在
if [ -f "profiles.json" ]; then
    echo "检查可用设备配置..."
    if command -v jq >/dev/null 2>&1; then
        jq -r '.profiles | keys[]' profiles.json
    else
        echo "可用设备配置文件:"
        grep -o '"[^"]*":' profiles.json | tr -d '":' | head -10
    fi
fi

echo "构建设备: $DEVICE_PROFILE (来自 $PROFILE)"
echo "开始构建镜像（通过构建配置禁用签名验证）..."

# 集成第三方软件包
integrate_custom_packages

# 构建最终镜像（包含第三方软件包和配置文件）
echo "构建最终镜像..."
echo "构建设备: $DEVICE_NAME (Profile: $DEVICE_PROFILE)"
cd ${ROOT_DIR}
[ -x "${ROOT_DIR}/setup.sh" ] && "${ROOT_DIR}/setup.sh"
make image PROFILE="$DEVICE_PROFILE" PACKAGES="$PACKAGES" ROOTFS_PARTSIZE="1024" FILES="${ROOT_DIR}/files"