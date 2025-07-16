#!/bin/bash

# Advanced script to run medium_1m_bench with parallel execution and logging
# Runs H0 and H1 alternately for the same seed (H0 first, then H1)

set -e  # Exit on any error

# Configuration
SEEDS=(42 123 456 789 1337)
H0_CONFIG="configs/medium_1m_bench/h0_medium_1m.yaml"
H1_CONFIG="configs/medium_1m_bench/h1_medium_1m.yaml"
SCRIPT_DIR="training/train_meta_task.py"
LOG_DIR="logs/medium_1m_bench_$(date +%Y%m%d_%H%M%S)"
PARALLEL_JOBS=1  # Set to 2 if you want to run H0 and H1 in parallel

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create log directory
mkdir -p "$LOG_DIR"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Medium 1M Benchmark Experiment${NC}"
echo -e "${BLUE}  Running H0 and H1 with 5 seeds${NC}"
echo -e "${BLUE}  Log directory: $LOG_DIR${NC}"
echo -e "${BLUE}  Parallel jobs: $PARALLEL_JOBS${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to run experiment
run_experiment() {
    local config_file=$1
    local seed=$2
    local exp_type=$3
    local log_file="$LOG_DIR/${exp_type}_seed_${seed}.log"
    local save_dir="/root/experiment_${exp_type,,}_${seed}"
    
    echo -e "${YELLOW}Starting $exp_type experiment with seed $seed...${NC}"
    echo -e "${YELLOW}Config: $config_file${NC}"
    echo -e "${YELLOW}Save directory: $save_dir${NC}"
    echo -e "${YELLOW}Log file: $log_file${NC}"
    echo ""
    
    # Create save directory
    mkdir -p "$save_dir"
    
    # Run the experiment with logging
    if python $SCRIPT_DIR \
        --config_path $config_file \
        --train_seed $seed \
        --eval_seed $seed \
        --checkpoint_path "$save_dir" \
        --name "${exp_type}-medium-1m-seed-${seed}" \
        > "$log_file" 2>&1; then
        echo -e "${GREEN}✓ $exp_type experiment with seed $seed completed successfully${NC}"
        echo "Final results saved to: $log_file"
        # Extract final return from log
        if grep -q "Final return:" "$log_file"; then
            final_return=$(grep "Final return:" "$log_file" | tail -1 | awk '{print $3}')
            echo -e "${GREEN}Final return: $final_return${NC}"
        fi
    else
        echo -e "${RED}✗ $exp_type experiment with seed $seed failed${NC}"
        echo -e "${RED}Check log file: $log_file${NC}"
        return 1
    fi
    echo ""
}

# Function to run experiments for a single seed
run_seed_experiments() {
    local seed=$1
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Seed: $seed${NC}"
    echo -e "${BLUE}========================================${NC}"
    
    if [ "$PARALLEL_JOBS" -eq 1 ]; then
        # Sequential execution
        run_experiment $H0_CONFIG $seed "H0"
        run_experiment $H1_CONFIG $seed "H1"
    else
        # Parallel execution
        echo "Running H0 and H1 in parallel..."
        (run_experiment $H0_CONFIG $seed "H0") &
        pid_h0=$!
        (run_experiment $H1_CONFIG $seed "H1") &
        pid_h1=$!
        
        # Wait for both to complete
        wait $pid_h0
        wait $pid_h1
    fi
    
    echo -e "${GREEN}Completed both H0 and H1 for seed $seed${NC}"
    echo ""
}

# Main experiment loop
total_experiments=$((${#SEEDS[@]} * 2))
echo "Total experiments to run: $total_experiments"
echo ""

# Track start time
start_time=$(date +%s)

for seed in "${SEEDS[@]}"; do
    run_seed_experiments $seed
done

# Calculate total time
end_time=$(date +%s)
total_time=$((end_time - start_time))
hours=$((total_time / 3600))
minutes=$(((total_time % 3600) / 60))
seconds=$((total_time % 60))

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  All experiments completed!${NC}"
echo -e "${GREEN}  Total experiments run: $total_experiments${NC}"
echo -e "${GREEN}  Total time: ${hours}h ${minutes}m ${seconds}s${NC}"
echo -e "${GREEN}  Logs saved in: $LOG_DIR${NC}"
echo -e "${GREEN}========================================${NC}"

# Create summary of results
echo "Creating results summary..."
summary_file="$LOG_DIR/summary.txt"
echo "Medium 1M Benchmark Results Summary" > "$summary_file"
echo "Generated on: $(date)" >> "$summary_file"
echo "Total runtime: ${hours}h ${minutes}m ${seconds}s" >> "$summary_file"
echo "" >> "$summary_file"

echo "Seed,Type,Final_Return,Status" >> "$summary_file"
for seed in "${SEEDS[@]}"; do
    for exp_type in "H0" "H1"; do
        log_file="$LOG_DIR/${exp_type}_seed_${seed}.log"
        if [ -f "$log_file" ]; then
            if grep -q "Final return:" "$log_file"; then
                final_return=$(grep "Final return:" "$log_file" | tail -1 | awk '{print $3}')
                status="SUCCESS"
            else
                final_return="N/A"
                status="FAILED"
            fi
        else
            final_return="N/A"
            status="NOT_RUN"
        fi
        echo "$seed,$exp_type,$final_return,$status" >> "$summary_file"
    done
done

echo -e "${GREEN}Results summary saved to: $summary_file${NC}"
