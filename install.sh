#!/bin/bash

echo -e ''
echo -e "\033[32m========Sing-Box for pfSense 代理全家桶一键安装脚本=========\033[0m"
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
MODELS_DIR="$ROOT/share/pfSense/menu/"
RC_DIR="$ROOT/etc/rc.d"
RC_CONF="/etc/rc.conf.d/"
CONFIG_FILE="/cf/conf/config.xml"
TMP_FILE="/tmp/config.xml.tmp"
BACKUP_FILE="/cf/conf/config.xml.bak.$(date +%F-%H%M%S)"

# 定义日志函数
log() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${RESET}"
}

# 创建目录
log "$YELLOW" "创建目录..."
sleep 1
mkdir -p "$CONF_DIR/sing-box" "$CONF_DIR/sing-box/ui" "$CONF_DIR/tun2socks" || log "$RED" "目录创建失败！"

# 复制文件
log "$YELLOW" "复制文件..."
log "$YELLOW" "生成菜单..."
log "$YELLOW" "添加权限..."
chmod +x bin/*
chmod +x rc.d/*
cp -f bin/* "$BIN_DIR/" || log "$RED" "bin 文件复制失败！"
cp -f www/* "$WWW_DIR/" || log "$RED" "www 文件复制失败！"
cp -f menu/* "$MODELS_DIR/" || log "$RED" "menu 文件复制失败！"
cp -R -f ui/* "$CONF_DIR/sing-box/ui/" || log "$RED" "ui 文件复制失败！"
cp rc.d/* "$RC_DIR/" || log "$RED" "rc.d 文件复制失败！"
cp conf/config_sing-box.json "$CONF_DIR/sing-box/config.json" || log "$RED" "sing-box 配置文件复制失败！"
cp conf/config_tun2socks.yaml "$CONF_DIR/tun2socks/config.yaml" || log "$RED" "tun2socks 配置文件复制失败！"

# 添加服务启动项
log "$YELLOW" "配置系统服务..."
cp -f rc.conf/* "$RC_CONF/" || log "$RED" "rc.conf 文件复制失败！"

# 备份现有配置
log "$YELLOW" "备份配置文件..."
cp "$CONFIG_FILE" "$BACKUP_FILE" || {
  log "$RED" "备份失败"
  exit 1
}

# 安装shellcmd
log "$YELLOW" "安装shellcmd..."
if ! pkg info -q pfSense-pkg-Shellcmd > /dev/null 2>&1; then
  pkg install -y pfSense-pkg-Shellcmd > /dev/null 2>&1
fi

# 启动Tun接口
log "$YELLOW" "启动Tun2Socks..."
service tun2socks start > /dev/null 2>&1
echo ""

# 添加Tun接口
sleep 1
log "$YELLOW" "添加tun接口..."
if grep -q "<if>tun_3000</if>" "$CONFIG_FILE"; then
  echo "TUN接口已存在，跳过"
else
  awk '
  /<interfaces>/ {
    print
    print "    <opt10>"
    print "      <descr><![CDATA[tun]]></descr>"
    print "      <if>tun_3000</if>"
    print "      <spoofmac></spoofmac>"
    print "      <enable></enable>"
    print "      <ipaddr>10.10.0.1</ipaddr>"
    print "      <subnet>24</subnet>"
    print "      <gateway>tun</gateway>"
    print "    </opt10>"
    next
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
  echo "TUN接口添加完成"
fi
echo " "

# 添加Tun网关
sleep 1
log "$YELLOW" "添加tun网关..."
if grep -q "<gateway>10.10.0.1</gateway>" "$CONFIG_FILE"; then
  echo "TUN网关已存在，跳过"
else
  awk '
  /<gateways>/ {
    print
    print "    <gateway_item>"
    print "      <interface>opt10</interface>"
    print "      <gateway>10.10.0.1</gateway>"
    print "      <name>tun</name>"
    print "      <weight>1</weight>"
    print "      <ipprotocol>inet</ipprotocol>"
    print "      <descr></descr>"
    print "      <gw_down_kill_states></gw_down_kill_states>"
    print "    </gateway_item>"
    next
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
  echo "TUN网关添加成功"
fi
echo " "

# 添加CN_IP别名
sleep 1
log "$YELLOW" "添加CN_IP别名..."
if grep -q "<url>https://ispip.clang.cn/all_cn.txt</url>" "$CONFIG_FILE"; then
  echo "同名别名已存在，跳过"
else
  awk '
  BEGIN { inserted=0 }

  # 情况1：空的 <aliases></aliases> 标签
  /<aliases>[[:space:]]*<\/aliases>/ && !inserted {
    print "  <aliases>"
    print "    <alias>"
    print "      <name>CN_IP</name>"
    print "      <type>urltable</type>"
    print "      <url>https://ispip.clang.cn/all_cn.txt</url>"
    print "      <updatefreq>7</updatefreq>"
    print "      <address>https://ispip.clang.cn/all_cn.txt</address>"
    print "      <descr><![CDATA[中国IP段，七天更新一次。]]></descr>"
    print "      <detail><![CDATA[中国IP段，七天更新一次。]]></detail>"
    print "    </alias>"
    print "  </aliases>"
    inserted=1
    next
  }

  # 情况2：非空 <aliases> 标签，插在标签后
  /<aliases>/ && !inserted {
    print
    print "    <alias>"
    print "      <name>CN_IP</name>"
    print "      <type>urltable</type>"
    print "      <url>https://ispip.clang.cn/all_cn.txt</url>"
    print "      <updatefreq>7</updatefreq>"
    print "      <address>https://ispip.clang.cn/all_cn.txt</address>"
    print "      <descr><![CDATA[中国IP段，七天更新一次。]]></descr>"
    print "      <detail><![CDATA[中国IP段，七天更新一次。]]></detail>"
    print "    </alias>"
    inserted=1
    next
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
  echo "别名添加成功"
fi
echo " "

# 更改 unbound 端口为 5355
  sleep 1
  log "$YELLOW" "更改Unbound端口..."

  PORT_OK=$(awk '
  BEGIN { in_unbound = 0 }
  /<unbound>/ { in_unbound = 1 }
  /<\/unbound>/ { in_unbound = 0 }
  in_unbound && /<port>5355<\/port>/ { print "yes"; exit }
  ' "$CONFIG_FILE")

if [ "$PORT_OK" = "yes" ]; then
  echo "端口已经为5355，跳过"
else
  # 修改或插入 <port> 标签
  awk '
  BEGIN { in_unbound = 0; port_found = 0 }
  /<unbound>/ {
    in_unbound = 1
    print
    next
  }
  /<\/unbound>/ {
    if (in_unbound && port_found == 0) {
      print "   <port>5355</port>"
    }
    in_unbound = 0
    print
    next
  }
  {
    if (in_unbound && /<port>.*<\/port>/) {
      sub(/<port>.*<\/port>/, "<port>5355</port>")
      port_found = 1
    }
    print
  }
  ' "$CONFIG_FILE" > "$TMP_FILE"

  if [ -s "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$CONFIG_FILE"
    echo "端口已修改为5355"
  else
    log "$RED" "修改失败，请检查配置文件"
  fi
fi
echo " "

# 添加防火墙规则
sleep 1
log "$YELLOW" "添加防火墙规则..."
if grep -q "<tracker>88888888</tracker>" "$CONFIG_FILE"; then
  echo "同名规则已存在，跳过"
else
  awk '
  BEGIN { inserted = 0 }
  /<filter>/ {
    print
    next
  }
  /<rule>/ && inserted == 0 {
    print "    <rule>"
    print "      <id></id>"
    print "      <tracker>88888888</tracker>"
    print "      <type>pass</type>"
    print "      <interface>lan</interface>"
    print "      <ipprotocol>inet</ipprotocol>"
    print "      <tag></tag>"
    print "      <tagged></tagged>"
    print "      <direction>in</direction>"
    print "      <quick>yes</quick>"
    print "      <floating>yes</floating>"
    print "      <max></max>"
    print "      <max-src-nodes></max-src-nodes>"
    print "      <max-src-conn></max-src-conn>"
    print "      <max-src-states></max-src-states>"
    print "      <statetimeout></statetimeout>"
    print "      <statepolicy></statepolicy>"
    print "      <statetype><![CDATA[keep state]]></statetype>"
    print "      <pflow></pflow>"
    print "      <os></os>"
    print "      <srcmac></srcmac>"
    print "      <dstmac></dstmac>"
    print "      <source>"
    print "        <network>lan</network>"
    print "      </source>"
    print "      <destination>"
    print "        <address>CN_IP</address>"
    print "        <not></not>"
    print "      </destination>"
    print "      <descr><![CDATA[访问国外走tun网关]]></descr>"
    print "      <gateway>tun</gateway>"
    print "      <bridgeto></bridgeto>"
    print "    </rule>"
    inserted = 1
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
  echo "防火墙规则添加成功"
fi
echo " "

# 添加开机启动项 
sleep 1
log "$YELLOW" "添加开机启动项..."
if grep -q "service tun2socks start" "$CONFIG_FILE"; then
  echo "开机启动项已设置，跳过"
else
  awk '
  /<shellcmdsettings>/ {
    print
    print "    <config>"
    print "      <cmd>service singbox start</cmd>"
    print "      <cmdtype>shellcmd</cmdtype>"
    print "      <description></description>"
    print "    </config>"
    print "    <config>"
    print "      <cmd>service tun2socks start</cmd>"
    print "      <cmdtype>shellcmd</cmdtype>"
    print "      <description></description>"
    print "    </config>"
    next
  }
  { print }
  ' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
  echo "开机启动项添加完成"
fi
if grep -q "<shellcmd>service tun2socks start</shellcmd>" "$CONFIG_FILE"; then
else
awk '
/<\/system>/ && !inserted {
   print "    <shellcmd>service singbox start</shellcmd>"
   print "    <shellcmd>service tun2socks start</shellcmd>"
   inserted = 1
}
{ print }
' "$CONFIG_FILE" > "$TMP_FILE" && mv "$TMP_FILE" "$CONFIG_FILE"
fi
echo " "

# 添加服务列表项 
sleep 1
log "$YELLOW" "添加服务列表项..."
# 定义要添加的内容
NEW_SERVICES="        <service>
            <name>tun2socks</name>
            <rcfile>tun2socks</rcfile>
            <executable>tun2socks</executable>
            <description><![CDATA[tun转socks]]></description>
        </service>
        <service>
            <name>sing-box</name>
            <rcfile>singbox</rcfile>
            <executable>sing-box</executable>
            <description><![CDATA[sing-box 代理服务]]></description>
        </service>
"
# 检查配置文件是否已包含相同内容
if grep -q "<name>tun2socks</name>" "$CONFIG_FILE" && grep -q "<name>sing-box</name>" "$CONFIG_FILE"; then
    echo "服务列表已设置，跳过"
else
    # 找到第一个<service>标签的位置
    FIRST_SERVICE_POS=$(grep -n "<service>" "$CONFIG_FILE" | head -n 1 | cut -d ":" -f 1)

    # 如果找到了<service>标签，插入新的服务配置
    if [ -n "$FIRST_SERVICE_POS" ]; then
        # 使用 head 和 tail 精确控制文件内容插入，避免空行
        {
            head -n "$((FIRST_SERVICE_POS-1))" "$CONFIG_FILE"
            printf "%s" "$NEW_SERVICES"  # 使用 printf 来避免额外的换行符
            tail -n +"$FIRST_SERVICE_POS" "$CONFIG_FILE"
        } > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        echo "服务列表添加完成"
    else
        echo "配置文件中没有<service>字段，无法插入新的服务配置。"
    fi
fi
echo " "

# 重启所有服务
sleep 1
log "$YELLOW" "正在应用所有更改，请稍等..."
/etc/rc.reload_all >/dev/null 2>&1
echo "所有服务已重新加载"
echo ""

# 完成提示
sleep 1
log "$GREEN" "Sing-Box 安装完成，请刷新浏览器，导航到VPN > Sing-Box 菜单进行操作。配置完成后建议重启防火墙，让新配置生效。"
echo ""
