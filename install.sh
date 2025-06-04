#!/bin/bash

echo -e ''
echo -e "\033[32m========Sing-Box for pfSense一键安装脚本=========\033[0m"
echo -e ''

# 定义颜色变量
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

# 定义目录变量
ROOT="/usr/local"
BIN_DIR="$ROOT/bin"
WWW_DIR="$ROOT/www"
CONF_DIR="$ROOT/etc"
MENU_DIR="$ROOT/share/pfSense/menu/"
RC_DIR="$ROOT/etc/rc.d"
RC_CONF="/etc/rc.conf.d/"

# 定义日志函数
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 创建目录
log "$YELLOW" "创建目录..."
mkdir -p "$CONF_DIR/sing-box" || log "$RED" "目录创建失败！"

# 复制文件
log "$YELLOW" "复制文件..."
log "$YELLOW" "生成菜单..."
log "$YELLOW" "添加权限..."
chmod +x ./bin/* ./rc.d/* 
cp -f bin/* "$BIN_DIR/" || log "$RED" "bin 文件复制失败！"
cp -f www/* "$WWW_DIR/" || log "$RED" "www 文件复制失败！"
cp -f menu/* "$MENU_DIR/" || log "$RED" "menu 文件复制失败！"
cp -f rc.d/* "$RC_DIR/" || log "$RED" "rc.d 文件复制失败！"
cp -f rc.conf/* "$RC_CONF/" || log "$RED" "rc.conf 文件复制失败！"
cp -f conf/* "$CONF_DIR/sing-box/" || log "$RED" "sing-box 配置文件复制失败！"

# 安装shellcmd
log "$YELLOW" "安装shellcmd..."
if ! pkg info -q pfSense-pkg-Shellcmd > /dev/null 2>&1; then
  pkg install -y pfSense-pkg-Shellcmd > /dev/null 2>&1
fi

# 启动Tun接口
log "$YELLOW" "启动sing-box..."
service sing-box start > /dev/null 2>&1
echo ""

# 完成提示
sleep 1
log "$GREEN" "sing-box安装完毕，请刷新浏览器，导航到VPN > Sing-Box修改配置。"
log "$GREEN" "实现透明代理，还需要添加tun接口和网关，添加中国ip别名，添加防火墙分流规则，"
log "$GREEN" "修改DNS设置，添加开机启动项。所有配置修改完成后，建议重启防火墙，让配置生效。"
echo ""