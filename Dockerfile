# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later

FROM ghcr.io/vexxhost/openstack-venv-builder:2025.1@sha256:1c59562cda6bffe43e671f7171cbfd4f4e308bde88c51e9c5e7fc8e9740d4e68 AS build
ARG IRONIC_VERSION=29.1.0+a8e.7.2
# vexxhost/requirements pins upstream sushy, which packages.vexxhost.com does
# not serve. Install the VEXXHOST builds of sushy that this release ships.
RUN <<EOF bash -xe
grep -vE '^sushy(-oem-idrac)?===' /upper-constraints.txt > /tmp/upper-constraints.txt
uv pip install \
    --constraint /tmp/upper-constraints.txt \
        "ironic==${IRONIC_VERSION}" \
        python-dracclient \
        sushy==5.5.1+a8e.0.3 \
        sushy-oem-idrac==6.0.0
EOF

FROM ghcr.io/vexxhost/python-base:2025.1@sha256:053e0183e08774439ccb21789a21fdd54e71f39e5960eaa9be5b0eaa4b92c074
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
COPY --from=build --link /var/lib/openstack /var/lib/openstack
