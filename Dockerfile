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
    && apt install locales \
    && locale-gen en_US.UTF-8 \
    && /var/lib/tsuru/base/install \
    && rm -rf /var/lib/apt/lists/*

USER ubuntu
