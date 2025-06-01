#!/bin/bash

echo -e ''
echo -e "\033[32m========Sing-box for pfSense 代理全家桶一键卸载脚本=========\033[0m"
echo -e ''

# 定义颜色变量
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# 定义日志函数
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}


# 删除服务项
CONFIG_FILE="/cf/conf/config.xml"
BACKUP_FILE="/cf/conf/config.xml.bak.$(date +%F-%H%M%S)"

[ -f "$CONFIG_FILE" ] || {
    log "$RED" "配置文件不存在：$CONFIG_FILE"
    exit 1
}

log "$YELLOW" "备份配置文件..."
cp "$CONFIG_FILE" "$BACKUP_FILE" || {
    log "$RED" "备份失败"
    exit 1
}

for SERVICE in sing-box; do
  # 生成临时文件
  TMP_FILE=$(mktemp)

  awk -v service="$SERVICE" '
    BEGIN { keep = 1 }
    /<service>/ { block = ""; in_block = 1 }
    in_block {
      block = block $0 "\n"
      if (/<\/service>/) {
        in_block = 0
        if (block ~ "<name>" service "</name>") {
          next
        } else {
          printf "%s", block
        }
      }
      next
    }
    { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
done
echo ""

# 停止程序
log "$YELLOW" "停止sing-box..."
service singbox stop > /dev/null 2>&1
echo ""

# 删除程序和配置
log "$YELLOW" "删除程序和配置，请稍等..."

# 删除配置
rm -rf /usr/local/etc/sing-box

# 删除rc.d
rm -f /usr/local/etc/rc.d/singbox

# 删除rc.conf
rm -f /etc/rc.conf.d/singbox

# 删除菜单
rm -f /usr/local/share/pfSense/menu/pfSense_VPN_sing_box.xml

# 删除php
rm -f /usr/local/www/services_sing-box.php
rm -f /usr/local/www/status_sing-box_logs.php
rm -f /usr/local/www/status_sing-box.php

# 删除程序
rm -f /usr/local/bin/sing-box
rm -f /etc/rc.sing-box
echo ""

log "$YELLOW" "删除完成，配置已保存为：$BACKUP_FILE"
echo ""

# 重启所有服务
log "$YELLOW" "重新应用所有更改，请稍等..."
/etc/rc.reload_all >/dev/null 2>&1
echo ""

# 完成提示
log "$GREEN" "卸载完成，请手动删除TUN接口和网关、别名和浮动防火墙分流规则，删除shellcmd中的启动项。"
echo ""