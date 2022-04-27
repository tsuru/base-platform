# Copyright 2022 tsuru authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

ARG image

FROM ${image}

ARG bats_core_version=1.6.0 \
    bats_support_version=0.3.0 \
    bats_assert_version=master

RUN set -eux \
    && curl -fsSL https://github.com/bats-core/bats-core/archive/refs/tags/v${bats_core_version}.tar.gz \
      | tar -xzf- -C /tmp \
    && sudo /tmp/bats-core-${bats_core_version}/install.sh /opt/bats \
    && sudo ln -s /opt/bats/bin/bats /usr/local/bin \
    && bats --version \
    && rm -rf /tmp/bats-core-${bats_core_version} \
    && curl -fsSL https://github.com/bats-core/bats-support/archive/refs/tags/v${bats_support_version}.tar.gz \
      | tar -xzf- -C /tmp \
    && sudo mv /tmp/bats-support-${bats_support_version} /opt/bats-support \
    && curl -fsSL https://github.com/bats-core/bats-assert/archive/refs/heads/${bats_assert_version}.tar.gz \
      | tar -xzf- -C /tmp \
    && sudo mv /tmp/bats-assert-${bats_assert_version} /opt/bats-assert

WORKDIR /tests

# COPY . /tests

# RUN echo "echo 'ran base deploy'" | sudo tee /var/lib/tsuru/base/deploy
# RUN bin/bats common && bin/bats .

