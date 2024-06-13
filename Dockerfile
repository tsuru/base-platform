# Copyright 2022 tsuru authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

ARG ubuntu_version=latest
FROM ubuntu:${ubuntu_version}

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

COPY base /var/lib/tsuru/base

RUN set -ex \
    && apt update \
    && apt install -y --no-install-recommends \
        locales curl sudo jq rsync netcat-openbsd net-tools telnet vim-tiny lsof openssl ca-certificates gnupg2 \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8 \
    && . /var/lib/tsuru/base/rc/config \
    && getent group ${USER} > /dev/null || addgroup --gid ${USER_GID} ${USER} \
    && getent passwd ${USER} > /dev/null || useradd -m --home-dir ${HOME} --gid ${USER_GID} --uid ${USER_UID} ${USER} \
    && rm -f ${HOME}/.bash_logout \
    && mkdir -p /home/application /var/lib/tsuru/default \
    && chown -R ${USER}:${USER} /home/application /var/lib/tsuru/default \
    && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo "export DEBIAN_FRONTEND=noninteractive" >> /etc/profile

USER ubuntu
