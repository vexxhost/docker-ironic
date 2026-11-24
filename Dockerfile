# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:2023.2@sha256:a8141f6ccb4377fb61122481ba59b283da023d98f67b21031ac7f32312aae8ee AS build
# vexxhost/requirements pins upstream sushy, which packages.vexxhost.com does
# not serve, and there is no VEXXHOST build of sushy 4.x. Install the upstream
# wheel from PyPI, pinned by hash.
RUN --mount=type=bind,from=ironic,source=/,target=/src/ironic,readwrite <<EOF bash -xe
grep -vE '^sushy===' /upper-constraints.txt > /tmp/upper-constraints.txt
uv pip install \
    --constraint /tmp/upper-constraints.txt \
        /src/ironic \
        python-dracclient \
        "sushy @ https://files.pythonhosted.org/packages/5a/a1/70364e770217d0adedb134a17da9051958d2fa55feb5ba5b4b14dd6030c9/sushy-4.5.2-py3-none-any.whl#sha256=14b4838d379a272e12bea20c81d87416fedfc2691ecd1eaa63392adb0b55a713"
EOF

FROM ghcr.io/vexxhost/python-base:2023.2@sha256:2864a63386dcb0b75bab6ec9ebeee1e65869921e81db17f17517ff34eddb2dcc
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
