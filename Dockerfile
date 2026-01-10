# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2023.2@sha256:7ef15eed3dd199f53c736838616b2df169f4509d3fc6440bd9c29f20be6f6e05 AS build
RUN --mount=type=bind,from=ironic,source=/,target=/src/ironic,readwrite <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        /src/ironic \
        python-dracclient \
        sushy
EOF

FROM ghcr.io/vexxhost/python-base:2023.2@sha256:220d65e3184ef5a50978abac042c8b4e9cb15829dfd8d32249da2c544a101df1
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
