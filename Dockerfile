# Copyright 2015 tsuru authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

FROM	ubuntu-debootstrap:14.04
RUN	locale-gen en_US.UTF-8
ENV	LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 DEBIAN_FRONTEND=noninteractive
RUN	mkdir -p /var/lib/tsuru/base
ADD	. /var/lib/tsuru/base
RUN	/var/lib/tsuru/base/install
