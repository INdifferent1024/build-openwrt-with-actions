#!/bin/bash
# ============================================
# CR8808 (Xiaomi CR880X M79) 专用编译脚本
# 目标: 2.4G 正常 + UA2F NFQUEUE 模式 + 不被识别为代理
# ============================================
set -e

echo "=== [1/5] 添加 UA2F 软件包 ==="
git clone --depth 1 https://github.com/Zxilly/UA2F.git package/UA2F
echo "UA2F 版本:"
grep PKG_VERSION package/UA2F/openwrt/Makefile | head -1

echo "=== [2/5] 关键: 内核开启 NFQUEUE ==="
# 必须在这里改, 因为 .config 里的 CONFIG_PACKAGE_kmod-* 只保证包被编译
# 内核本身的 KCONFIG 需要显式打开
KCONF="target/linux/qualcommax/config-6.6"
if [ -f "$KCONF" ]; then
  # 删除可能存在的旧设置
  sed -i '/CONFIG_NETFILTER_NETLINK_QUEUE/d' "$KCONF"
  sed -i '/CONFIG_NETFILTER_XT_TARGET_NFQUEUE/d' "$KCONF"
  sed -i '/CONFIG_NF_CONNTRACK_NETLINK/d' "$KCONF"
  sed -i '/CONFIG_NETFILTER_NETLINK_GLUE_CT/d' "$KCONF"
  sed -i '/CONFIG_NFT_QUEUE/d' "$KCONF"
  # 追加启用
  cat >> "$KCONF" << 'KEOF'

# === UA2F NFQUEUE 支持 (CR8808 定制, 勿删) ===
CONFIG_NETFILTER_NETLINK_QUEUE=y
CONFIG_NETFILTER_XT_TARGET_NFQUEUE=y
CONFIG_NF_CONNTRACK_NETLINK=y
CONFIG_NETFILTER_NETLINK_GLUE_CT=y
CONFIG_NFT_QUEUE=y
KEOF
  echo "已注入 NFQUEUE 内核配置:"
  grep -A6 "UA2F NFQUEUE 支持" "$KCONF"
else
  echo "错误: 找不到 $KCONF"
  exit 1
fi

echo "=== [3/5] 应用主题 ==="
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

echo "=== [4/5] 验证 UA2F Makefile 层级 ==="
if [ ! -f package/UA2F/openwrt/Makefile ]; then
  echo "错误: UA2F Makefile 位置不正确"
  exit 1
fi
echo "OK: package/UA2F/openwrt/Makefile 存在"

echo "=== [5/5] 完成 ==="
echo "diy.sh 执行成功"
