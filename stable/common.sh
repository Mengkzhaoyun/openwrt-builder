#!/bin/bash

# OpenWrt 公共配置函数
# 包含网络、DNS、密码、SSH等通用配置

# 通用网络配置函数 - 所有网口组成 br-lan
configure_network() {
    local custom_ip=${1:-"192.168.1.253"}
    local gateway=${2:-"192.168.1.1"}
    local dns_servers=${3:-"192.168.1.1"}
    
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
}

# Root 密码配置函数
configure_root_password() {
    local root_password="$1"
    
    echo "配置root密码 - 密码长度: ${#root_password}"
    
    if [ -n "$root_password" ]; then
        echo "设置root密码..."
        # 生成密码哈希
        PASSWORD_HASH=$(openssl passwd -1 "$root_password")
        echo "密码哈希生成成功: ${PASSWORD_HASH:0:20}..."
        
        cat > "${ROOT_DIR}/files/etc/shadow" << EOF
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
        chmod 600 "${ROOT_DIR}/files/etc/shadow"
        echo "root密码配置完成"
    else
        echo "警告: ROOT_PASSWORD 为空，跳过密码设置"
    fi
}

# SSH 公钥认证配置函数
configure_ssh_key() {
    local root_passkey="$1"
    
    if [ -n "$root_passkey" ]; then
        echo "设置SSH公钥认证..."
        mkdir -p "${ROOT_DIR}/files/etc/dropbear"
        echo "$root_passkey" > "${ROOT_DIR}/files/etc/dropbear/authorized_keys"
        chmod 600 "${ROOT_DIR}/files/etc/dropbear/authorized_keys"
        
        # 禁用密码认证，只允许公钥认证
        mkdir -p "${ROOT_DIR}/files/etc/config"
        cat >> "${ROOT_DIR}/files/etc/config/dropbear" << EOF

config dropbear
	option PasswordAuth 'off'
	option RootPasswordAuth 'off'
	option Port '22'
EOF
    fi
}

# 通用防火墙配置函数
configure_firewall() {
    # 使用环境变量或默认路径
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
}

# 配置默认主机名
configure_hostname() {
    local hostname=${1:-"openwrt"}
    echo "配置默认主机名为: $hostname"
    mkdir -p "${ROOT_DIR}/files/etc/config"
    
    # 设置系统主机名
    cat > "${ROOT_DIR}/files/etc/config/system" << EOF
config system
	option hostname '$hostname'
	option timezone 'UTC'
	option ttylogin '0'
	option log_size '64'
	option urandom_seed '0'

config timeserver 'ntp'
	option enabled '1'
	option enable_server '0'
	list server 'ntp.aliyun.com'
	list server 'time1.cloud.tencent.com'
	list server 'time.ustc.edu.cn'
	list server 'cn.pool.ntp.org'
EOF
}

# 配置bash为默认shell
configure_bash_shell() {
    echo "配置bash为默认shell..."
    
    # 创建profile配置，设置bash为默认shell
    mkdir -p "${ROOT_DIR}/files/etc"
    cat > "${ROOT_DIR}/files/etc/profile" << 'EOF'
#!/bin/sh
# /etc/profile: system-wide .profile file for the Bourne shell (sh(1))
# and Bourne compatible shells (bash(1), ksh(1), ash(1), ...).

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PS1='\u@\h:\w\$ '

# 如果bash可用，切换到bash
if [ -x /bin/bash ] && [ "$0" != "/bin/bash" ]; then
    export SHELL=/bin/bash
    exec /bin/bash --login
fi

# 加载profile.d中的脚本
if [ -d /etc/profile.d ]; then
    for i in /etc/profile.d/*.sh; do
        if [ -r $i ]; then
            . $i
        fi
    done
    unset i
fi
EOF

    # 设置root用户默认使用bash
    mkdir -p "${ROOT_DIR}/files/etc"
    
    # 创建一个脚本在系统启动时修改root用户的shell
    mkdir -p "${ROOT_DIR}/files/etc/init.d"
    cat > "${ROOT_DIR}/files/etc/init.d/set-bash-shell" << 'EOF'
#!/bin/sh /etc/rc.common

START=99

start() {
    # 修改root用户的默认shell为bash
    if [ -x /bin/bash ]; then
        sed -i 's|^root:.*:/bin/ash$|root:x:0:0:root:/root:/bin/bash|' /etc/passwd
    fi
}

stop() {
    return 0
}
EOF
    chmod +x "${ROOT_DIR}/files/etc/init.d/set-bash-shell"
}

# 签名验证配置 - 已移除
# 由于 ImageBuilder 不支持重编译 opkg，相关配置已移除

