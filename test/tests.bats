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
  echo -e 'openssl\r' >${BATS_TEST_TMPDIR}/requirements.apt
  echo -e 'vim\r' >>${BATS_TEST_TMPDIR}/requirements.apt
  echo -e 'bash\r' >>${BATS_TEST_TMPDIR}/requirements.apt

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  run cat_without_hash_comments ${BATS_TEST_TMPDIR}/requirements.apt
  echo -en 'openssl\nvim\nbash\n' | assert_output -
}

@test 'reading requirements.apt with comments, whitespaces and empty line' {
  cat >${BATS_TEST_TMPDIR}/requirements.apt <<-EOF
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
  echo "neofetch" >"${BATS_TEST_TMPDIR}"/requirements.apt

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  export CURRENT_DIR=${BATS_TEST_TMPDIR}

  run os_dependencies
  assert_success

  run neofetch --version
  assert_failure # neofetch --versions returns exit code 1 🤷
  assert_output --regexp '^Neofetch [^ ]+$'
}

@test 'adding extra APT repositories from repositories.apt from deb' {
  export UBUNTU_RELEASE=$(source /etc/lsb-release && echo $DISTRIB_CODENAME)
  export CURRENT_DIR=${BATS_TEST_TMPDIR}

  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  cat >${CURRENT_DIR}/repositories.apt <<-EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_RELEASE} stable
EOF

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  run os_dependencies
  assert_success

  expected_source_file="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${UBUNTU_RELEASE} stable"
  expected_file="/etc/apt/sources.list.d/tsuru_$(echo ${expected_source_file} | sha1sum | awk '{print $1}').list"
  [ -r "${expected_file}" ]
  run cat "${expected_file}"
  assert_output "${expected_source_file}"

  run sudo apt-get update -y
  assert_success
  assert_output --partial "https://download.docker.com/linux/ubuntu ${UBUNTU_RELEASE}/stable $(dpkg --print-architecture) Packages"
}

@test 'adding extra APT repositories from repositories.apt from deb-src' {
  export UBUNTU_RELEASE=$(source /etc/lsb-release && echo $DISTRIB_CODENAME)
  export CURRENT_DIR=${BATS_TEST_TMPDIR}

  sudo curl -fsSLq https://packages.mozilla.org/apt/repo-signing-key.gpg -o /etc/apt/keyrings/packages.mozilla.org.asc
  sudo chmod a+r /etc/apt/keyrings/packages.mozilla.org.asc

  cat >${CURRENT_DIR}/repositories.apt <<-EOF
deb-src [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main
EOF

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  run os_dependencies
  assert_success

  expected_source_file="deb-src [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main"
  expected_file="/etc/apt/sources.list.d/tsuru_$(echo ${expected_source_file} | sha1sum | awk '{print $1}').list"
  [ -r "${expected_file}" ]
  run cat "${expected_file}"
  assert_output "${expected_source_file}"

  run sudo apt-get update -y
  assert_success
  assert_output --partial "https://packages.mozilla.org/apt mozilla InRelease"
}

@test 'adding extra APT repositories from repositories.apt from ppa' {
  export UBUNTU_RELEASE=$(source /etc/lsb-release && echo $DISTRIB_CODENAME)
  export CURRENT_DIR=${BATS_TEST_TMPDIR}

  cat >${CURRENT_DIR}/repositories.apt <<-EOF
ppa:pogo-dev/stable
EOF

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  run os_dependencies
  assert_success

  expected_source_file=$(
    cat <<-EOF
deb [signed-by=/usr/share/keyrings/pogo-dev.gpg] https://ppa.launchpadcontent.net/pogo-dev/stable/ubuntu ${UBUNTU_RELEASE} main
deb-src [signed-by=/usr/share/keyrings/pogo-dev.gpg] https://ppa.launchpadcontent.net/pogo-dev/stable/ubuntu ${UBUNTU_RELEASE} main
EOF
  )
  expected_file="/etc/apt/sources.list.d/tsuru_$(echo "${expected_source_file}" | sha1sum | awk '{print $1}').list"

  [ -r "${expected_file}" ]
  run cat "${expected_file}"
  assert_output "${expected_source_file}"

  sudo apt-get clean
  run sudo apt-get update -y
  assert_success
  assert_output --partial "https://ppa.launchpadcontent.net/pogo-dev/stable/ubuntu ${UBUNTU_RELEASE}/main Sources"
  assert_output --partial "https://ppa.launchpadcontent.net/pogo-dev/stable/ubuntu ${UBUNTU_RELEASE}/main $(dpkg --print-architecture) Packages"
}

@test 'adding extra APT repositories from repositories.apt from ppa with fingerprint' {
  export UBUNTU_RELEASE=$(source /etc/lsb-release && echo $DISTRIB_CODENAME)
  export CURRENT_DIR=${BATS_TEST_TMPDIR}

  cat >${CURRENT_DIR}/repositories.apt <<-EOF
pogo-dev/daily 0x32D78285D050BE9F1B0030D0F0AE9179321F84C8
EOF

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  run os_dependencies
  assert_success

  expected_source_file=$(
    cat <<-EOF
deb [signed-by=/usr/share/keyrings/pogo-dev.gpg] https://ppa.launchpadcontent.net/pogo-dev/daily/ubuntu ${UBUNTU_RELEASE} main
deb-src [signed-by=/usr/share/keyrings/pogo-dev.gpg] https://ppa.launchpadcontent.net/pogo-dev/daily/ubuntu ${UBUNTU_RELEASE} main
EOF
  )
  expected_file="/etc/apt/sources.list.d/tsuru_$(echo "${expected_source_file}" | sha1sum | awk '{print $1}').list"
  [ -r "${expected_file}" ]
  run cat "${expected_file}"
  assert_output "${expected_source_file}"

  run sudo apt-get update -y
  assert_success
  assert_output --partial "https://ppa.launchpadcontent.net/pogo-dev/daily/ubuntu ${UBUNTU_RELEASE}/main Sources"
  assert_output --partial "https://ppa.launchpadcontent.net/pogo-dev/daily/ubuntu ${UBUNTU_RELEASE}/main $(dpkg --print-architecture) Packages"

  run gpg --no-default-keyring --keyring /usr/share/keyrings/pogo-dev.gpg --fingerprint
  assert_success
  assert_output --partial "32D7 8285 D050 BE9F 1B00  30D0 F0AE 9179 321F 84C8"
}

# vim: ft=bash
