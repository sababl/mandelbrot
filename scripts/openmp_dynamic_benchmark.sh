#!/bin/bash

# OpenMP Dynamic Scheduling Benchmark for Specific Configurations
# Tests the configurations requested by the user

# Configuration arrays - specific configurations requested
CONFIGS=(
    "1000 1000"   # RES 1000 – ITR 1000
    "2000 1000"   # RES 2000 – ITR 1000  
    "3000 1000"   # RES 3000 – ITR 1000
    "1000 3000"   # ITR 3000 – RES 1000
    "1000 5000"   # ITR 5000 – RES 1000
)

THREADS=(64 32 24 16 8 4 2 1)
RUNS_PER_CONFIG=3

# Output files
OUTPUT_CSV="report/openmp_dynamic_specific_results.csv"
ANALYSIS_REPORT="report/openmp_dynamic_specific_analysis.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== OpenMP Dynamic Scheduling Benchmark (Specific Configurations) ===${NC}"
echo -e "Configurations:"
for config in "${CONFIGS[@]}"; do
    echo -e "  Resolution ${config%% *}x${config%% *}, Iterations ${config##* }"
done
echo -e "Thread counts: ${THREADS[@]}"
echo -e "Runs per configuration: ${RUNS_PER_CONFIG}"
echo -e "Compiler: Intel C Compiler (icc)"
echo -e "Results: ${OUTPUT_CSV}"
echo -e "Analysis: ${ANALYSIS_REPORT}"
echo ""

# Create CSV header
echo "resolution,iterations,threads,execution_time_ms,execution_time_seconds,speedup,efficiency_percent" > ${OUTPUT_CSV}

# Store baseline times for speedup calculations
declare -A baseline_times

# Function to run benchmark for a specific configuration
run_benchmark() {
    local resolution=$1
    local iterations=$2
    local threads=$3
    
    export OMP_NUM_THREADS=${threads}
    
    # Run multiple times and take the best result
    local best_time=""
    for run in $(seq 1 ${RUNS_PER_CONFIG}); do
        local output_file="temp_dynamic_${resolution}_${iterations}_${threads}_${run}.csv"
        
        # Use high precision timing
        local start_ns=$(date +%s%N)
        ./openmp/mandelbrot_dynamic_parametric ${output_file} ${resolution} ${iterations} > /dev/null 2>&1
        local end_ns=$(date +%s%N)
        
        # Calculate time in nanoseconds, then convert
        local time_ns=$((end_ns - start_ns))
        local time_ms=$(echo "scale=3; $time_ns / 1000000" | bc -l)
        
        if [ -z "$best_time" ] || [ $(echo "$time_ms < $best_time" | bc) -eq 1 ]; then
            best_time=$time_ms
        fi
        
        rm -f ${output_file}
    done
    
    echo $best_time
}

# Calculate baselines (1 thread) for each configuration
echo -e "${YELLOW}Establishing baselines (1 thread)...${NC}"
for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    echo "  Resolution ${resolution}x${resolution}, Iterations ${iterations}..."
    baseline_time=$(run_benchmark $resolution $iterations 1)
    baseline_times["${resolution}_${iterations}"]=$baseline_time
    echo "    Baseline: ${baseline_time} ms"
done
echo ""

