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
  cat > ${BATS_TEST_TMPDIR}/repositories.apt <<-EOF
deb https://packagecloud.io/tsuru/rc/ubuntu/ jammy main
deb-src https://packagecloud.io/tsuru/rc/ubuntu/ jammy main
ppa:tsuru/ppa
pogo-dev/stable 0x2445455D0F8FB8F9299E7A0AF2244A5C0D4D9B55
EOF

  [ -r /var/lib/tsuru/base/rc/os_dependencies ]
  source /var/lib/tsuru/base/rc/os_dependencies

  export CURRENT_DIR=${BATS_TEST_TMPDIR}
  export UBUNTU_RELEASE=$(source /etc/lsb-release && echo $DISTRIB_CODENAME)

  run os_dependencies
  assert_success

  expected_file="/etc/apt/sources.list.d/tsuru_96c980b0d58bf0127d270b571d9223d57dac260e.list"
  [ -r ${expected_file} ]
  run cat ${expected_file}
  assert_output 'deb https://packagecloud.io/tsuru/rc/ubuntu/ jammy main'

  expected_file='/etc/apt/sources.list.d/tsuru_f0f3b70e50fa0bbe4329f1af6d855573c5f22bd3.list'
  [ -r ${expected_file} ]
  run cat ${expected_file}
  assert_output 'deb-src https://packagecloud.io/tsuru/rc/ubuntu/ jammy main'

  expected_file='/etc/apt/sources.list.d/tsuru_435caf3a8bc86b0ae984aab774786109394ac445.list'
  [ -r ${expected_file} ]
  run cat ${expected_file}
  assert_output - <<-EOF
deb https://ppa.launchpadcontent.net/tsuru/ppa/ubuntu jammy main
deb-src https://ppa.launchpadcontent.net/tsuru/ppa/ubuntu jammy main
EOF

  run sudo apt-key finger 2>/dev/null
  assert_output --partial 'B0DE 9C5D EBF4 8635 9EB2  55B0 3B01 53D0 383F 073D'

  expected_file='/etc/apt/sources.list.d/tsuru_940069a563e061f3dfd8704ff3b76577c031b76f.list'
  [ -r ${expected_file} ]
  run cat ${expected_file}
  assert_output - <<-EOF
deb https://ppa.launchpadcontent.net/pogo-dev/stable/ubuntu jammy main
deb-src https://ppa.launchpadcontent.net/pogo-dev/stable/ubuntu jammy main
EOF

  run sudo apt-key finger 2>/dev/null
  assert_output --partial '2445 455D 0F8F B8F9 299E  7A0A F224 4A5C 0D4D 9B55'
}

@test 'ensure tsuru_unit_agent is installed in the system path' {
  run tsuru_unit_agent --version
  assert_success
  assert_output --partial 'deploy-agent version'
}

# vim : ft=bash
