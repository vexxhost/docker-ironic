# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2025.1@sha256:be0383c6b6f5752c35132a022fad99148b556be222ed79c2fdc62ca5dc0f2e14 AS build
ARG IRONIC_VERSION=29.0.6+a8e.0.2
RUN <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "ironic==${IRONIC_VERSION}" \
        python-dracclient \
        sushy \
        sushy-oem-idrac
EOF

FROM ghcr.io/vexxhost/python-base:2025.1@sha256:7de32b3af7509a5427834bf36f72805cfc600ae87cd2e4fd3762dbd94fff0731
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
