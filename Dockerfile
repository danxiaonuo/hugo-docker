#############################
#     设置公共的变量         #
#############################
FROM alpine:latest AS base
# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/hugo
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=alpine
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=latest
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
ARG VCS_REF
ENV VCS_REF=$VCS_REF

# ##############################################################################

# ***** 设置变量 *****

# HUGO站点路径
ARG HUGO_PATH=/blog
ENV HUGO_PATH=$HUGO_PATH
# HUGO输出静态文件路径
ARG HUGO_DESTINATION=/src
ENV HUGO_DESTINATION=$HUGO_DESTINATION
# HUGO监听端口
ARG HUGO_PORT=80
ENV HUGO_PORT=$HUGO_PORT

ARG HUGO_BUILD_DEPS="\
      tzdata \
      ca-certificates \
	  asciidoctor \
	  libc6-compat \
      libstdc++ \
      pcre \
	  nodejs \
	  nodejs-npm \
	  git \
	  curl \
	  wget \
	  gcc \
	  g++ \
	  make \
	  libffi-dev \
	  openssl-dev \
	  libxml2-dev \
	  libxml2-utils \
	  libxslt \
	  musl-dev \
	  libxslt-dev \
	  jq \
      bash"
ENV HUGO_BUILD_DEPS=$HUGO_BUILD_DEPS

ARG PY_DEPS="\
      python3 \
	  python3-dev"
ENV PY_DEPS=$PY_DEPS


ARG FONT_DEPS="\
      font-adobe-100dpi \
	  ttf-dejavu \
	  fontconfig"
ENV FONT_DEPS=$FONT_DEPS

ARG PWA_DEPS="\
      workbox-build \
	  gulp \
	  gulp-uglify \
	  readable-stream \
	  uglify-es"
ENV PWA_DEPS=$PWA_DEPS

# dumb-init
# https://github.com/Yelp/dumb-init
ARG DUMBINIT_VERSION=1.2.2
ENV DUMBINIT_VERSION=$DUMBINIT_VERSION

# ##############################################################################

####################################
#          构建运行环境             #
####################################
FROM base AS builder

# http://label-schema.org/rc1/
LABEL maintainer="danxiaonuo <danxiaonuo@danxiaonuo.me>" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="$DOCKER_IMAGE" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.url="https://github.com/$DOCKER_IMAGE" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/$DOCKER_IMAGE" \
      versions.dumb-init=${DUMBINIT_VERSION}

# 修改源地址
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# ***** 安装相关依赖并更新系统软件 *****
# ***** 安装依赖 *****
RUN set -eux \
   # 更新源地址
   && apk update \
   # 更新系统并更新系统软件
   && apk upgrade && apk upgrade \
   && apk add -U --update $HUGO_BUILD_DEPS $PY_DEPS $FONT_DEPS \
   # 更新时区
   && ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
   # 更新时间
   && echo ${TZ} > /etc/timezone
      

# ***** 安装HUGO *****
RUN set -eux \
#   && export HUGO_DOWN=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases |jq -r .[].assets[].browser_download_url| grep -i 'extended'| grep -i 'Linux-64bit.tar.gz'|head -n 1) \
    && export HUGO_DOWN="https://github.com/gohugoio/hugo/releases/download/v0.71.1/hugo_extended_0.71.1_Linux-64bit.tar.gz" \
    && wget --no-check-certificate -O - $HUGO_DOWN | tar -xz -C /tmp \
	&& mv /tmp/hugo /usr/bin/hugo \
	&& chmod +x /usr/bin/hugo \
	&& rm -rf /tmp/*
	
	
# ***** 升级 setuptools 版本 *****
RUN set -eux \
    && python3 -m ensurepip \
    && rm -r /usr/lib/python*/ensurepip \
    && pip3 install --upgrade pip setuptools wheel pycryptodome lxml cython beautifulsoup4 \
    && if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi \
    && if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi \
    && rm -r /root/.cache
  

# ***** 安装字体库 *****
RUN set -eux \
    && mkdir /usr/share/fonts/win \
    && COPY ./font/. /usr/share/fonts/win/ \
    && RUN chmod -R 777 /usr/share/fonts/win && fc-cache -f

# ***** 安装 PWA *****
RUN set -eux \
    && npm install $PWA_DEPS --save-dev && npm update
	

# ***** 安装 Hugo-Encryptor *****
RUN set -eux \
    && wget -O /usr/bin/hugo-encryptor.py https://cdn.jsdelivr.net/gh/Li4n0/hugo_encryptor/hugo-encryptor.py \
    && chmod +x /usr/bin/hugo-encryptor.py
	
# ***** 安装dumb-init *****
RUN set -eux \
    && wget --no-check-certificate https://github.com/Yelp/dumb-init/releases/download/v${DUMBINIT_VERSION}/dumb-init_${DUMBINIT_VERSION}_x86_64 -O /usr/bin/dumb-init \
    && chmod +x /usr/bin/dumb-init

# ***** 设置HOGO环境变量 *****
ENV PATH /usr/bin/dumb-init:$PATH
ENV PATH /usr/bin/hugo:$PATH
ENV PATH /usr/bin/hugo-encryptor.py:$PATH


# ***** 挂载目录 *****
VOLUME ${HUGO_PATH}
VOLUME ${HUGO_DESTINATION}

# ***** 工作目录 *****
WORKDIR ${HUGO_PATH}

# ***** 增加文件 *****
ADD entrypoint.sh /entrypoint.sh

# ***** 增加文件权限 *****
RUN chmod +x /entrypoint.sh /usr/local/sbin/hugo

# ***** 命令执行入口 *****
ENTRYPOINT ["/entrypoint.sh"]

# ***** 暴露端口 *****
EXPOSE ${HUGO_PORT}
