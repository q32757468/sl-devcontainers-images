FROM ubuntu:noble

# Remove default ubuntu user
RUN if id "ubuntu" &>/dev/null; then \
        echo "Deleting user 'ubuntu'" && userdel -f -r ubuntu; \
    fi

ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

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

# Create non-root user hsl
RUN groupadd --gid 1000 hsl \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash hsl \
    && echo "hsl ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/hsl \
    && chmod 0440 /etc/sudoers.d/hsl

ENV SHELL=/bin/bash \
    DOCKER_BUILDKIT=1

CMD [ "sleep", "infinity" ]
