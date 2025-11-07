#!/bin/bash

# OpenWrt 公共配置函数
# 包含网络、DNS、密码、SSH等通用配置

# 通用网络配置函数 - 所有网口组成 br-lan
configure_network() {
    local custom_ip=${1:-"192.168.1.253"}
    local gateway=${2:-"192.168.1.1"}
    local dns_servers=${3:-"192.168.1.1"}
    
    cat > files/etc/config/network << EOF
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
    option ip6assign '60'
    option gateway '$gateway'
    list dns '$dns_servers'
EOF
}

# DNS 配置函数
configure_dns() {
    local dns_servers=${1:-"192.168.1.1"}
    
    echo "设置DNS服务器: $dns_servers"
    
    # 创建resolv.conf
    cat > files/etc/resolv.conf << EOF
# 自定义DNS配置
EOF
    for dns in $dns_servers; do
        echo "nameserver $dns" >> files/etc/resolv.conf
    done
    
    # 配置dhcp和dns
    cat > files/etc/config/dhcp << EOF
config dnsmasq
	option domainneeded '1'
	option boguspriv '1'
	option filterwin2k '0'
	option localise_queries '1'
	option rebind_protection '1'
	option rebind_localhost '1'
	option local '/lan/'
	option domain 'lan'
	option expandhosts '1'
	option nonegcache '0'
	option cachesize '1000'
	option authoritative '1'
	option readethers '1'
	option leasefile '/tmp/dhcp.leases'
	option resolvfile '/tmp/resolv.conf.d/resolv.conf.auto'
	option nonwildcard '1'
	option localservice '1'
	option ednspacket_max '1232'
EOF
    
    # 添加上游DNS服务器
    for dns in $dns_servers; do
        cat >> files/etc/config/dhcp << EOF

config dnsmasq
	list server '$dns'
EOF
    done
    
    cat >> files/etc/config/dhcp << EOF

config dhcp 'lan'
	option interface 'lan'
	option start '100'
	option limit '150'
	option leasetime '12h'
	option dhcpv4 'server'
	option dhcpv6 'server'
	option ra 'server'
	list dhcp_option '6,$dns_servers'

config dhcp 'wan'
	option interface 'wan'
	option ignore '1'

config odhcpd 'odhcpd'
	option maindhcp '0'
	option leasefile '/tmp/hosts/odhcpd'
	option leasetrigger '/usr/sbin/odhcpd-update'
	option loglevel '4'
EOF
}

# Root 密码配置函数
configure_root_password() {
    local root_password="$1"
    
    if [ -n "$root_password" ]; then
        echo "设置root密码..."
        # 生成密码哈希
        PASSWORD_HASH=$(openssl passwd -1 "$root_password")
        cat > files/etc/shadow << EOF
root:$PASSWORD_HASH:19797:0:99999:7:::
daemon:*:0:0:99999:7:::
ftp:*:0:0:99999:7:::
network:*:0:0:99999:7:::
nobody:*:0:0:99999:7:::
ntp:x:0:0:99999:7:::
dnsmasq:x:0:0:99999:7:::
logd:x:0:0:99999:7:::
ubus:x:0:0:99999:7:::
EOF
        chmod 600 files/etc/shadow
    fi
}

# SSH 公钥认证配置函数
configure_ssh_key() {
    local root_passkey="$1"
    
    if [ -n "$root_passkey" ]; then
        echo "设置SSH公钥认证..."
        mkdir -p files/etc/dropbear
        echo "$root_passkey" > files/etc/dropbear/authorized_keys
        chmod 600 files/etc/dropbear/authorized_keys
        
        # 禁用密码认证，只允许公钥认证
        mkdir -p files/etc/config
        cat >> files/etc/config/dropbear << EOF

config dropbear
	option PasswordAuth 'off'
	option RootPasswordAuth 'off'
	option Port '22'
EOF
    fi
}

# 通用防火墙配置函数
configure_firewall() {
    cat > files/etc/config/firewall << 'EOF'
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
}