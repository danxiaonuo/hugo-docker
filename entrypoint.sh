#!/bin/bash

# 创建HUGO
HUGO_NEWSITE="${HUGO_NEWSITE:=false}"
# 监听文件状态
HUGO_WATCH="${HUGO_WATCH:=false}"
# 发布HUGO
HUGO_PUB="${HUGO_PUB:=true}"
# HUGO主题模板
HUGO_THEME="${HUGO_THEME:=FixIt}"
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

if [[ $HUGO_NEWSITE != 'false' ]]; then
	echo "创建HUGO"
	sudo rm -rf $HUGO_PATH
	sudo mkdir -p $HUGO_PATH
	sudo hugo new site $HUGO_PATH
	cd $HUGO_PATH
	git init
	git submodule add --depth 1 https://github.com/hugo-fixit/FixIt.git themes/FixIt
	# git submodule update --init --recursive
        # git submodule update --rebase --remote
	git submodule update --remote --merge themes/FixIt
        cat /dev/null > hugo.toml
        echo 'title = "hugo"' >> hugo.toml
        echo 'theme = "FixIt"' >> hugo.toml
        echo 'defaultContentLanguage = "zh-cn"' >> hugo.toml
        echo 'languageCode = "zh-CN"' >> hugo.toml
        echo 'languageName = "简体中文"' >> hugo.toml
        echo 'lhasCJKLanguage = true' >> hugo.toml
	hugo new content posts/my-first-post.md
        hugo server --bind 0.0.0.0 -p 80 -D --disableFastRender
	echo "创建HUGO结束"
	tail -f /dev/null
fi
if [[ $HUGO_PUB != 'false' ]]; then
	echo "发布HUGO"
        cd $HUGO_PATH
	sudo rm -rf public
	hugo
	echo "发布HUGO完成"
	tail -f /dev/null
fi
if [[ $HUGO_WATCH != 'false' ]]; then
	echo "监视HUGO"
        cd $HUGO_PATH
	hugo server -e production -w -t="$HUGO_THEME" -s="$HUGO_PATH" -d="$HUGO_DESTINATION" -b="$HUGO_BASEURL" --bind="$HUGO_BIND" -p="$HUGO_PORT" --disableFastRender "$@" || exit 1
fi
