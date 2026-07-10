FROM ubuntu:noble

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# Free the host-matching UID/GID before common-utils creates hsl:1000:1000.
RUN if id "ubuntu" &>/dev/null; then \
        userdel -f -r ubuntu; \
    fi

# Use Tsinghua mirror (local proxy interferes with default ubuntu sources)
RUN sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources \
    && sed -i 's|http://security.ubuntu.com/ubuntu/|http://mirrors.tuna.tsinghua.edu.cn/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources

RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        vim \
        curl \
        ca-certificates \
        git \
        sudo \
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

ENV SHELL=/bin/bash \
    DOCKER_BUILDKIT=1

CMD [ "sleep", "infinity" ]
