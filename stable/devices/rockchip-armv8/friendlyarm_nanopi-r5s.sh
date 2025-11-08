#!/bin/bash

# FriendlyARM NanoPi R5S Device Configuration
# Architecture: rockchip-armv8
# Device: friendlyarm_nanopi-r5s
# Network Ports: 3 (1 WAN + 2 LAN)

DEVICE_ARCH="rockchip-armv8"
DEVICE_PROFILE="friendlyarm_nanopi-r5s"
DEVICE_NAME="FriendlyARM NanoPi R5S"

# Network configuration for R5S (3 ports) - 差异化配置
configure_network() {
    local custom_ip=${1}
    local gateway=${2}
    local dns_servers=${3}
    
    cat > ${ROOT_DIR}/files/etc/config/network << EOF
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
    list ports 'eth1'
    list ports 'eth2'

config interface 'lan'
    option device 'br-lan'
    option proto 'static'
    option ipaddr '$custom_ip'
    option netmask '255.255.255.0'
    option gateway '$gateway'
    list dns '$dns_servers'
EOF
}

# Device-specific package additions
add_device_packages() {
    echo "Adding R5S specific packages..."
    # R5S specific drivers and utilities can be added here
}

# Device-specific configurations
configure_device() {
    echo "Configuring FriendlyARM NanoPi R5S..."
    # R5S 设备特定配置（如果需要的话）
}