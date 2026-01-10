#!/bin/bash

echo "=========================================="
echo "  Reasoning Toggle Impact Test"
echo "=========================================="
echo ""

cd simple-agent

echo "Building..."
go build -o weather-profile weather-profile.go 2>&1 > /dev/null

echo "Test 1: REASONING DISABLED (Fast Path)"
echo "  Running 3 iterations of 6 cities each..."
for run in {1..3}; do
    result=$(./weather-profile 2>&1 | grep "Total time:")
    time_val=$(echo "$result" | awk '{print $3}')
    echo "    Run $run: $time_val"
done

echo ""
echo "Test 2: REASONING ENABLED (Multi-step)"
echo "  Running 3 iterations of 6 cities each..."
for run in {1..3}; do
    result=$(./weather-profile --reasoning 2>&1 | grep "Total time:")
    time_val=$(echo "$result" | awk '{print $3}')
    echo "    Run $run: $time_val"
done

echo ""
echo "=========================================="
