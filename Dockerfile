# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2023.1@sha256:807987ac94bad6d85f55f8b320b37062600357642614d87daac2d699a8d134b0 AS build
# vexxhost/requirements pins upstream sushy, which packages.vexxhost.com does
# not serve, and there is no VEXXHOST build of sushy 4.x. Install the upstream
# wheel from PyPI, pinned by hash.
RUN --mount=type=bind,from=ironic,source=/,target=/src/ironic,readwrite <<EOF bash -xe
grep -vE '^sushy===' /upper-constraints.txt > /tmp/upper-constraints.txt
uv pip install \
    --constraint /tmp/upper-constraints.txt \
        /src/ironic \
        python-dracclient \
        "sushy @ https://files.pythonhosted.org/packages/5f/f5/c7f9b3baa114d17811205333531f637162265b45c2021fa05190c8aeb42e/sushy-4.4.3-py3-none-any.whl#sha256=b79f24cc21b02365e64d1c0370f149916be4d53d634c6634abea73b9b6ed24b0"
EOF

FROM ghcr.io/vexxhost/python-base:2023.1@sha256:3e6ee9d16016a3ae4dc11883220adfe5cd4563e20d8c9d809801cca50e79e4f3
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
