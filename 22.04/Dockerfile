# Copyright 2022 tsuru authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

FROM ubuntu:22.04
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive
COPY . /var/lib/tsuru/base
RUN set -ex \
    && apt update \
    && apt install locales \
    && locale-gen en_US.UTF-8 \
    && /var/lib/tsuru/base/install \
    && rm -rf /var/lib/apt/lists/*
USER ubuntu
