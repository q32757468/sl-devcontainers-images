FROM ubuntu:noble

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Shanghai

# Free the host-matching UID/GID before common-utils creates the configured user.
RUN if id "ubuntu" &>/dev/null; then \
        userdel -f -r ubuntu; \
    fi

# Install base packages before local Features configure the APT mirror.
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
        ca-certificates \
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