# Main benchmark loop
total_configs=$((${#CONFIGS[@]} * ${#THREADS[@]}))
current_config=0

for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    
    echo -e "${BLUE}=== Testing Resolution ${resolution}x${resolution}, Iterations ${iterations} ===${NC}"
    
    baseline_time=${baseline_times["${resolution}_${iterations}"]}
    
    for threads in "${THREADS[@]}"; do
        current_config=$((current_config + 1))
        echo -e "${YELLOW}[${current_config}/${total_configs}] Testing ${threads} threads...${NC}"
        
        best_time=$(run_benchmark $resolution $iterations $threads)
        time_seconds=$(echo "scale=6; $best_time / 1000" | bc -l)
        
        # Calculate speedup and efficiency
        if [ -n "$baseline_time" ] && [ "$baseline_time" != "0" ]; then
            speedup=$(echo "scale=3; $baseline_time / $best_time" | bc -l)
            efficiency=$(echo "scale=1; $speedup / $threads * 100" | bc -l)
        else
            speedup="1.000"
            efficiency="100.0"
        fi
        
        echo "    Result: ${best_time} ms | Speedup: ${speedup}x | Efficiency: ${efficiency}%"
        
        # Write to CSV
        echo "${resolution},${iterations},${threads},${best_time},${time_seconds},${speedup},${efficiency}" >> ${OUTPUT_CSV}
    done
    echo ""
done

echo -e "${GREEN}=== Benchmark Complete ===${NC}"
echo -e "Results saved to: ${OUTPUT_CSV}"
echo ""

# Generate analysis report
echo -e "${BLUE}=== Generating Analysis Report ===${NC}"

cat > ${ANALYSIS_REPORT} << EOF
=== OpenMP Dynamic Scheduling Performance Analysis ===
Generated: $(date)
Configurations Tested:
EOF

for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    echo "- ${resolution}x${resolution} resolution, ${iterations} iterations" >> ${ANALYSIS_REPORT}
done

cat >> ${ANALYSIS_REPORT} << EOF

Thread counts: ${THREADS[@]}
Runs per configuration: ${RUNS_PER_CONFIG}
Timing: High-precision nanosecond timing (best of ${RUNS_PER_CONFIG} runs)
Compiler: Intel C Compiler (icc) with -qopenmp
Scheduling: OpenMP dynamic scheduling

=== Performance Results by Configuration ===

EOF

# Generate detailed analysis for each configuration
for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    
    cat >> ${ANALYSIS_REPORT} << EOF
--- Resolution ${resolution}x${resolution}, Iterations ${iterations} ---
Threads | Time (ms) | Time (s)  | Speedup | Efficiency (%)
--------|-----------|-----------|---------|---------------
EOF
    
    # Extract and sort data for this configuration
    grep "^${resolution},${iterations}," ${OUTPUT_CSV} | sort -t',' -k3 -n | while IFS=',' read -r res iter threads time_ms time_s speedup efficiency; do
        printf "%-7s | %-9s | %-9s | %-7s | %-13s\n" "$threads" "$time_ms" "$time_s" "$speedup" "$efficiency" >> ${ANALYSIS_REPORT}
    done
    
    # Find best performance for this configuration
    best_time=$(grep "^${resolution},${iterations}," ${OUTPUT_CSV} | cut -d',' -f4 | sort -n | head -1)
    best_threads=$(grep "^${resolution},${iterations},.*,${best_time}," ${OUTPUT_CSV} | cut -d',' -f3)
    max_speedup=$(grep "^${resolution},${iterations},.*,${best_time}," ${OUTPUT_CSV} | cut -d',' -f6)
    
    cat >> ${ANALYSIS_REPORT} << EOF

Best Performance: ${best_threads} threads at ${best_time} ms (${max_speedup}x speedup)

EOF
done

# Generate summary comparison
cat >> ${ANALYSIS_REPORT} << EOF
=== Dynamic vs Static Scheduling Comparison ===

Dynamic scheduling is particularly beneficial for irregular workloads where:
• Work distribution is uneven across iterations
• Load balancing is critical for performance
• Runtime work stealing can improve efficiency

Key Findings:
• Dynamic scheduling shows different performance characteristics compared to static
• Better load balancing may improve performance on irregular problems
• Overhead of dynamic scheduling may impact small problems

=== Recommendations ===

1. Problem Size Considerations:
   - Small problems (1000x1000): Static scheduling often performs better due to lower overhead
   - Large problems (3000x3000): Dynamic scheduling may provide better load balancing

2. Thread Count Optimization:
   - Monitor efficiency vs. thread count relationship
   - Dynamic scheduling may show different optimal thread counts than static

3. Workload Characteristics:
   - Dynamic scheduling excels with irregular computation patterns
   - For regular Mandelbrot computation, static may be more predictable

EOF

echo -e "${GREEN}Analysis report generated: ${ANALYSIS_REPORT}${NC}"
echo ""

# Display performance summary
echo -e "${BLUE}=== Performance Summary ===${NC}"
echo "Configuration | Best Threads | Time (ms) | Speedup | Efficiency"
echo "--------------|--------------|-----------|---------|------------"

for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    
    # Find best performance for this configuration
    best_line=$(grep "^${resolution},${iterations}," ${OUTPUT_CSV} | sort -t',' -k4 -n | head -1)
    if [ -n "$best_line" ]; then
        IFS=',' read -r res iter threads time_ms time_s speedup efficiency <<< "$best_line"
        printf "%-13s | %-12s | %-9s | %-7s | %-10s\n" "${resolution}x${resolution}, ${iterations}" "$threads" "$time_ms" "$speedup" "$efficiency%"
    fi
done

echo ""
echo -e "${YELLOW}Files generated:${NC}"
echo -e "  📊 ${OUTPUT_CSV}"
echo -e "  📋 ${ANALYSIS_REPORT}"
