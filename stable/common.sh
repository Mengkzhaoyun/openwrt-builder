#!/bin/bash

# OpenWrt 公共配置管理器
# 自动扫描并加载 config 目录中的所有配置模块

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"

# 加载所有配置模块
load_config_modules() {
    echo "加载配置模块..."
    
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "警告: 配置目录不存在: $CONFIG_DIR"
        return 1
    fi
    
    # 扫描并加载所有 .sh 文件
    for config_file in "$CONFIG_DIR"/*.sh; do
        if [ -f "$config_file" ]; then
            local module_name=$(basename "$config_file" .sh)
            echo "  加载模块: $module_name"
            source "$config_file"
        fi
    done
    
    echo "配置模块加载完成"
}

# 应用所有基础配置
apply_all_configs() {
    local custom_ip=${1:-"192.168.1.253"}
    local gateway=${2:-"192.168.1.1"}
    local root_password="$3"
    local root_passkey="$4"
    local hostname=${5:-"openwrt"}
    
    echo "应用系统配置..."
    echo "  网络: IP=$custom_ip, 网关=$gateway"
    echo "  主机名: $hostname"
    echo ""
    
    # 确保目录存在
    mkdir -p "${ROOT_DIR}/files/etc/config"
    
    # 应用各项配置
    configure_network "$custom_ip" "$gateway"
    configure_dns "$dns_servers"
    configure_firewall
    configure_root_password "$root_password"
    configure_ssh_key "$root_passkey"
    configure_hostname "$hostname"
    configure_bash_shell
    
    echo "系统配置应用完成"
}

# 自动加载配置模块
load_config_modules

