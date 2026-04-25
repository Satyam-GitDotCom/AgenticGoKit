#!/bin/bash
echo "Testing Go agent with 5 iterations..."
for i in {1..5}; do
  timeout 30 go run agent-stage-profiler.go --city sf 2>&1 | grep -a "Wall-clock" | sed 's/Wall-clock time: /Run '$i': /'
done
