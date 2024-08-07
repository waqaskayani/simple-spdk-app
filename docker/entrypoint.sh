#!/bin/bash

# Env. variables for SPDK configuration
NRHUGE=$1                           # Number of hugepages to allocate. This variable overwrites HUGEMEM
DRIVER_OVERRIDE=$2                  # Disable automatic selection and forcefully bind devices to the given driver
MEM_SIZE=$3                         # Memory size in MB for DPDK

# Start the SPDK NVMe-oF target and store the process PID
NRHUGE=$NRHUGE DRIVER_OVERRIDE=$DRIVER_OVERRIDE ./scripts/setup.sh && ./build/bin/nvmf_tgt -s $MEM_SIZE &
NVMF_TGT_PID=$!

# Run the RPC command to initiate the tcp transport after waiting 5 seconds
sleep 5
./scripts/rpc.py nvmf_create_transport -t TCP -u 16384 -m 8 -c 8192

# Monitor the nvmf_tgt process
wait $NVMF_TGT_PID
