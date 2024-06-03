#############################
#     设置公共的变量         #
#############################
FROM --platform=$BUILDPLATFORM ubuntu:jammy AS base
# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=zh_CN.UTF-8
ENV LANG=$LANG

# 镜像变量
ARG DOCKER_IMAGE=danxiaonuo/nginx
ENV DOCKER_IMAGE=$DOCKER_IMAGE
ARG DOCKER_IMAGE_OS=ubuntu
ENV DOCKER_IMAGE_OS=$DOCKER_IMAGE_OS
ARG DOCKER_IMAGE_TAG=jammy
ENV DOCKER_IMAGE_TAG=$DOCKER_IMAGE_TAG
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

# 安装依赖包
ARG PKG_DEPS="\
    zsh \
    bash \
    bash-doc \
    bash-completion \
    dnsutils \
    iproute2 \
    net-tools \
    sysstat \
    ncat \
    git \
    vim \
    jq \
    lrzsz \
    tzdata \
    curl \
    wget \
    axel \
    lsof \
    zip \
    unzip \
    tar \
    rsync \
    iputils-ping \
    telnet \
    procps \
    libaio1 \
    numactl \
    xz-utils \
    gnupg2 \
    psmisc \
    libmecab2 \
    debsums \
    locales \
    iptables \
    nodejs \
    npm \
    python2 \
    python3 \
    python3-dev \
    python3-pip \
    language-pack-zh-hans \
    fonts-droid-fallback \
    fonts-wqy-zenhei \
    fonts-wqy-microhei \
    fonts-arphic-ukai \
    fonts-arphic-uming \
    ca-certificates"
ENV PKG_DEPS=$PKG_DEPS

ARG PWA_DEPS="\
    workbox-build \
    gulp \
    gulp-uglify \
    readable-stream \
    uglify-es"
ENV PWA_DEPS=$PWA_DEPS

# ##############################################################################

##########################################
#         构建最新的镜像                  #
##########################################
FROM base
# 作者描述信息
MAINTAINER danxiaonuo
# 时区设置
ARG TZ=Asia/Shanghai
ENV TZ=$TZ
# 语言设置
ARG LANG=zh_CN.UTF-8
ENV LANG=$LANG

# ***** 安装依赖 *****
RUN set -eux && \
   # 更新源地址
   sed -i s@http://*.*ubuntu.com@https://mirrors.aliyun.com@g /etc/apt/sources.list && \
   sed -i 's?# deb-src?deb-src?g' /etc/apt/sources.list && \
   # 解决证书认证失败问题
   touch /etc/apt/apt.conf.d/99verify-peer.conf && echo >>/etc/apt/apt.conf.d/99verify-peer.conf "Acquire { https::Verify-Peer false }" && \
   # 更新系统软件
   DEBIAN_FRONTEND=noninteractive apt-get update -qqy && apt-get upgrade -qqy && \
   # 安装依赖包
   DEBIAN_FRONTEND=noninteractive apt-get install -qqy --no-install-recommends $PKG_DEPS --option=Dpkg::Options::=--force-confdef && \
   DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends autoremove --purge && \
   DEBIAN_FRONTEND=noninteractive apt-get -qqy --no-install-recommends autoclean && \
   rm -rf /var/lib/apt/lists/* && \
   # 更新时区
   ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime && \
   # 更新时间
   echo ${TZ} > /etc/timezone && \
   # 更改为zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true && \
   sed -i -e "s/bin\/ash/bin\/zsh/" /etc/passwd && \
   sed -i -e 's/mouse=/mouse-=/g' /usr/share/vim/vim*/defaults.vim && \
   locale-gen zh_CN.UTF-8 && localedef -f UTF-8 -i zh_CN zh_CN.UTF-8 && locale-gen && \
   /bin/zsh


# ***** 安装HUGO *****
RUN set -eux && \
    export HUGO_DOWN=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases |jq -r .[].assets[].browser_download_url| grep -i 'extended'| grep -i 'Linux-64bit.tar.gz'|head -n 1) && \
    wget --no-check-certificate -O - $HUGO_DOWN | tar -xz -C /tmp && \
    mv /tmp/hugo /usr/bin/hugo && \
    chmod +x /usr/bin/hugo && \
    rm -rf /tmp/*
		
# ***** 升级 setuptools 版本 *****
RUN set -eux && \
    wget --no-check-certificate https://bootstrap.pypa.io/pip/2.7/get-pip.py -O /tmp/get-pip.py && \
    python2 /tmp/get-pip.py && \
    pip3 config set global.index-url http://mirrors.aliyun.com/pypi/simple/ && \
    pip3 config set install.trusted-host mirrors.aliyun.com && \
    pip3 install --upgrade pip setuptools wheel pycryptodome lxml cython beautifulsoup4 requests && \
    rm -r /root/.cache && rm -rf /tmp/*
  

# ***** 工作目录 *****
WORKDIR ${HUGO_PATH}

# ***** 安装 PWA *****
RUN set -eux && \
    npm install $PWA_DEPS --save-dev && npm update
	
# ***** 安装 Hugo-Encryptor *****
RUN set -eux && \
    wget -O /usr/bin/hugo-encryptor.py https://cdn.jsdelivr.net/gh/Li4n0/hugo_encryptor/hugo-encryptor.py && \
    chmod +x /usr/bin/hugo-encryptor.py
	
# ***** 设置HOGO环境变量 *****
ENV PATH /usr/bin/hugo:$PATH
ENV PATH /usr/bin/hugo-encryptor.py:$PATH

# ***** 挂载目录 *****
VOLUME ${HUGO_PATH}
VOLUME ${HUGO_DESTINATION}

# ***** 增加文件 *****
ADD entrypoint.sh /entrypoint.sh

# ***** 增加文件权限 *****
RUN chmod +x /entrypoint.sh /usr/bin/hugo

# ***** 命令执行入口 *****
ENTRYPOINT ["/entrypoint.sh"]

# ***** 暴露端口 *****
EXPOSE ${HUGO_PORT}
