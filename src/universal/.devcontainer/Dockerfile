FROM ubuntu:noble

ARG USERNAME=hsl
ARG USER_UID=1000
ARG USER_GID=1000

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

# Create non-root user
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# Configure npm mirror registry
RUN echo 'registry=https://registry.npmmirror.com/' > /home/${USERNAME}/.npmrc \
    && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.npmrc

ENV SHELL=/bin/bash \
    DOCKER_BUILDKIT=1

CMD [ "sleep", "infinity" ]
