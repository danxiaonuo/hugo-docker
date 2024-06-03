#!/bin/bash

# 创建HUGO
HUGO_NEWSITE="${HUGO_NEWSITE:=false}"
# 监听文件状态
HUGO_WATCH="${HUGO_WATCH:=false}"
# 发布HUGO
HUGO_PUB="${HUGO_PUB:=true}"
# HUGO主题模板
HUGO_THEME="${HUGO_THEME:=FeelIt}"
# HUGO站点路径
HUGO_PATH="${HUGO_PATH:=/blog}"
# HUGO输出静态文件路径
HUGO_DESTINATION="${HUGO_DESTINATION:=/src}"
# HUGO访问站点地址
HUGO_BASEURL="${HUGO_BASEURL:=http://www.danxiaonuo.me}"
# HUGO监听地址
HUGO_BIND="${HUGO_BIND:=::}"
# HUGO监听端口
HUGO_PORT="${HUGO_PORT:=80}"
echo "HUGO监听文件状态:" $HUGO_WATCH
echo "HUGO主题模板:" $HUGO_THEME
echo "HUGO站点路径:" $HUGO_PATH
echo "HUGO站点输出静态文件路径:" $HUGO_DESTINATION
echo "HUGO访问站点地址:" $HUGO_BASEURL
echo "HUGO监听地址:" $HUGO_BIND
echo "HUGO监听端口:" $HUGO_PORT
echo "其他参数:" $@

# HUGO二进制文件路径
HUGO=/usr/bin/hugo
echo "HUGO二进制文件路径: $HUGO"
# hugo-encryptor脚本路径
hugo_encryptor=/usr/bin/hugo-encryptor.py
echo "hugo-encryptor脚本路径: $hugo_encryptor"

if [[ $HUGO_NEWSITE != 'false' ]]; then
	echo "创建HUGO"
	rm -rf $HUGO_PATH
	mkdir -p $HUGO_PATH
	hugo new site $HUGO_PATH
	cd $HUGO_PATH
	git init
	git submodule add --depth 1 https://github.com/hugo-fixit/FixIt.git themes/FixIt
	git submodule update --init --recursive
        git submodule update --rebase --remote
	mkdir -p $HUGO_PATH/layouts/shortcodes/
	wget -O $HUGO_PATH/layouts/shortcodes/hugo-encryptor.html https://raw.githubusercontent.com/Li4n0/hugo_encryptor/master/shortcodes/hugo-encryptor.html
	echo "创建HUGO结束"
	tail -f /dev/null
fi
if [[ $HUGO_PUB != 'false' ]]; then
	echo "发布HUGO"
	rm -rf public
	hugo
	python3 $hugo_encryptor
	echo "发布HUGO完成"
	tail -f /dev/null
fi
if [[ $HUGO_WATCH != 'false' ]]; then
	echo "监视HUGO"
	hugo server -e production -w -t="$HUGO_THEME" -s="$HUGO_PATH" -d="$HUGO_DESTINATION" -b="$HUGO_BASEURL" --bind="$HUGO_BIND" -p="$HUGO_PORT" "$@" || exit 1
fi
