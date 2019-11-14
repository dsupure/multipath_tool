#!/usr/bin/env bash

# Copyright 2018, Pure Storage Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function set_centos {
    if [ -f /usr/bin/yum ] && \
        cat /etc/*release | grep -q -e "CentOS" -e "CloudLinux"; then

        OS_FLAVOR="centos"
        OS_VERSION=$(cat /etc/system-release | grep release | awk '{print $4}' | awk -F '.' '{print $1"."$2}')
        return 0
    fi

    return 1
}

function set_rhel {
    if cat /etc/*release | grep -q -e "Red Hat Enterprise Linux"; then
        OS_FLAVOR="rhel"
        OS_VERSION=$(cat /etc/system-release | grep release | awk '{print $7}')
        return 0
    fi

    return 1
}

function set_ubuntu {
    if [ -f /usr/bin/apt-get ]; then
        OS_FLAVOR="ubuntu"
        OS_VERSION=$(lsb_release -r | awk '{print $2}')
        return 0
    fi

    return 1
}

function set_coreos {
    if cat /etc/*release | grep -q 'CoreOS'; then
        OS_FLAVOR="coreos"
        OS_VERSION=""
        return 0
    fi

    return 1
}

function set_osx {
    if uname | grep -q 'Darwin'; then
        OS_FLAVOR="osx"
        OS_VERSION=""
        return 0
    fi

    return 1
}

function set_os_version {
    if set_centos; then
        return 0
    elif set_rhel; then
        return 0
    elif set_ubuntu; then
        return 0
    elif set_coreos; then
        return 0
    elif set_osx; then
        return 0
    fi

    return 1
}

set_os_version