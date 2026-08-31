FROM ubuntu:noble

# POSIX TZ syntax: UTC-8 means a fixed UTC+8 offset (Asia/Shanghai).
ENV LANG=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    TZ=UTC-8

# Free the host-matching UID/GID before common-utils creates the configured user.
RUN if id "ubuntu" &>/dev/null; then \
        userdel -f -r ubuntu; \
    fi

# Preserve the canonical timezone name without requiring the tzdata package.
RUN printf '%s\n' 'Asia/Shanghai' > /etc/timezone

ENV SHELL=/bin/bash \
    DOCKER_BUILDKIT=1

CMD [ "sleep", "infinity" ]
