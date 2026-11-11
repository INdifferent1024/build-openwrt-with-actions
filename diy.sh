#!/bin/bash
# ============================================
# CR8808 (Xiaomi CR880X M79) 专用编译脚本
# 2.4G 正常 + UA2F NFQUEUE 模式 + 不被识别为代理
# ============================================
set -e

echo "=== [1/6] 克隆 UA2F ==="
git clone --depth 1 https://github.com/Zxilly/UA2F.git package/UA2F
echo "UA2F 版本:"
grep PKG_VERSION package/UA2F/openwrt/Makefile | head -1

echo "=== [2/6] 修复 UA2F Makefile 递归依赖 bug ==="
# 上游 Package/ua2f/config 段里写了 depends on PACKAGE_ua2f
# 包装器本身就是 config PACKAGE_ua2f, 导致 kconfig 报 recursive dependency
python3 - << 'PYEOF'
import re, pathlib
p = pathlib.Path('package/UA2F/openwrt/Makefile')
s = p.read_text()
# 删除整个 Package/ua2f/config ... endef 块
new = re.sub(r'define Package/ua2f/config\b.*?\nendef\n', '', s, flags=re.S)
if new == s:
    print('WARN: config block not found, no change')
else:
    p.write_text(new)
    print('OK: removed Package/ua2f/config block')
PYEOF
echo "--- 验证已删除 ---"
if grep -q "Package/ua2f/config" package/UA2F/openwrt/Makefile; then
  echo "ERROR: 仍存在 config 块"
  exit 1
else
  echo "OK: config 块已删除"
fi

echo "=== [3/6] 关键: 内核开启 NFQUEUE ==="
KCONF="target/linux/qualcommax/config-6.6"
if [ ! -f "$KCONF" ]; then
  echo "ERROR: 找不到 $KCONF"
  exit 1
fi
# 清理旧设置
sed -i '/CONFIG_NETFILTER_NETLINK_QUEUE/d' "$KCONF" 2>/dev/null || true
sed -i '/CONFIG_NETFILTER_XT_TARGET_NFQUEUE/d' "$KCONF" 2>/dev/null || true
sed -i '/CONFIG_NF_CONNTRACK_NETLINK/d' "$KCONF" 2>/dev/null || true
sed -i '/CONFIG_NETFILTER_NETLINK_GLUE_CT/d' "$KCONF" 2>/dev/null || true
sed -i '/CONFIG_NFT_QUEUE/d' "$KCONF" 2>/dev/null || true
# 追加启用
cat >> "$KCONF" << 'KEOF'

# === UA2F NFQUEUE 支持 (CR8808 定制, 勿删) ===
CONFIG_NETFILTER_NETLINK_QUEUE=y
CONFIG_NETFILTER_XT_TARGET_NFQUEUE=y
CONFIG_NF_CONNTRACK_NETLINK=y
CONFIG_NETFILTER_NETLINK_GLUE_CT=y
CONFIG_NFT_QUEUE=y
KEOF
echo "已注入:"
grep -A6 "UA2F NFQUEUE 支持" "$KCONF"

echo "=== [4/6] 应用主题 ==="
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

echo "=== [5/6] 校验 UA2F Makefile 位置 ==="
if [ ! -f package/UA2F/openwrt/Makefile ]; then
  echo "ERROR: Makefile 位置不对"
  exit 1
fi
echo "OK: package/UA2F/openwrt/Makefile"

echo "=== [6/6] diy.sh 完成 ==="
