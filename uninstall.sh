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

# 停止程序
log "$YELLOW" "停止sing-box..."
service sing-box stop > /dev/null 2>&1
echo ""

# 删除程序和配置
log "$YELLOW" "删除程序和配置，请稍等..."

# 删除配置
rm -rf /usr/local/etc/sing-box

# 删除rc.d
rm -f /usr/local/etc/rc.d/sing-box

# 删除rc.conf
rm -f /etc/rc.conf.d/sing_box

# 删除菜单
rm -f /usr/local/share/pfSense/menu/pfSense_VPN_sing_box.xml

# 删除php
rm -f /usr/local/www/services_sing-box.php
rm -f /usr/local/www/status_sing-box_logs.php
rm -f /usr/local/www/status_sing-box.php
rm -f /usr/local/www/services_sub.php
rm -f /usr/bin/sub

# 删除程序
rm -f /usr/local/bin/sing-box
echo ""

# 完成提示
log "$GREEN" "卸载完成，请手动删除TUN接口和网关、别名和浮动防火墙分流规则，删除shellcmd中的启动项。"
echo ""