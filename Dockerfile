# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2025.2@sha256:64984fc93512f770bfd7ccfe1409714eb704592acfb8df451fc2d63c2ce387db AS build
RUN --mount=type=bind,from=ironic,source=/,target=/src/ironic,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/ironic \
        python-dracclient \
        sushy
EOF

FROM ghcr.io/vexxhost/python-base:2025.2@sha256:3fe182c91bb30443e7f81d5f6f31e83d61746959d64987fc3a3cd4adcce0e06b
RUN \
    groupadd -g 42424 ironic && \
    useradd -u 42424 -g 42424 -M -d /var/lib/ironic -s /usr/sbin/nologin -c "Ironic User" ironic && \
    mkdir -p /etc/ironic /var/log/ironic /var/lib/ironic /var/cache/ironic && \
    chown -Rv ironic:ironic /etc/ironic /var/log/ironic /var/lib/ironic /var/cache/ironic
RUN <<EOF bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    ethtool genisoimage ipmitool iproute2 ipxe isolinux lshw qemu-block-extra qemu-utils syslinux-common tftpd-hpa
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
COPY --from=build --link /var/lib/openstack /var/lib/openstack
