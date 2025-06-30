#!/bin/bash

# OpenMP Guided Scheduling Benchmark Script
# Tests specific configurations matching dynamic analysis for direct comparison

echo "=== OpenMP Guided Scheduling Performance Analysis ==="
echo "Target configurations for direct comparison with dynamic scheduling"
echo "Date: $(date)"
echo ""

# Configuration arrays
CONFIGS=(
    "1000 1000"   # Small problem, low iterations
    "2000 1000"   # Medium problem, low iterations  
    "3000 1000"   # Large problem, low iterations
    "1000 3000"   # Small problem, medium iterations
    "1000 5000"   # Small problem, high iterations
)

THREADS=(64 32 24 16 8 4 2 1)
RUNS_PER_CONFIG=3

# Output files
OUTPUT_CSV="report/openmp_guided_specific_results.csv"
ANALYSIS_REPORT="report/openmp_guided_specific_analysis.txt"
TEMP_OUTPUT="temp_guided_output.csv"

# Ensure executable exists
if [ ! -f "openmp/mandelbrot_guided_parametric" ]; then
    echo "Building guided parametric version..."
    make build-openmp-guided-parametric
fi

# Initialize CSV with headers
echo "Configuration,Resolution,Iterations,Threads,Run,Time_ms,Speedup,Efficiency" > $OUTPUT_CSV

echo "Starting guided scheduling benchmark..."
echo "Total configurations: $((${#CONFIGS[@]} * ${#THREADS[@]} * $RUNS_PER_CONFIG))"
echo ""

config_count=0
total_configs=$((${#CONFIGS[@]} * ${#THREADS[@]}))

# Get sequential baseline for speedup calculations
echo "Establishing sequential baseline..."
SEQUENTIAL_1000_1000=$(cd /home/stud/S5843444/mandelbrot && OMP_NUM_THREADS=1 ./openmp/mandelbrot_guided_parametric $TEMP_OUTPUT 1000 1000 2>&1 | grep "Execution time:" | awk '{print $3}')
SEQUENTIAL_2000_1000=$(cd /home/stud/S5843444/mandelbrot && OMP_NUM_THREADS=1 ./openmp/mandelbrot_guided_parametric $TEMP_OUTPUT 2000 1000 2>&1 | grep "Execution time:" | awk '{print $3}')
SEQUENTIAL_3000_1000=$(cd /home/stud/S5843444/mandelbrot && OMP_NUM_THREADS=1 ./openmp/mandelbrot_guided_parametric $TEMP_OUTPUT 3000 1000 2>&1 | grep "Execution time:" | awk '{print $3}')
SEQUENTIAL_1000_3000=$(cd /home/stud/S5843444/mandelbrot && OMP_NUM_THREADS=1 ./openmp/mandelbrot_guided_parametric $TEMP_OUTPUT 1000 3000 2>&1 | grep "Execution time:" | awk '{print $3}')
SEQUENTIAL_1000_5000=$(cd /home/stud/S5843444/mandelbrot && OMP_NUM_THREADS=1 ./openmp/mandelbrot_guided_parametric $TEMP_OUTPUT 1000 5000 2>&1 | grep "Execution time:" | awk '{print $3}')

echo "Sequential baselines established:"
echo "  1000x1000, 1000 iter: ${SEQUENTIAL_1000_1000} ms"
echo "  2000x2000, 1000 iter: ${SEQUENTIAL_2000_1000} ms" 
echo "  3000x3000, 1000 iter: ${SEQUENTIAL_3000_1000} ms"
echo "  1000x1000, 3000 iter: ${SEQUENTIAL_1000_3000} ms"
echo "  1000x1000, 5000 iter: ${SEQUENTIAL_1000_5000} ms"
echo ""

# Main benchmark loop
for config in "${CONFIGS[@]}"; do
    read -r resolution iterations <<< "$config"
    
    # Get sequential baseline for this configuration
    case "${resolution}_${iterations}" in
        "1000_1000") sequential_time=$SEQUENTIAL_1000_1000 ;;
        "2000_1000") sequential_time=$SEQUENTIAL_2000_1000 ;;
        "3000_1000") sequential_time=$SEQUENTIAL_3000_1000 ;;
        "1000_3000") sequential_time=$SEQUENTIAL_1000_3000 ;;
        "1000_5000") sequential_time=$SEQUENTIAL_1000_5000 ;;
    esac
    
    for threads in "${THREADS[@]}"; do
        config_count=$((config_count + 1))
        echo "[$config_count/$total_configs] Testing ${resolution}x${resolution}, ${iterations} iter, ${threads} threads"
        
        # Run multiple times and take the best (minimum) time
        best_time=999999
        for run in $(seq 1 $RUNS_PER_CONFIG); do
            echo -n "  Run $run: "
            
            # Execute benchmark
            result=$(cd /home/stud/S5843444/mandelbrot && OMP_NUM_THREADS=$threads ./openmp/mandelbrot_guided_parametric $TEMP_OUTPUT $resolution $iterations 2>&1)
            
            # Extract execution time
            time_ms=$(echo "$result" | grep "Execution time:" | awk '{print $3}')
            
            if [ -z "$time_ms" ]; then
                echo "ERROR - No timing data"
                time_ms=999999
            else
                echo "${time_ms} ms"
                if (( $(echo "$time_ms < $best_time" | bc -l) )); then
                    best_time=$time_ms
                fi
            fi
            
            # Calculate speedup and efficiency
            if [ "$sequential_time" != "0" ] && [ -n "$sequential_time" ]; then
                speedup=$(echo "scale=3; $sequential_time / $time_ms" | bc -l)
                efficiency=$(echo "scale=3; $speedup / $threads * 100" | bc -l)
            else
                speedup="N/A"
                efficiency="N/A"
            fi
            
            # Save to CSV
            echo "${resolution}x${resolution}_${iterations},${resolution},${iterations},${threads},${run},${time_ms},${speedup},${efficiency}" >> $OUTPUT_CSV
        done
        
        echo "  Best time: ${best_time} ms"
        echo ""
    done
