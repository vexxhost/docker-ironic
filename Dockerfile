# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2024.2@sha256:3f9cf3d9be46d1df842b2c11fae817793fb9a438a4d76713e9f91d03c2f8ea1b AS build
ARG IRONIC_VERSION=26.1.6+a8e.0.4
RUN <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "ironic==${IRONIC_VERSION}" \
        python-dracclient \
        sushy \
        sushy-oem-idrac
EOF

FROM ghcr.io/vexxhost/python-base:2024.2@sha256:31b81988a0e492e0c595b5641019c1d58654ed5fdedc9fa191977a71c06a86fb
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
