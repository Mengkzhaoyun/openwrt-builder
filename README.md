# OpenWrt-Builder

## R5S-linux/arm64

```bash
rm -rf $PWD/.tmp && \
mkdir -p $PWD/.tmp/bin $PWD/.tmp/files && \
docker run --rm -it \
  -v $PWD/.tmp/bin/:/builder/bin/ \
  -v $PWD/.tmp/files/:/builder/files/ \
  -v $PWD/stable/:/builder/src/ \
  --env-file .env \
  -e PROFILE="rockchip-armv8/friendlyarm_nanopi-r5s" \
  registry.cn-qingdao.aliyuncs.com/wod/openwrt-imagebuilder:rockchip-armv8-v25.12.4 \
  bash -c /builder/src/build.sh
```

```powershell
Remove-Item -Recurse -Force "$PWD/.tmp" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$PWD/.tmp/bin", "$PWD/.tmp/files" | Out-Null
docker run --rm -it `
  -v "$PWD/.tmp/bin/:/builder/bin/" `
  -v "$PWD/.tmp/files/:/builder/files/" `
  -v "$PWD/stable/:/builder/src/" `
  --env-file .env `
  -e "PROFILE=rockchip-armv8/friendlyarm_nanopi-r5s" `
  registry.cn-qingdao.aliyuncs.com/wod/openwrt-imagebuilder:rockchip-armv8-v25.12.4 `
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
  --env-file .env \
  -e PROFILE="x86_64/generic" \
  registry.cn-qingdao.aliyuncs.com/wod/openwrt-imagebuilder:x86-64-v25.12.4 \
  bash -c /builder/src/build.sh
```

```powershell
Remove-Item -Recurse -Force "$PWD/.tmp" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path "$PWD/.tmp/bin", "$PWD/.tmp/files" | Out-Null
docker run --rm -it `
  -v "$PWD/.tmp/bin/:/builder/bin/" `
  -v "$PWD/.tmp/files/:/builder/files/" `
  -v "$PWD/stable/:/builder/src/" `
  --env-file .env `
  -e "PROFILE=x86_64/generic" `
  registry.cn-qingdao.aliyuncs.com/wod/openwrt-imagebuilder:x86-64-v25.12.4 `
  bash -c /builder/src/build.sh
```

### 虚拟机使用方法

**转换为 VHDX 格式（Hyper-V 使用）：**

```bash
# 设置目录变量
OPENWRT_DIR="$PWD/.tmp/bin/targets/x86/64" && \
OPENWRT_VERSION=25.12.4 && \
rm -rf ${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img && \
rm -rf ${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.vhdx && \
{ gunzip -c "${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img.gz" > "${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img" 2>/dev/null || true; } && \
qemu-img convert -f raw -O vhdx "${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.img" "${OPENWRT_DIR}/openwrt-${OPENWRT_VERSION}-x86-64-generic-ext4-combined.vhdx"
```

```powershell
# 设置目录变量
$OPENWRT_DIR = "$PWD/.tmp/bin/targets/x86/64"
$OPENWRT_VERSION = "25.12.4"
Remove-Item -Force "$OPENWRT_DIR/openwrt-$OPENWRT_VERSION-x86-64-generic-ext4-combined.img" -ErrorAction SilentlyContinue
Remove-Item -Force "$OPENWRT_DIR/openwrt-$OPENWRT_VERSION-x86-64-generic-ext4-combined.vhdx" -ErrorAction SilentlyContinue
& 7z e "$OPENWRT_DIR/openwrt-$OPENWRT_VERSION-x86-64-generic-ext4-combined.img.gz" -o"$OPENWRT_DIR" -y
qemu-img convert -f raw -O vhdx `
  "$OPENWRT_DIR/openwrt-$OPENWRT_VERSION-x86-64-generic-ext4-combined.img" `
  "$OPENWRT_DIR/openwrt-$OPENWRT_VERSION-x86-64-generic-ext4-combined.vhdx"
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
- 密码：通过 `.env` 文件中的 `ROOT_PASSWORD` 设置

---

## 💾 镜像文件选择指南 (如何选择固件)

编译完成后，会在 `.tmp/bin/targets/` 目录下生成一系列的文件。对于初学者，这里提供一份清晰的避坑指南：

### 🖥️ x86_64 软路由 (物理机 / PVE / ESXi)

请重点关注名字中带有 **`combined`** 的 `.img.gz` 文件。你需要做两个选择：

#### 1. 选择引导方式 (Boot Mode)

- **`-efi.img.gz`**：**推荐！** 如果你的软路由较新，或使用 PVE/ESXi 等虚拟机，请选择支持 UEFI 引导的 EFI 版本。
- **无 `-efi` (仅 `-combined.img.gz`)**：如果你的软路由主板很老，只支持传统 BIOS (Legacy BIOS) 引导，请选择普通版本。

#### 2. 选择文件系统 (Filesystem)

- **`squashfs`**：**【强烈推荐】** 系统本身是只读压缩的，用户配置存在独立区域。**最大优势是支持“恢复出厂设置”**，且抗断电能力强，不易损坏系统。绝大部分用户的首选。
- **`ext4`**：整个系统分区可读写。优势是可以极度方便地扩容根目录空间，适合把软路由当 Linux 服务器“重度折腾”的玩家。**缺点是系统损坏无法通过“恢复出厂设置”救砖**。

> **🏆 x86 极客尊享首选：**  
> 解压 `openwrt-25.12.4-x86-64-generic-ext4-combined-efi.img.gz`，通过写盘工具 (如 Rufus / balenaEtcher / StarWind) 烧录即可。ext4 的自由度能让你随心所欲扩容折腾！

---

### 🍓 ARM64 软路由 (如 NanoPi R5S/R4S, 树莓派等)

ARM 架构的机器没有 EFI/Legacy 的区别，固件通常会直接带有具体的**设备型号**名称，如 `friendlyarm_nanopi-r5s`。

- 请寻找带有 **`sysupgrade.img.gz`** 后缀的文件。
- 它既可以用来使用写盘工具烧录到 TF 卡/eMMC 作为全新安装，也可以在现有的 OpenWRT 后台 Web 界面中直接上传作为升级包。
- **文件系统**依然遵循上述规则，普通用户**强烈建议选用 `squashfs`** 版本。
