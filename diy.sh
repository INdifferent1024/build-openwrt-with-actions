#!/bin/bash
# ============================================
# CR8808 (Xiaomi CR880X M79) 专用编译脚本
# 2.4G 正常 + UA2F NFQUEUE + 不被识别为代理
# ============================================
set -e

echo "=== [1/4] 关键: 内核开启 NFQUEUE ==="
KCONF="target/linux/qualcommax/config-6.6"
if [ ! -f "$KCONF" ]; then
  echo "ERROR: 找不到 $KCONF"
  exit 1
fi
sed -i '/CONFIG_NETFILTER_NETLINK_QUEUE/d' "$KCONF" 2>/dev/null || true
sed -i '/CONFIG_NETFILTER_XT_TARGET_NFQUEUE/d' "$KCONF" 2>/dev/null || true
sed -i '/CONFIG_NF_CONNTRACK_NETLINK/d' "$KCONF" 2>/dev/null || true
sed -i '/CONFIG_NETFILTER_NETLINK_GLUE_CT/d' "$KCONF" 2>/dev/null || true
sed -i '/CONFIG_NFT_QUEUE/d' "$KCONF" 2>/dev/null || true
cat >> "$KCONF" << 'KEOF'

# === UA2F NFQUEUE 支持 (CR8808 定制, 勿删) ===
CONFIG_NETFILTER_NETLINK_QUEUE=y
CONFIG_NETFILTER_XT_TARGET_NFQUEUE=y
CONFIG_NF_CONNTRACK_NETLINK=y
CONFIG_NETFILTER_NETLINK_GLUE_CT=y
CONFIG_NFT_QUEUE=y
KEOF
echo "已注入 NFQUEUE:"
grep -A6 "UA2F NFQUEUE 支持" "$KCONF"

echo "=== [2/4] 应用 argon 主题 ==="
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
echo "主题已应用"

echo "=== [3/4] 说明: ua2f 使用官方 feeds ==="
echo "ImmortalWrt 官方 packages feed 已包含 ua2f，无需手动 clone"
echo "luci-app-ua2f 也已包含在 luci feed 中"

echo "=== [4/4] diy.sh 完成 ==="
