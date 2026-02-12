#!/usr/bin/env bash

BACKENDS=""
PORT=${1:-3005}
COUNT=${2:-1}
PIDS=()
LOGDIR=$(mktemp -d)

for p in $(seq 3015 $((3015 + COUNT - 1))); do
  sam local start-lambda --warm-containers=LAZY -p $p >"$LOGDIR/$p.log" 2>&1 &
  PIDS+=($!)
  BACKENDS="$BACKENDS
  server s$p 127.0.0.1:$p";
done;
trap 'kill "${PIDS[@]}" 2>/dev/null' EXIT

for p in $(seq 3015 $((3015 + COUNT - 1))); do
  while ! grep -q "Press CTRL+C to quit" "$LOGDIR/$p.log" 2>/dev/null; do
    sleep 0.1
  done
done
echo "All $COUNT backends ready"
tail -f -q -n 0 "$LOGDIR"/*.log &
TAIL_PID=$!

LAMBDA_TIMEOUT=$(yq '.Resources.metadataAgent.Properties.Timeout' < template.yaml)
TIMEOUT="$((LAMBDA_TIMEOUT + 5))s"
CONFIG="defaults
  mode tcp
  timeout connect 5s
  timeout client $TIMEOUT
  timeout server $TIMEOUT

frontend f
  bind *:$PORT
  default_backend b

backend b
  balance roundrobin
$BACKENDS"

PIDS+=($TAIL_PID)
echo " * Running on http://127.0.0.1:$PORT/ (Press CTRL+C to quit)"
echo "$CONFIG" | haproxy -f /dev/stdin
