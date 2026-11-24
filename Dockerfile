# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2024.1@sha256:88a0c42e933c2fd01fb9b17ea8210f439b19f4f4cf9d91adae44544f3b876236 AS build
ARG IRONIC_VERSION=24.1.5+a8e.35.2
# vexxhost/requirements pins upstream sushy, which packages.vexxhost.com does
# not serve. Install the VEXXHOST build of sushy that this release ships.
RUN <<EOF bash -xe
grep -vE '^sushy===' /upper-constraints.txt > /tmp/upper-constraints.txt
uv pip install \
    --constraint /tmp/upper-constraints.txt \
        "ironic==${IRONIC_VERSION}" \
        python-dracclient \
        sushy==5.0.1+a8e.1.0
EOF

FROM ghcr.io/vexxhost/python-base:2024.1@sha256:17ad9f704d099eaca892ed0cc7cbc8a97484abf271123451e1a2c55d99f368dd
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
