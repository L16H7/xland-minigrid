#!/bin/bash

# Script to run all XLand-MiniGrid benchmarks sequentially
# Run this in tmux to ensure experiments continue even if connection is lost

set -e  # Exit on any error

echo "Starting XLand-MiniGrid benchmark experiments at $(date)"
echo "========================================================="

# Change to the project root directory
cd /root/xland-minigrid

# List of all benchmark config files
BENCHMARKS=(
    "configs/benchmarks/h0_trivial_1m.yaml"
    "configs/benchmarks/h1_trivial_1m.yaml"
    "configs/benchmarks/h0_small_1m.yaml"
    "configs/benchmarks/h1_small_1m.yaml"
    "configs/benchmarks/h0_medium_1m.yaml"
    "configs/benchmarks/h1_medium_1m.yaml"
    "configs/benchmarks/h0_medium_3m.yaml"
    "configs/benchmarks/h1_medium_3m.yaml"
    "configs/benchmarks/h0_high_1m.yaml"
    "configs/benchmarks/h1_high_1m.yaml"
    "configs/benchmarks/h0_high_3m.yaml"
    "configs/benchmarks/h1_high_3m.yaml"
)

# Total number of benchmarks
TOTAL=${#BENCHMARKS[@]}
CURRENT=0

echo "Found $TOTAL benchmark configurations to run"
echo ""

# Function to run a single benchmark
run_benchmark() {
    local config_path=$1
    local benchmark_name=$(basename "$config_path" .yaml)
    
    CURRENT=$((CURRENT + 1))
    
    echo "[$CURRENT/$TOTAL] Starting benchmark: $benchmark_name"
    echo "Config: $config_path"
    echo "Started at: $(date)"
    echo "----------------------------------------"
    
    # Run the training
    python training/train_meta_task.py --config-path="$config_path"
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo "✅ Successfully completed: $benchmark_name"
    else
        echo "❌ Failed: $benchmark_name (exit code: $exit_code)"
        echo "Continuing with next benchmark..."
    fi
    
    echo "Finished at: $(date)"
    echo "========================================"
    echo ""
}

# Log start time
START_TIME=$(date)
echo "Batch started at: $START_TIME"
echo ""

# Run all benchmarks
for config in "${BENCHMARKS[@]}"; do
    if [ -f "$config" ]; then
        run_benchmark "$config"
    else
        echo "⚠️  Warning: Config file not found: $config"
        echo ""
    fi
done

# Log completion
END_TIME=$(date)
echo "========================================================="
echo "All experiments completed!"
echo "Started at:  $START_TIME"
echo "Finished at: $END_TIME"
echo "Total benchmarks processed: $CURRENT/$TOTAL"
echo "========================================================="
