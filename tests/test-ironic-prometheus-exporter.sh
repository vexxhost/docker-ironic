#!/bin/bash

set -euxo pipefail

python - <<'PY'
from importlib.metadata import entry_points

import ironic_prometheus_exporter

drivers = entry_points(group="oslo.messaging.notify.drivers")
assert any(driver.name == "prometheus_exporter" for driver in drivers)
PY

metrics_dir="$(mktemp -d)"
config_file="$(mktemp)"
exporter_port="$(
  python - <<'PY'
import socket

with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"
cat >"${config_file}" <<EOF
[oslo_messaging_notifications]
location = ${metrics_dir}
EOF

IRONIC_CONFIG="${config_file}" \
  uwsgi \
    --http-socket "127.0.0.1:${exporter_port}" \
    --processes 1 \
    --master \
    --die-on-term \
    --need-app \
    --module ironic_prometheus_exporter.app.wsgi:application &
exporter_pid=$!
trap 'kill "${exporter_pid}" 2>/dev/null || true' EXIT

for _ in {1..30}; do
  if ! kill -0 "${exporter_pid}" 2>/dev/null; then
    wait "${exporter_pid}" || true
    exit 1
  fi
  if EXPORTER_PORT="${exporter_port}" python -c \
    'import os; from urllib.request import urlopen; urlopen("http://127.0.0.1:{}/metrics".format(os.environ["EXPORTER_PORT"]), timeout=1).read()'; then
    exit 0
  fi
  sleep 1
done

exit 1
