# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2025.1@sha256:23b162d7b21343837dd8894aa29eeec97ce45bf1a0d43ccb3ab5c26f12185b6c AS build
RUN --mount=type=bind,from=ironic,source=/,target=/src/ironic,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/ironic \
        python-dracclient \
        sushy
EOF

FROM ghcr.io/vexxhost/python-base:2025.1@sha256:19173c6f26d983d07e19126e5d7ca38c9f6b9c28e3b0a86bb98db57abd288310
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
