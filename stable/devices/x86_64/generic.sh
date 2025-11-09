#!/bin/bash

# x86_64 Virtual Machine Device Configuration
# Architecture: x86
# Device: 64 (generic x86_64)
# Network Ports: 1 (eth0 - single interface for VM)

DEVICE_ARCH="x86_64"
DEVICE_PROFILE="generic"
DEVICE_NAME="x86_64 Virtual Machine"

# Network configuration for x86_64 VM (single port) - 虚拟机配置
configure_network() {
    local custom_ip=${1:-"192.168.1.253"}
    local gateway=${2:-"192.168.1.1"}
    
    echo "配置网络: IP=$custom_ip, 网关=$gateway"
    
    cat > "${ROOT_DIR}/files/etc/config/network" << EOF
config interface 'loopback'
    option ifname 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config globals 'globals'
    option ula_prefix 'fd12:3456:789a::/48'

config device
    option name 'br-lan'
    option type 'bridge'
    list ports 'eth0'

config interface 'lan'
    option device 'br-lan'
    option proto 'static'
    option ipaddr '$custom_ip'
    option netmask '255.255.255.0'
    option gateway '$gateway'
    list dns '$custom_ip'
EOF
    
    echo "网络配置完成"
}

# Device-specific package additions
add_device_packages() {
    echo "Adding x86_64 VM specific packages..."
    # VM 特定的驱动和工具
    PACKAGES="$PACKAGES kmod-e1000"      # Intel E1000 网卡驱动（常见虚拟网卡）
    PACKAGES="$PACKAGES kmod-vmxnet3"    # VMware 网卡驱动
    # VirtIO 驱动通常已内置在 x86_64 内核中，如需要可手动添加
}

# Device-specific configurations
configure_device() {
    echo "Configuring x86_64 Virtual Machine..."
    
    # 虚拟机优化配置
    mkdir -p ${ROOT_DIR}/files/etc/sysctl.d
    cat > ${ROOT_DIR}/files/etc/sysctl.d/99-vm-optimize.conf << 'EOF'
# 虚拟机优化配置
vm.swappiness=10
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 65536 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
EOF
    
    echo "x86_64 虚拟机配置完成"
}