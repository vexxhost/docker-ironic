# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2024.2@sha256:f19a38183fbcce9824dbd4585fbbae8a08865cbbd5e56d820d0a8053b7be6ee9 AS build
ARG IRONIC_VERSION=26.1.6+a8e.0.4
# vexxhost/requirements pins upstream sushy, which packages.vexxhost.com does
# not serve. Install the VEXXHOST builds of sushy that this release ships.
RUN <<EOF bash -xe
grep -vE '^sushy(-oem-idrac)?===' /upper-constraints.txt > /tmp/upper-constraints.txt
uv pip install \
    --constraint /tmp/upper-constraints.txt \
        "ironic==${IRONIC_VERSION}" \
        python-dracclient \
        sushy==5.2.2+a8e.0.4 \
        sushy-oem-idrac==6.0.0
EOF

FROM ghcr.io/vexxhost/python-base:2024.2@sha256:103897daed441a3504c7222b7cb07cc23ba06f463f003b370d99e0acb18adefa
RUN \
    groupadd -g 42424 ironic && \
    useradd -u 42424 -g 42424 -M -d /var/lib/ironic -s /usr/sbin/nologin -c "Ironic User" ironic && \
    mkdir -p /etc/ironic /var/log/ironic /var/lib/ironic /var/cache/ironic && \
    chown -Rv ironic:ironic /etc/ironic /var/log/ironic /var/lib/ironic /var/cache/ironic
RUN <<EOF bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    ethtool ipmitool iproute2 ipxe lshw qemu-block-extra qemu-utils tftpd-hpa
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=build --link /var/lib/openstack /var/lib/openstack
