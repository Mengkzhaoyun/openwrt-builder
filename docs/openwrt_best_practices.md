# OpenWrt 软路由配置初始化最佳实践

本文档总结了基于本地旁路由与远程软路由的折腾经验，提炼出的 OpenWrt 系统初始化与网络配置的最佳实践，旨在为后续新设备的初始化提供标准化的参考指南。

## 1. 基础系统与可靠性配置

软路由作为网络核心，其稳定性和故障排查能力至关重要。新系统刷入后，应优先完成以下配置。

### 1.1 系统日志持久化

OpenWrt 默认将日志存储在内存（环形缓冲区）中，一旦发生死机或异常重启，系统日志将丢失，导致无法追溯故障根因。**必须开启日志持久化。**

```sh
# 创建日志目录（选择一个非易失性分区，如 /root）
mkdir -p /root/log

# 配置系统日志落盘及大小限制（10MB 轮转）
uci set system.@system[0].log_file='/root/log/syslog'
uci set system.@system[0].log_size='10240'
uci commit system

# 重启日志服务生效
/etc/init.d/log restart
```

_验证方法：重启路由器后，检查 `cat /root/log/syslog` 是否保留了重启前的日志记录。_

### 1.2 定时健康重启

为了释放长时间运行可能造成的内存碎片或僵尸连接，建议通过原生的 crontab 配置每日凌晨的无感知重启，避免依赖第三方定时插件。

```sh
# 写入原生 crontab 配置：每天凌晨 4 点重启，重启前更新 banner 时间戳用于验证
echo "00 4 * * * sleep 5 && touch /etc/banner && reboot" >> /etc/crontabs/root
/etc/init.d/cron restart
```

_注意：请确保系统时区已正确配置（如 `Asia/Hong Kong` / `UTC+8`）。_

### 1.3 防火墙转发配置 (旁路由必备)

如果软路由作为旁路网关（客户端网关指向它），需要确保其防火墙的 `lan` 区域开启了 `masquerade`（IP 动态伪装），否则客户端流量转发给主路由时可能会因为源 IP 问题导致无法上网。

```sh
uci set firewall.@zone[0].masq='1'
uci set firewall.@zone[0].mtu_fix='1'
uci commit firewall
/etc/init.d/firewall reload
```

## 2. 旁路由与局域网 DHCP 最佳实践

> [!WARNING]
> **暂缓执行**：此部分的配置对局域网整体网络结构影响较大。目前正在进一步评估，请暂时不要直接应用。

在 `主路由 + 旁路由` 架构下，DHCP 的配置直接影响局域网的稳定性和科学上网的灵活性。最常见的网络故障（如网段冲突、IP 分配失败）均源于 DHCP 竞争。

### 方案 A：旁路由统一 DHCP + 标签化按需分流（⭐⭐⭐⭐⭐ 强烈推荐）

此方案最为优雅，能够实现网络控制的中心化管理。正常设备默认直连主路由（无旁路由 CPU 损耗），特定设备才走旁路由代理。

1. **关闭主路由的 DHCP 服务**，避免竞争。
2. **在旁路由配置标签分流策略**：
   默认将网关和 DNS 指向下发的 `主路由 (192.168.1.1)`；通过 MAC 地址将特定客户端打上 `proxy` 标签，并将其网关和 DNS 指向 `旁路由自身 (192.168.1.254)`。

```sh
# 1. 设置 LAN 默认下发的网关与 DNS 为主路由
uci del_list dhcp.lan.dhcp_option='3,192.168.1.254'
uci del_list dhcp.lan.dhcp_option='6,192.168.1.254'
uci add_list dhcp.lan.dhcp_option='3,192.168.1.1'
uci add_list dhcp.lan.dhcp_option='6,192.168.1.1'

# 2. 创建 proxy 标签，网关和 DNS 指向旁路由自身
uci add_list dhcp.lan.dhcp_option='tag:proxy,3,192.168.1.254'
uci add_list dhcp.lan.dhcp_option='tag:proxy,6,192.168.1.254'
uci commit dhcp
```

3. **绑定静态分配并打标签**：在 `/etc/config/dhcp` 的静态主机（`config host`）中添加 `option tag 'proxy'`。

```text
config host
	option name 'PC_USER'
	option mac '58:C1:F8:8C:CA:9C'
	option ip '192.168.1.20'
	option tag 'proxy'
```

4. 执行 `/etc/init.d/dnsmasq restart` 生效。

### 方案 B：主路由 DHCP + 客户端手动静态 IP 配置（适合单设备折腾）

如果不想影响家人网络（旁路由死机不影响大局），可以让主路由继续负责 DHCP。

1. 在旁路由彻底禁用 DHCP (`网络 -> 接口 -> LAN -> DHCP 服务器 -> 忽略此接口`)。
2. 为需要走代理的设备（如手机、电脑），在其自身系统网络设置中，手动将 IP 改为静态，并将**默认网关**和**DNS 服务器**指向软路由的 IP（如 `192.168.1.254`）。

## 3. 日常维护提醒

1. **避免本地内存泄露**：对于某些长期后台运行占用内存的 Go 程序（如 frpc），建议监控其 VSZ/RSS。若发现有持续的泄漏问题或处于 crash loop，建议将其迁移至具备完善资源限制的容器环境（如 NAS Docker 中），不让其拖垮作为网络基础的软路由。
2. **关闭多余服务**：不需要的服务（如 IPv6 相关的 `odhcpd` 或不再使用的插件）应通过 `/etc/init.d/xxx stop && /etc/init.d/xxx disable` 进行彻底停用，以减少资源消耗和日志刷屏。
