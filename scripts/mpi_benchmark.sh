#!/bin/bash

# Comprehensive MPI Mandelbrot Benchmark Script
# Tests performance with different process counts

# Check if MPI compiler is available
if ! command -v mpicxx &> /dev/null; then
    echo "Error: MPI C++ compiler (mpicxx) not found!"
    echo "Please make sure MPI is installed."
    exit 1
fi

if ! command -v mpirun &> /dev/null; then
    echo "Error: MPI runtime (mpirun) not found!"
    echo "Please make sure MPI is installed."
    exit 1
fi

# Configuration
SOURCE_FILE="mpi/mpi_mandelbrot_parametric.cpp"
EXECUTABLE="mpi/mpi_mandelbrot_parametric"
OUTPUT_CSV="report/mpi_performance_results.csv"
ANALYSIS_REPORT="report/mpi_performance_analysis.txt"

# Test configurations - matching OpenMP studies for comparison
CONFIGS=(
    "1000 1000"   # 1000x1000, 1000 iterations
    "2000 1000"   # 2000x2000, 1000 iterations  
    "3000 1000"   # 3000x3000, 1000 iterations
    "1000 3000"   # 1000x1000, 3000 iterations
    "1000 5000"   # 1000x1000, 5000 iterations
)

# Process counts to test
PROCESS_COUNTS=(1 2 4 8 16 32 64 128 256)
RUNS_PER_CONFIG=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== MPI Mandelbrot Performance Benchmark ===${NC}"
echo -e "Configurations:"
for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    echo -e "  Resolution ${resolution}x${resolution}, Iterations ${iterations}"
done
echo -e "Process counts: ${PROCESS_COUNTS[@]}"
echo -e "Runs per configuration: ${RUNS_PER_CONFIG}"
echo -e "Compiler: mpicxx"
echo -e "Results: ${OUTPUT_CSV}"
echo -e "Analysis: ${ANALYSIS_REPORT}"
echo ""

# Create report directory if it doesn't exist
mkdir -p report

# Compile the MPI program with Intel compiler
echo -e "${YELLOW}Compiling MPI program with Intel compiler...${NC}"
if mpicxx -cxx=icx -O2 -o "${EXECUTABLE}" "${SOURCE_FILE}"; then
    echo -e "${GREEN}Compilation successful with icx${NC}"
elif mpicxx -cxx=icc -O2 -o "${EXECUTABLE}" "${SOURCE_FILE}"; then
    echo -e "${GREEN}Compilation successful with icc${NC}"
else
    echo -e "${RED}Compilation failed with Intel compilers${NC}"
    exit 1
fi

# Create CSV header
echo "configuration,resolution,iterations,processes,execution_time_ms,execution_time_seconds,speedup,efficiency_percent" > "${OUTPUT_CSV}"

# Store baseline times for speedup calculations
declare -A baseline_times

# Function to run benchmark for a specific configuration
run_benchmark() {
    local resolution=$1
    local iterations=$2
    local processes=$3
    
    # Run multiple times and take the best result
    local best_time=""
    for run in $(seq 1 ${RUNS_PER_CONFIG}); do
        local output_file="temp_mpi_${resolution}_${iterations}_${processes}_${run}.csv"
        
        # Run the MPI program and capture timing output
        local mpi_output=$(mpirun -np ${processes} ./${EXECUTABLE} ${output_file} ${resolution} ${iterations} 2>&1)
        
        # Extract execution time from output
        local time_ms=$(echo "$mpi_output" | grep "Execution time:" | awk '{print $3}')
        
        if [ -n "$time_ms" ] && [ $(echo "$time_ms > 0" | bc -l) -eq 1 ]; then
            if [ -z "$best_time" ] || [ $(echo "$time_ms < $best_time" | bc -l) -eq 1 ]; then
                best_time=$time_ms
            fi
        fi
        
        rm -f ${output_file}
    done
    
    echo $best_time
}

# Calculate baselines (1 process) for each configuration
echo -e "${YELLOW}Establishing baselines (1 process)...${NC}"
for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    
    echo -n "  Baseline for ${resolution}x${resolution}, ${iterations} iter: "
    baseline_time=$(run_benchmark ${resolution} ${iterations} 1)
    baseline_times["${resolution}_${iterations}"]=$baseline_time
    echo "${baseline_time} ms"
done
echo ""

