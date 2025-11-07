# OpenWrt-Builder

## R5S-linux/arm64

```bash
mkdir -p $PWD/.tmp/bin $PWD/.tmp/files && \
docker run --rm -it \
  -v $PWD/.tmp/bin:/builder/bin \
  -v $PWD/.tmp/files:/builder/files \
  -v $PWD/stable/:/builder/src \
  -e ROOT_PASSWORD="$OPENWRT_ROOT_PASSWORD" \
  -e ROOT_PASSKEY="$OPENWRT_ROOT_PASSKEY" \
  -e PROFILE="rockchip-armv8/friendlyarm_nanopi-r5s" \
  openwrt/imagebuilder:rockchip-armv8-v24.10.4 /builder/src/build.sh
```
