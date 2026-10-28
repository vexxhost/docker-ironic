# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:main@sha256:c0add116e1e2c3c1d70131612528c3c3a6e41be6287d8f0f5fba67adbebb91bb AS build
ARG IRONIC_VERSION=38.0.0+a8e.36.1
RUN --mount=type=bind,source=build,target=/build \
    --mount=type=bind,source=patches,target=/patches <<'EOF' bash -xe
uv run --index https://pypi.org/simple --script /build/patch-wheel.py \
    --constraint /upper-constraints.txt \
    "ironic==${IRONIC_VERSION}" /patches/openstack/ironic /tmp/patched-wheels
uv pip install \
    --constraint /upper-constraints.txt \
        /tmp/patched-wheels/*.whl \
        python-dracclient \
        sushy
/var/lib/openstack/bin/python -c 'from ironic.conf import CONF; from ironic.common import wsgi_service'
EOF

FROM ghcr.io/vexxhost/python-base:main@sha256:ab6c60c427ade851e06c8152f94d2c3406436ab2d9854714c6f9417ed292e56d
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
