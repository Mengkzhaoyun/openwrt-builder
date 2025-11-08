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

echo "Nginx 配置完成"
echo "- 已启用 HTTP (端口 80) 和 HTTPS (端口 443) 访问"
echo "- 已配置自签名 SSL 证书"
echo "- 已禁用访问日志以节省存储空间"