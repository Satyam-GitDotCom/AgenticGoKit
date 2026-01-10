#!/bin/bash

# Profiling script for Go weather-tool

echo "========================================="
echo "  Go Weather-Tool Profiler"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Ensure binary is built
if [ ! -f "simple-agent/weather-tool" ]; then
    echo -e "${YELLOW}Building weather-tool...${NC}"
    cd simple-agent && go build -o weather-tool weather-tool.go && cd ..
fi

# Create profiles directory
mkdir -p profiles

echo -e "${BLUE}1. Running with verbose timing...${NC}"
echo "-----------------------------------"
./simple-agent/weather-tool -v
echo ""

echo -e "${BLUE}2. Running with CPU profiling...${NC}"
echo "-----------------------------------"
./simple-agent/weather-tool -cpuprofile=profiles/cpu.prof -memprofile=profiles/mem.prof -v
echo ""

echo -e "${GREEN}Profiles saved to profiles/ directory${NC}"
echo ""

echo -e "${BLUE}3. Analyzing CPU profile...${NC}"
echo "-----------------------------------"
echo "Top 10 functions by CPU time:"
go tool pprof -top -nodecount=10 profiles/cpu.prof
echo ""

echo -e "${BLUE}4. Analyzing Memory profile...${NC}"
echo "-----------------------------------"
echo "Top 10 functions by memory allocation:"
go tool pprof -top -nodecount=10 profiles/mem.prof
echo ""

echo "========================================="
echo "  Profile Analysis Complete"
echo "========================================="
echo ""
echo "To view interactive CPU profile in browser:"
echo -e "  ${GREEN}go tool pprof -http=:8080 profiles/cpu.prof${NC}"
echo ""
echo "To view interactive Memory profile in browser:"
echo -e "  ${GREEN}go tool pprof -http=:8080 profiles/mem.prof${NC}"
echo ""
echo "To see flame graph:"
echo -e "  ${GREEN}go tool pprof -http=:8080 profiles/cpu.prof${NC}"
echo "  Then navigate to View > Flame Graph"
echo ""
