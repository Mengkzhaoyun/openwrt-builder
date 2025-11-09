#!/bin/bash

# 系统配置模块（主机名、shell等）

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
    
    echo "主机名配置完成"
}

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
    
    echo "bash shell配置完成"
}