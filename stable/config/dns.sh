#!/bin/bash

# DNS配置模块

configure_dns() {
    local dns_servers=${1:-"192.168.1.1"}
    
    echo "配置DNS服务器: $dns_servers"
    
    # 创建resolv.conf
    cat > "${ROOT_DIR}/files/etc/resolv.conf" << EOF
# 自定义DNS配置
EOF
    for dns in $dns_servers; do
        echo "nameserver $dns" >> "${ROOT_DIR}/files/etc/resolv.conf"
    done
    
    # 配置dhcp和dns
    cat > "${ROOT_DIR}/files/etc/config/dhcp" << EOF
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
        cat >> "${ROOT_DIR}/files/etc/config/dhcp" << EOF

config dnsmasq
	list server '$dns'
EOF
    done
    
    cat >> "${ROOT_DIR}/files/etc/config/dhcp" << EOF

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
    
    echo "DNS配置完成"
}