#!/bin/bash

# 防火墙配置模块

configure_firewall() {
    echo "配置防火墙规则"
    
    cat > "${ROOT_DIR}/files/etc/config/firewall" << 'EOF'
config defaults
    option syn_flood '1'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'REJECT'
    option flow_offloading '1'
    option flow_offloading_hw '1'

config zone
    option name 'lan'
    list network 'lan'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'ACCEPT'
EOF
    
    echo "防火墙配置完成"
}