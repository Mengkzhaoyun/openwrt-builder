#!/bin/bash

# 认证配置模块（密码和SSH密钥）

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
        echo "SSH公钥认证配置完成"
    fi
}