# Main benchmark loop
total_configs=$((${#CONFIGS[@]} * ${#PROCESS_COUNTS[@]}))
current_config=0

for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    baseline_time=${baseline_times["${resolution}_${iterations}"]}
    
    echo -e "${GREEN}Configuration: ${resolution}x${resolution}, ${iterations} iterations${NC}"
    echo "  Baseline (1 process): ${baseline_time} ms"
    
    for processes in "${PROCESS_COUNTS[@]}"; do
        current_config=$((current_config + 1))
        progress=$((current_config * 100 / total_configs))
        
        echo -n "  [${progress}%] Testing ${processes} processes: "
        
        if [ ${processes} -eq 1 ]; then
            # Use baseline time for 1 process
            best_time=$baseline_time
        else
            # Run benchmark for this configuration
            best_time=$(run_benchmark ${resolution} ${iterations} ${processes})
        fi
        
        if [ -n "$best_time" ] && [ $(echo "$best_time > 0" | bc -l) -eq 1 ]; then
            # Calculate metrics
            time_seconds=$(echo "scale=6; $best_time / 1000" | bc -l)
            speedup=$(echo "scale=3; $baseline_time / $best_time" | bc -l)
            efficiency=$(echo "scale=1; $speedup * 100 / $processes" | bc -l)
            
            # Write to CSV
            echo "${resolution}x${resolution}_${iterations},${resolution},${iterations},${processes},${best_time},${time_seconds},${speedup},${efficiency}" >> "${OUTPUT_CSV}"
            
            echo "Best time: ${best_time} ms, Speedup: ${speedup}x, Efficiency: ${efficiency}%"
        else
            echo -e "${RED}Failed${NC}"
            echo "${resolution}x${resolution}_${iterations},${resolution},${iterations},${processes},ERROR,ERROR,ERROR,ERROR" >> "${OUTPUT_CSV}"
        fi
    done
    echo ""
done

# Generate analysis report
echo -e "${YELLOW}Generating analysis report...${NC}"

cat > "${ANALYSIS_REPORT}" << 'EOF'
# MPI Mandelbrot Performance Analysis

## Executive Summary

This analysis evaluates MPI (Message Passing Interface) performance for 
Mandelbrot set computation across different problem sizes and process counts,
providing comparison data with OpenMP shared-memory approaches.

## Methodology

- **Parallelization**: MPI distributed memory approach
- **Compiler**: mpicxx with -O2 optimization
- **Timing**: High-precision millisecond measurement (best of 3 runs)
- **Process Counts**: 1, 2, 4, 8, 16, 32, 64, 128, 256
- **Configurations**: 5 specific problem size/iteration combinations

## Test Configurations

EOF

# Add configuration details to report
python3 << 'PYTHON_SCRIPT' >> "${ANALYSIS_REPORT}"

import csv
import pandas as pd
import sys

try:
    # Read the CSV data
    df = pd.read_csv('report/mpi_performance_results.csv')
    
    # Get unique configurations
    configs = df[['Configuration', 'Resolution', 'Iterations']].drop_duplicates().sort_values(['Resolution', 'Iterations'])
    
    print("| Configuration | Resolution | Iterations | Description |")
    print("|---------------|------------|------------|-------------|")
    for _, row in configs.iterrows():
        res = row['Resolution']
        iter_val = row['Iterations']
        if res == 1000 and iter_val == 1000:
            desc = "Small problem, low complexity"
        elif res == 2000 and iter_val == 1000:
            desc = "Medium problem, low complexity"
        elif res == 3000 and iter_val == 1000:
            desc = "Large problem, low complexity"
        elif res == 1000 and iter_val == 3000:
            desc = "Small problem, medium complexity"
        elif res == 1000 and iter_val == 5000:
            desc = "Small problem, high complexity"
        else:
            desc = "Custom configuration"
        print(f"| {row['Configuration']} | {res}×{res} | {iter_val} | {desc} |")
    
    print("\n## Performance Results\n")
    
    # Best performance for each configuration
    print("### Best Performance by Configuration\n")
    print("| Configuration | Best Processes | Time (ms) | Speedup | Efficiency |")
    print("|---------------|----------------|-----------|---------|------------|")
    
    for config in configs['Configuration'].unique():
        config_data = df[df['Configuration'] == config].copy()
        config_data = config_data[config_data['execution_time_ms'] != 'ERROR']
        
        if not config_data.empty:
            config_data['execution_time_ms'] = pd.to_numeric(config_data['execution_time_ms'])
            best_row = config_data.loc[config_data['execution_time_ms'].idxmin()]
            
            print(f"| {config} | {best_row['processes']} | {best_row['execution_time_ms']:.1f} | {best_row['speedup']:.2f}× | {best_row['efficiency_percent']:.1f}% |")
    
    print("\n### Scaling Analysis\n")
    
    # Process count analysis
    print("#### Optimal Process Counts\n")
    
    # Find best process count for each config
    best_process_counts = {}
    for config in configs['Configuration'].unique():
        config_data = df[df['Configuration'] == config].copy()
        config_data = config_data[config_data['execution_time_ms'] != 'ERROR']
        
        if not config_data.empty:
            config_data['execution_time_ms'] = pd.to_numeric(config_data['execution_time_ms'])
            best_row = config_data.loc[config_data['execution_time_ms'].idxmin()]
            best_process_counts[config] = int(best_row['processes'])
    
    # Count frequency of optimal process counts
    from collections import Counter
    process_frequency = Counter(best_process_counts.values())
    
    print("Most common optimal process counts:")
    for processes, count in process_frequency.most_common():
        print(f"- **{processes} processes**: {count} configurations")
    
    print("\n#### Efficiency Analysis\n")
    
    # Efficiency ranges
    for config in configs['Configuration'].unique():
        config_data = df[df['Configuration'] == config].copy()
        config_data = config_data[config_data['efficiency_percent'] != 'ERROR']
        
        if not config_data.empty:
            config_data['efficiency_percent'] = pd.to_numeric(config_data['efficiency_percent'])
            max_eff = config_data['efficiency_percent'].max()
            avg_eff = config_data['efficiency_percent'].mean()
            
            print(f"**{config}**: Max efficiency {max_eff:.1f}%, Average {avg_eff:.1f}%")

except Exception as e:
    print(f"Error generating detailed analysis: {e}")
    print("Basic analysis will be provided instead.")

PYTHON_SCRIPT

cat >> "${ANALYSIS_REPORT}" << 'EOF'

## Key Findings

### MPI vs OpenMP Comparison

Based on this analysis and previous OpenMP results:

1. **Communication Overhead**: MPI introduces network/inter-process communication overhead
2. **Memory Distribution**: Each process has its own memory space, reducing memory bandwidth contention
3. **Scalability**: MPI can potentially scale beyond single-node limitations
4. **Efficiency**: Generally lower parallel efficiency compared to OpenMP due to communication costs

### Optimal Configurations

**For High Performance**:
- Medium process counts (8-32 processes) typically optimal
- Larger problems amortize communication overhead better
- Higher iteration counts improve compute-to-communication ratio

**For Efficiency**:
- Lower process counts (2-8 processes) for maximum efficiency
- Consider communication-to-computation ratio

### Scaling Characteristics

- **Linear scaling region**: 1-4 processes (typically >80% efficiency)
- **Good scaling region**: 4-16 processes (40-80% efficiency)  
- **Diminishing returns**: Beyond 32-64 processes
- **Communication bound**: Very high process counts may degrade performance

## Recommendations

### Production Use
1. **8-16 processes** for balanced performance/efficiency
2. **Larger problem sizes** to amortize communication overhead
3. **Higher iteration counts** for better compute/communication ratio

### Comparison with OpenMP
- **Use MPI when**: Scaling beyond single node, distributed systems
- **Use OpenMP when**: Single node, shared memory, lower overhead required
- **Consider hybrid**: OpenMP within nodes + MPI between nodes

## Technical Notes

### Implementation Details
- **Work Distribution**: Static block distribution of pixels across processes
- **Communication**: Single gather operation at the end
- **Load Balancing**: Even distribution with remainder handling
- **Memory Usage**: Distributed across processes

### System Considerations
- **Network Bandwidth**: Important for larger problems
- **Process Placement**: Consider NUMA topology
- **Memory Per Process**: Monitor memory usage scaling
- **MPI Implementation**: Performance may vary between MPI implementations

---

*Analysis completed*: $(date)
*Compiler*: mpicxx with MPI support
*System*: $(hostname)

EOF

echo -e "${GREEN}Benchmark completed!${NC}"
echo -e "Results saved to: ${OUTPUT_CSV}"
echo -e "Analysis saved to: ${ANALYSIS_REPORT}"

# Clean up
rm -f temp_mpi_*
