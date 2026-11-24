# SPDX-FileCopyrightText: © 2025 VEXXHOST, Inc.
# SPDX-License-Identifier: GPL-3.0-or-later
# Atmosphere-Rebuild-Time: 2024-06-25T22:49:25Z

FROM ghcr.io/vexxhost/openstack-venv-builder:zed@sha256:b745636e619cc287f3783d2cba726f18d6677e86659229246ab15d6fbbfa0c96 AS build
# vexxhost/requirements pins upstream sushy, which packages.vexxhost.com does
# not serve, and there is no VEXXHOST build of sushy 4.x. Install the upstream
# wheel from PyPI, pinned by hash.
RUN --mount=type=bind,from=ironic,source=/,target=/src/ironic,readwrite <<EOF bash -xe
grep -vE '^sushy===' /upper-constraints.txt > /tmp/upper-constraints.txt
uv pip install \
    --constraint /tmp/upper-constraints.txt \
        /src/ironic \
        python-dracclient \
        "sushy @ https://files.pythonhosted.org/packages/56/dc/6833e8ee47fdab7fc908cb9786ae7223c63972e2742564aa291241767a5e/sushy-4.3.4-py3-none-any.whl#sha256=ac381ffff7be7cc3e875ce38147eeebf853ce00c8af4836ab58488f01524ef3a"
EOF

FROM ghcr.io/vexxhost/python-base:zed@sha256:8d900fd0b0e5b9747652056e564daa5be3868f5aa01bde7805afebecc278a1d8
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