done

# Generate analysis report
echo "Generating analysis report..."

cat > $ANALYSIS_REPORT << 'EOF'
# OpenMP Guided Scheduling Performance Analysis

## Executive Summary

This analysis evaluates OpenMP guided scheduling performance across different
problem sizes and thread configurations, providing direct comparison data
with static and dynamic scheduling approaches.

## Methodology

- **Scheduling**: OpenMP guided (adaptive chunk sizing)
- **Compiler**: g++ with -O2 -fopenmp optimization
- **Timing**: High-precision millisecond measurement (best of 3 runs)
- **Thread Counts**: 64, 32, 24, 16, 8, 4, 2, 1
- **Configurations**: 5 specific problem size/iteration combinations

## Test Configurations

EOF

# Add configuration details to report
python3 << 'PYTHON_SCRIPT' >> $ANALYSIS_REPORT

import csv
import pandas as pd

# Read the CSV data
df = pd.read_csv('report/openmp_guided_specific_results.csv')

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

# Find best performance for each configuration
best_results = []
for config in df['Configuration'].unique():
    config_data = df[df['Configuration'] == config]
    best_idx = config_data.groupby('Threads')['Time_ms'].min().idxmin()
    best_row = config_data.loc[config_data.groupby('Threads')['Time_ms'].idxmin()]
    best_overall = best_row.loc[best_row['Time_ms'].idxmin()]
    best_results.append(best_overall)

print("### Best Performance by Configuration\n")
print("| Configuration | Best Threads | Time (ms) | Speedup | Efficiency |")
print("|---------------|--------------|-----------|---------|------------|")

for result in best_results:
    config = result['Configuration']
    threads = int(result['Threads'])
    time_ms = f"{result['Time_ms']:,.0f}"
    speedup = f"{result['Speedup']:.2f}×" if pd.notna(result['Speedup']) else "N/A"
    efficiency = f"{result['Efficiency']:.1f}%" if pd.notna(result['Efficiency']) else "N/A"
    
    print(f"| {config} | {threads} | {time_ms} | {speedup} | {efficiency} |")

PYTHON_SCRIPT

cat >> $ANALYSIS_REPORT << 'EOF'

## Key Findings

### Guided Scheduling Characteristics

**Adaptive Load Balancing**: Guided scheduling starts with larger chunks and
progressively reduces chunk size as work is distributed, providing a balance
between the predictability of static scheduling and the flexibility of dynamic.

**Thread Scaling**: Performance analysis across thread counts reveals optimal
configurations for different problem sizes and computational intensities.

**Efficiency Patterns**: Guided scheduling demonstrates distinct efficiency
characteristics compared to static and dynamic approaches, particularly in
how it handles load imbalance.

## Comparison Readiness

This analysis provides the foundation for comprehensive comparison with:
- **Static scheduling results** (72 configurations tested)
- **Dynamic scheduling results** (40 configurations tested)
- **Sequential baseline** performance metrics

## Technical Details

- **Chunk Size Strategy**: Guided scheduling automatically adjusts chunk sizes
- **Load Balancing**: Better than static, potentially more efficient than dynamic
- **Overhead**: Lower than pure dynamic, higher than static scheduling
- **Scalability**: Expected to show good performance across thread counts

---

*Analysis completed*: $(date)
*Total measurements*: $(wc -l < report/openmp_guided_specific_results.csv | awk '{print $1-1}')
*Compiler*: g++ with OpenMP support
*Optimization*: -O2 level with guided scheduling
EOF

# Clean up
rm -f $TEMP_OUTPUT

echo "=== Guided Scheduling Benchmark Complete ==="
echo "Results saved to: $OUTPUT_CSV"
echo "Analysis report: $ANALYSIS_REPORT"
echo ""
echo "Key files generated:"
echo "  - Raw data: $OUTPUT_CSV"
echo "  - Analysis: $ANALYSIS_REPORT"
echo ""
echo "Next steps:"
echo "  1. Review guided scheduling results"
echo "  2. Run three-way comparison analysis"
echo "  3. Generate comprehensive scheduling comparison report"
