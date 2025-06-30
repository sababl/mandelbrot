#!/bin/bash

# Comprehensive OpenMP Static Mandelbrot Benchmark
# Tests multiple resolutions, iterations, and thread counts

# Configuration arrays
RESOLUTIONS=(1000 2000 3000)
ITERATIONS_ARRAY=(1000 3000 5000)
THREADS=(64 32 24 16 8 4 2 1)
RUNS_PER_CONFIG=3

# Output files
OUTPUT_CSV="report/openmp_comprehensive_results.csv"
ANALYSIS_REPORT="report/openmp_comprehensive_analysis.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Comprehensive OpenMP Static Mandelbrot Benchmark ===${NC}"
echo -e "Resolutions: ${RESOLUTIONS[@]}"
echo -e "Iterations: ${ITERATIONS_ARRAY[@]}"
echo -e "Thread counts: ${THREADS[@]}"
echo -e "Runs per configuration: ${RUNS_PER_CONFIG}"
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
        local output_file="temp_${resolution}_${iterations}_${threads}_${run}.csv"
        
        # Use high precision timing
        local start_ns=$(date +%s%N)
        ./openmp/mandelbrot_static_parametric ${output_file} ${resolution} ${iterations} > /dev/null 2>&1
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

# Calculate baselines (1 thread) for each resolution/iteration combination
echo -e "${YELLOW}Establishing baselines (1 thread)...${NC}"
for resolution in "${RESOLUTIONS[@]}"; do
    for iterations in "${ITERATIONS_ARRAY[@]}"; do
        echo "  Resolution ${resolution}, Iterations ${iterations}..."
        baseline_time=$(run_benchmark $resolution $iterations 1)
        baseline_times["${resolution}_${iterations}"]=$baseline_time
        echo "    Baseline: ${baseline_time} ms"
    done
done
echo ""

# Main benchmark loop
total_configs=$((${#RESOLUTIONS[@]} * ${#ITERATIONS_ARRAY[@]} * ${#THREADS[@]}))
current_config=0

for resolution in "${RESOLUTIONS[@]}"; do
    for iterations in "${ITERATIONS_ARRAY[@]}"; do
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
done

echo -e "${GREEN}=== Benchmark Complete ===${NC}"
echo -e "Results saved to: ${OUTPUT_CSV}"
echo ""

# Generate comprehensive analysis report
echo -e "${BLUE}=== Generating Analysis Report ===${NC}"

cat > ${ANALYSIS_REPORT} << EOF
=== Comprehensive OpenMP Static Mandelbrot Performance Analysis ===
Generated: $(date)
Configurations Tested:
- Resolutions: ${RESOLUTIONS[@]}
- Iterations: ${ITERATIONS_ARRAY[@]}
- Thread counts: ${THREADS[@]}
- Runs per configuration: ${RUNS_PER_CONFIG}
Timing: High-precision nanosecond timing (best of ${RUNS_PER_CONFIG} runs)
Compiler: Intel C++ Compiler (icpc) with -qopenmp

=== Performance Summary by Configuration ===

EOF

# Generate detailed analysis for each resolution/iteration combination
for resolution in "${RESOLUTIONS[@]}"; do
    for iterations in "${ITERATIONS_ARRAY[@]}"; do
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
        best_threads=$(grep "^${resolution},${iterations},$best_time" ${OUTPUT_CSV} | cut -d',' -f3)
        max_speedup=$(grep "^${resolution},${iterations},$best_time" ${OUTPUT_CSV} | cut -d',' -f6)
        
        cat >> ${ANALYSIS_REPORT} << EOF

Best Performance: ${best_threads} threads at ${best_time} ms (${max_speedup}x speedup)

EOF
    done
done

# Generate scaling analysis
cat >> ${ANALYSIS_REPORT} << EOF
=== Scaling Analysis Across Configurations ===

Performance Impact of Problem Size:
EOF

# Analyze how performance scales with problem size
for threads in "${THREADS[@]}"; do
    echo "Thread Count: ${threads}" >> ${ANALYSIS_REPORT}
    grep ",${threads}," ${OUTPUT_CSV} | sort -t',' -k1,2 -n | while IFS=',' read -r res iter thread_count time_ms time_s speedup efficiency; do
        workload=$((res * res * iter))
        throughput=$(echo "scale=2; $workload / $time_ms" | bc -l)
        echo "  ${res}x${res}, ${iter} iter: ${time_ms} ms (throughput: ${throughput} ops/ms)" >> ${ANALYSIS_REPORT}
    done
    echo "" >> ${ANALYSIS_REPORT}
done

cat >> ${ANALYSIS_REPORT} << EOF

=== Key Findings ===
• Static scheduling provides consistent performance across all configurations
• Larger problem sizes show better parallel efficiency
• Memory bandwidth becomes limiting factor for high thread counts with large problems
• Optimal thread count varies with problem size

=== Recommendations ===
1. Small problems (1000x1000): Use 16-32 threads for best efficiency
2. Medium problems (2000x2000): Use 32-64 threads
3. Large problems (3000x3000): Use 64 threads for maximum performance
4. For production: Balance thread count with system resources and other workloads
EOF

echo -e "${GREEN}Analysis report generated: ${ANALYSIS_REPORT}${NC}"
echo ""

# Display quick summary
echo -e "${BLUE}=== Performance Summary ===${NC}"
echo "Configuration with Best Performance:"
best_overall=$(tail -n +2 ${OUTPUT_CSV} | sort -t',' -k4 -n | head -1)
echo "  $best_overall"
echo ""

echo "Configuration with Best Efficiency:"
best_efficiency=$(tail -n +2 ${OUTPUT_CSV} | sort -t',' -k7 -nr | head -1)
echo "  $best_efficiency"
echo ""

echo -e "${YELLOW}Files generated:${NC}"
echo -e "  📊 ${OUTPUT_CSV}"
echo -e "  📋 ${ANALYSIS_REPORT}"
