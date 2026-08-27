FROM ubuntu:noble

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai

# Free the host-matching UID/GID before common-utils creates the configured user.
RUN if id "ubuntu" &>/dev/null; then \
        userdel -f -r ubuntu; \
    fi

# Bootstrap CA certificates from Tsinghua University over HTTP, then use
# Tsinghua University over HTTPS for all subsequent package operations.
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources \
    && sed -i 's|http://security.ubuntu.com/ubuntu/|http://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources \
    && sed -i 's/^Components:.*/Components: main/' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update \
    && apt-get -y install --no-install-recommends \
        ca-certificates \
    && sed -i 's/^Components:.*/Components: main universe restricted multiverse/' /etc/apt/sources.list.d/ubuntu.sources \
    && sed -i 's|http://mirrors.tuna.tsinghua.edu.cn/ubuntu/|https://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources \
    && apt-get update \
    && apt-get -y install --no-install-recommends \
        vim \
        curl \
        git \
        sudo \
        tzdata \
    && ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo ${TZ} > /etc/timezone \
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV SHELL=/bin/bash \
    DOCKER_BUILDKIT=1

CMD [ "sleep", "infinity" ]
