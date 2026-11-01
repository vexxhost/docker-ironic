# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2026.1@sha256:c4d76980a010d5a0775d8fce0176458d44b4f5be701f66112d1d51d8934d9304 AS build
ARG IRONIC_VERSION=35.1.0+a8e.28.1
RUN <<EOF bash -xe
uv pip install \
    --constraint /upper-constraints.txt \
        "ironic==${IRONIC_VERSION}" \
        python-dracclient \
        sushy
EOF

FROM ghcr.io/vexxhost/python-base:2026.1@sha256:0dcb29bb84860ce039a035fe9112d8f519374270797bcb2a2f43bcf86061c226
RUN \
    groupadd -g 42424 ironic && \
    useradd -u 42424 -g 42424 -M -d /var/lib/ironic -s /usr/sbin/nologin -c "Ironic User" ironic && \
    mkdir -p /etc/ironic /var/log/ironic /var/lib/ironic /var/cache/ironic && \
    chown -Rv ironic:ironic /etc/ironic /var/log/ironic /var/lib/ironic /var/cache/ironic
ADD https://github.com/novnc/noVNC.git#v1.6.0 /usr/share/novnc
RUN <<EOF bash -xe
apt-get update -qq
apt-get install -qq -y --no-install-recommends \
    ethtool genisoimage ipmitool iproute2 ipxe isolinux lshw qemu-block-extra qemu-utils syslinux-common tftpd-hpa
apt-get clean
rm -rf /var/lib/apt/lists/*
EOF
ARG TARGETARCH
ADD --chmod=755 https://dl.k8s.io/release/v1.34.1/bin/linux/${TARGETARCH}/kubectl /usr/local/bin/kubectl
COPY --from=build --link /var/lib/openstack /var/lib/openstack
