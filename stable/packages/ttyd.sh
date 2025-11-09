#!/bin/bash

# TTYD 配置脚本

echo "配置 ttyd..."

# 创建 ttyd 配置文件
cat > "${ROOT_DIR}/files/etc/config/ttyd" << 'EOF'

config ttyd
	option interface '/var/run/ttyd.sock'
	option command '/bin/login'
	option debug '1'
	option url_override '/luci/ttyd/'
	option unix_sock '1'

EOF

# 创建 nginx 配置文件
cat > "${ROOT_DIR}/files/etc/nginx/conf.d/ttyd.locations" << 'EOF'

location /luci/ttyd {
    allow all; 
    
    rewrite ^/luci/ttyd/?(.*)$ /$1 break; 
    
    proxy_pass http://unix:/var/run/ttyd.sock;
    
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_read_timeout 3600s;
}

EOF

echo "ttyd 配置完成"
echo "- 已启用 url_override 和 /luci/ttyd/ 访问"
echo "- 已启用 Unix Socket"
echo "- 已启用 Nginx 配置"