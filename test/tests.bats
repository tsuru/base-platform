#!/usr/bin/env bats

# Copyright 2022 tsuru authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

load '/opt/bats-support/load.bash'
load '/opt/bats-assert/load.bash'

@test 'ensure "ubuntu" user and group exist with UID and GID 1000 respectively' {
  run id ubuntu
  assert_success

  run id -u ubuntu
  assert_output '1000'

  run id -g ubuntu
  assert_output '1000'
}

@test 'ensure ubuntu user can run as root trough sudo command (without password)' {
  run id -nu
  assert_success
  assert_output 'ubuntu'

  run sudo id -nu
  assert_success
  assert_output 'root'
}

@test '~/.bash_logout should not exist' {
  # in order to avoid errors when running clear_console without a terminal
  [ ! -f /home/ubuntu/.bash_logout ]
}

@test 'reading requirements.apt w/ carriage return (CR+LF)' {
  echo -e 'openssl\r' >  ${BATS_TEST_TMPDIR}/requirements.apt
  echo -e 'vim\r'     >> ${BATS_TEST_TMPDIR}/requirements.apt
  echo -e 'bash\r'    >> ${BATS_TEST_TMPDIR}/requirements.apt

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  run cat_without_hash_comments ${BATS_TEST_TMPDIR}/requirements.apt
  echo -en 'openssl\nvim\nbash\n' | assert_output -
}

@test 'reading requirements.apt with comments, whitespaces and empty line' {
  cat > ${BATS_TEST_TMPDIR}/requirements.apt <<-EOF
# Installing openssl for X purpose
openssl
example # Installing exampe to mitigate Y

  # Required by component Z
  git
EOF

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  run cat_without_hash_comments ${BATS_TEST_TMPDIR}/requirements.apt
  echo -e 'openssl\nexample\ngit' | assert_output -
}

@test 'install system package from requirements.apt' {
  echo "neofetch" > ${BATS_TEST_TMPDIR}/requirements.apt

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  export CURRENT_DIR=${BATS_TEST_TMPDIR}

  run os_dependencies
  assert_success

  run neofetch --version
  assert_failure # neofetch --versions returns exit code 1 🤷
  assert_output --regexp '^Neofetch [^ ]+$'
}

@test 'adding extra APT repositories from repositories.apt' {
  export UBUNTU_RELEASE=$(source /etc/lsb-release && echo $DISTRIB_CODENAME)
  export CURRENT_DIR=${BATS_TEST_TMPDIR}

  cat > ${CURRENT_DIR}/repositories.apt <<-EOF
deb https://packagecloud.io/tsuru/rc/ubuntu/ ${UBUNTU_RELEASE} main
deb-src https://packagecloud.io/tsuru/rc/ubuntu/ ${UBUNTU_RELEASE} main
ppa:tsuru/ppa
pogo-dev/stable 0x2445455D0F8FB8F9299E7A0AF2244A5C0D4D9B55
EOF

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  run os_dependencies
  assert_success

  expected_source_file="deb https://packagecloud.io/tsuru/rc/ubuntu/ ${UBUNTU_RELEASE} main"
  expected_file="/etc/apt/sources.list.d/tsuru_$(echo ${expected_source_file} | sha1sum | awk '{print $1}').list"
  [ -r ${expected_file} ]
  run cat ${expected_file}
  assert_output "${expected_source_file}"

  expected_source_file="deb-src https://packagecloud.io/tsuru/rc/ubuntu/ ${UBUNTU_RELEASE} main"
  expected_file="/etc/apt/sources.list.d/tsuru_$(echo ${expected_source_file} | sha1sum | awk '{print $1}').list"
  [ -r ${expected_file} ]
  run cat ${expected_file}
  assert_output "${expected_source_file}"

  expected_source_file=$(cat <<-EOF
deb https://ppa.launchpadcontent.net/tsuru/ppa/ubuntu ${UBUNTU_RELEASE} main
deb-src https://ppa.launchpadcontent.net/tsuru/ppa/ubuntu ${UBUNTU_RELEASE} main
EOF
)
  expected_file="/etc/apt/sources.list.d/tsuru_$(echo ${expected_source_file} | sha1sum | awk '{print $1}').list"
  [ -r ${expected_file} ]
  run cat ${expected_file}
  assert_output "${expected_source_file}"
  run sudo apt-key finger 2>/dev/null
  assert_output --partial 'B0DE 9C5D EBF4 8635 9EB2  55B0 3B01 53D0 383F 073D'

  expected_source_file=$(cat <<-EOF
deb https://ppa.launchpadcontent.net/pogo-dev/stable/ubuntu ${UBUNTU_RELEASE} main
deb-src https://ppa.launchpadcontent.net/pogo-dev/stable/ubuntu ${UBUNTU_RELEASE} main
EOF
)
  expected_file="/etc/apt/sources.list.d/tsuru_$(echo ${expected_source_file} | sha1sum | awk '{print $1}').list"
  [ -r ${expected_file} ]
  run cat ${expected_file}
  assert_output "${expected_source_file}"
  run sudo apt-key finger 2>/dev/null
  assert_output --partial '2445 455D 0F8F B8F9 299E  7A0A F224 4A5C 0D4D 9B55'
}

# vim: ft=bash
