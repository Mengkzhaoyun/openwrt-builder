# OpenWrt-Builder

## R5S-linux/arm64

```bash
rm -rf $PWD/.tmp && \
mkdir -p $PWD/.tmp/bin $PWD/.tmp/files && \
docker run --rm -it \
  -v $PWD/.tmp/bin/:/builder/bin/ \
  -v $PWD/.tmp/files/:/builder/files/ \
  -v $PWD/stable/:/builder/src/ \
  -e ROOT_PASSWORD="$OPENWRT_ROOT_PASSWORD" \
  -e ROOT_PASSKEY="$OPENWRT_ROOT_PASSKEY" \
  -e PROFILE="rockchip-armv8/friendlyarm_nanopi-r5s" \
  registry.cn-qingdao.aliyuncs.com/wod/openwrt-imagebuilder:rockchip-armv8-v24.10.4 \
  bash -c /builder/src/build.sh
```

## x86_64 虚拟机版本（Hyper-V / QNAP 测试）

```bash
rm -rf $PWD/.tmp && \
mkdir -p $PWD/.tmp/bin $PWD/.tmp/files && \
docker run --rm -it \
  -v $PWD/.tmp/bin/:/builder/bin/ \
  -v $PWD/.tmp/files/:/builder/files/ \
  -v $PWD/stable/:/builder/src/ \
  -e ROOT_PASSWORD="$OPENWRT_ROOT_PASSWORD" \
  -e ROOT_PASSKEY="$OPENWRT_ROOT_PASSKEY" \
  -e PROFILE="x86_64/generic" \
  registry.cn-qingdao.aliyuncs.com/wod/openwrt-imagebuilder:x86-64-v24.10.4 \
  bash -c /builder/src/build.sh
```

### 虚拟机使用方法

**转换为 VHDX 格式（Hyper-V 使用）：**

```bash
# 设置目录变量
OPENWRT_DIR="$PWD/.tmp/bin/targets/x86/64" && \
OPENWRT_VERSION=24.10.4 && \
rm -rf ${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img && \
rm -rf ${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.vhdx && \
{ gunzip -c "${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img.gz" > "${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img" 2>/dev/null || true; } && \
qemu-img convert -f raw -O vhdx "${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img" "${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.vhdx"
```

### 虚拟机使用

**配置建议：**

- 内存：512MB - 1GB
- 存储：至少 1GB
- 网络：桥接模式
- CPU：1-2 核心

**使用方法：**

1. **Hyper-V**：使用生成的 `openwrt.vhdx` 文件创建虚拟机
2. **QNAP Virtualization Station**：导入 `openwrt.qcow2` 或 `openwrt.img` 文件
3. **VMware/VirtualBox**：使用 `openwrt.img` 文件（可能需要转换为对应格式）

**首次启动：**

- 默认 IP：<http://192.168.1.253>
- 用户名：root
- 密码：通过环境变量 `OPENWRT_ROOT_PASSWORD` 设置
