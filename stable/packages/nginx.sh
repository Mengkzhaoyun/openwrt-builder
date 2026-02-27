#!/bin/bash

# Nginx 配置脚本

echo "配置 Nginx..."

# 创建 nginx 配置文件
cat > "${ROOT_DIR}/files/etc/config/nginx" << 'EOF'
config main 'global'
	option uci_enable 'true'

config server '_lan'
	list listen '443 ssl default_server'
	list listen '[::]:443 ssl default_server'
	option server_name '_lan'
	list include 'restrict_locally'
	list include 'conf.d/*.locations'
	option uci_manage_ssl 'self-signed'
	option ssl_certificate '/etc/nginx/conf.d/_lan.crt'
	option ssl_certificate_key '/etc/nginx/conf.d/_lan.key'
	option ssl_session_cache 'shared:SSL:32k'
	option ssl_session_timeout '64m'
	option access_log 'off; # logd openwrt'

config server '_lan_http'
	list listen '80 default_server'
	list listen '[::]:80 default_server'
	option server_name '_lan_http'
	list include 'restrict_locally'
	list include 'conf.d/*.locations'
	option access_log 'off; # logd openwrt'
EOF

# 创建启动脚本确保nginx和uhttpd不冲突，并等待网络就绪
mkdir -p "${ROOT_DIR}/files/etc/init.d"
cat > "${ROOT_DIR}/files/etc/init.d/ensure-nginx" << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

boot() {
    # 在启动时延迟执行，确保网络已就绪
    ( sleep 5 && start ) &
}

start() {
    # 确保uhttpd已停止
    /etc/init.d/uhttpd stop 2>/dev/null
    /etc/init.d/uhttpd disable 2>/dev/null
    
    # 确保nginx已启用
    /etc/init.d/nginx enable 2>/dev/null
    
    # 停止nginx（如果正在运行）
    /etc/init.d/nginx stop 2>/dev/null
    
    # 等待一秒
    sleep 1
    
    # 启动nginx
    /etc/init.d/nginx start 2>/dev/null
    
    # 记录到日志
    logger -t ensure-nginx "Nginx service started"
}

stop() {
    return 0
}

restart() {
    start
}
EOF
chmod +x "${ROOT_DIR}/files/etc/init.d/ensure-nginx"

# 创建 rc.d 符号链接以确保自动启动
mkdir -p "${ROOT_DIR}/files/etc/rc.d"
ln -sf ../init.d/ensure-nginx "${ROOT_DIR}/files/etc/rc.d/S99ensure-nginx" 2>/dev/null || true

echo "Nginx 配置完成"
echo "- 已启用 HTTP (端口 80) 和 HTTPS (端口 443) 访问"
echo "- 已配置自签名 SSL 证书"
echo "- 已禁用访问日志以节省存储空间"
echo "- 已创建启动脚本确保nginx正常运行"
echo "- 已创建自动启动链接"