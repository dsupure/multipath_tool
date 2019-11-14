#!/usr/bin/env bash

# Copyright 2017, Pure Storage Inc.
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

SCRIPT_DIR=$(dirname $0)
source ${SCRIPT_DIR}/../bash-utils/os_version.sh

set -xe

cat <<EOF >>/tmp/multipath.conf
defaults {
         polling_interval       5
}

blacklist {
    devnode "vda"
}

devices {
        device {
               vendor                   "PURE"
               path_selector            "queue-length 0"
               path_grouping_policy     multibus
               path_checker             tur
               fast_io_fail_tmo         10
               dev_loss_tmo             60
               user_friendly_names      no
               no_path_retry            0
               features                 0
               }
}
EOF

sudo mkdir -p /etc/multipath/
sudo cp /tmp/multipath.conf /etc/multipath.conf

cat <<EOF >>/tmp/99-pure-storage.rules
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/max_sectors_kb}="4096"

# Use noop scheduler for high-performance solid-state storage
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/scheduler}="noop"

# Reduce CPU overhead due to entropy collection
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/add_random}="0"

# Spread CPU load by redirecting completions to originating CPU
ACTION=="add|change", KERNEL=="sd*[!0-9]", SUBSYSTEM=="block", ENV{ID_VENDOR}=="PURE", ATTR{queue/rq_affinity}="2"

EOF

if [ "${OS_FLAVOR}" = "ubuntu" ]; then

    cat <<EOF >>/tmp/99-pure-storage.rules
# Set the HBA timeout to 60 seconds
ACTION=="add", SUBSYSTEMS=="scsi", ATTRS{model}=="FlashArray      ", ATTR{timeout}=“60”
EOF

else

    cat <<EOF >>/tmp/99-pure-storage.rules
# Set the HBA timeout to 60 seconds
ACTION=="add", SUBSYSTEMS=="scsi", ATTRS{model}=="FlashArray      ", RUN+="/bin/sh -c 'echo 60 > /sys/\$DEVPATH/device/timeout'"
EOF

fi

sudo cp /tmp/99-pure-storage.rules /lib/udev/rules.d/99-pure-storage.rules

sudo systemctl enable iscsid multipathd
sudo systemctl daemon-reload
sudo systemctl restart iscsid multipathd
