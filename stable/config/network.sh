#!/bin/bash

# 网络配置模块

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
    list ports 'eth1'
    list ports 'eth2'
    list ports 'eth3'
    list ports 'eth4'
    list ports 'eth5'

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