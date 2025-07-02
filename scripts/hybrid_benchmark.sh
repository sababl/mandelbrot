#!/bin/bash

# Comprehensive Hybrid OpenMP+MPI Mandelbrot Benchmark Script
# Tests performance with different process and thread combinations

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
SOURCE_FILE="mpi/hybrid_openmp_mpi_mandelbrot.cpp"
EXECUTABLE="mpi/hybrid_openmp_mpi_mandelbrot"
OUTPUT_CSV="report/hybrid_performance_results.csv"
ANALYSIS_REPORT="report/hybrid_performance_analysis.txt"

# Test configurations - matching previous studies for comparison
CONFIGS=(
    "1000 1000"   # 1000x1000, 1000 iterations
    "2000 1000"   # 2000x2000, 1000 iterations  
    "3000 1000"   # 3000x3000, 1000 iterations
    "1000 3000"   # 1000x1000, 3000 iterations
    "1000 5000"   # 1000x1000, 5000 iterations
)

# Hybrid configurations: [processes, threads_per_process]
# Targeting specific total thread counts for comparison
HYBRID_CONFIGS=(
    "1 1"    # 1 total (baseline)
    "1 2"    # 2 total
    "2 2"    # 4 total
    "1 8"    # 8 total
    "2 8"    # 16 total
    "4 8"    # 32 total
    "8 8"    # 64 total
    "2 16"   # 32 total (alternative)
    "4 16"   # 64 total (alternative)
    "8 16"   # 128 total
)

RUNS_PER_CONFIG=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Hybrid OpenMP+MPI Mandelbrot Performance Benchmark ===${NC}"
echo -e "Configurations:"
for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    echo -e "  Resolution ${resolution}x${resolution}, Iterations ${iterations}"
done
echo -e "Hybrid configurations (processes x threads):"
for config in "${HYBRID_CONFIGS[@]}"; do
    processes=${config%% *}
    threads=${config##* }
    total=$((processes * threads))
    echo -e "  ${processes} processes × ${threads} threads = ${total} total"
done
echo -e "Runs per configuration: ${RUNS_PER_CONFIG}"
echo -e "Compiler: Intel C++ (icc) via Intel MPI with OpenMP"
echo -e "Results: ${OUTPUT_CSV}"
echo -e "Analysis: ${ANALYSIS_REPORT}"
echo ""

# Create report directory if it doesn't exist
mkdir -p report

# Compile the hybrid program with Intel compiler
echo -e "${YELLOW}Compiling hybrid OpenMP+MPI program with Intel compiler...${NC}"
if I_MPI_CXX=icc mpicxx -O2 -qopenmp -o "${EXECUTABLE}" "${SOURCE_FILE}" 2>/dev/null || \
   I_MPI_CXX=icc mpicxx -O2 -fopenmp -o "${EXECUTABLE}" "${SOURCE_FILE}"; then
    echo -e "${GREEN}Compilation successful with Intel icc + OpenMP${NC}"
else
    echo -e "${RED}Compilation failed${NC}"
    exit 1
fi

# Create CSV header
echo "configuration,resolution,iterations,processes,threads_per_process,total_threads,execution_time_ms,execution_time_seconds,speedup,efficiency_percent" > "${OUTPUT_CSV}"

# Store baseline times for speedup calculations
declare -A baseline_times

# Function to run benchmark for a specific configuration
run_benchmark() {
    local resolution=$1
    local iterations=$2
    local processes=$3
    local threads=$4
    
    # Run multiple times and take the best result
    local best_time=""
    for run in $(seq 1 ${RUNS_PER_CONFIG}); do
        local output_file="temp_hybrid_${resolution}_${iterations}_${processes}_${threads}_${run}.csv"
        
        # Run the hybrid program and capture timing output
        local hybrid_output=$(mpirun -np ${processes} ./${EXECUTABLE} ${output_file} ${resolution} ${iterations} ${threads} 2>&1)
        
        # Extract execution time from output
        local time_ms=$(echo "$hybrid_output" | grep "Execution time:" | awk '{print $3}')
        
        if [ -n "$time_ms" ] && [ $(echo "$time_ms > 0" | bc -l) -eq 1 ]; then
            if [ -z "$best_time" ] || [ $(echo "$time_ms < $best_time" | bc -l) -eq 1 ]; then
                best_time=$time_ms
            fi
        fi
        
        rm -f ${output_file}
    done
    
    echo $best_time
}

# Calculate baselines (1 process, 1 thread) for each configuration
echo -e "${YELLOW}Establishing baselines (1 process, 1 thread)...${NC}"
for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    
    echo -n "  Baseline for ${resolution}x${resolution}, ${iterations} iter: "
    baseline_time=$(run_benchmark ${resolution} ${iterations} 1 1)
    baseline_times["${resolution}_${iterations}"]=$baseline_time
    echo "${baseline_time} ms"
done
echo ""

# Main benchmark loop
total_configs=$((${#CONFIGS[@]} * ${#HYBRID_CONFIGS[@]}))
current_config=0

for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    baseline_time=${baseline_times["${resolution}_${iterations}"]}
    
    echo -e "${GREEN}Configuration: ${resolution}x${resolution}, ${iterations} iterations${NC}"
    echo "  Baseline (1 process, 1 thread): ${baseline_time} ms"
    
    for hybrid_config in "${HYBRID_CONFIGS[@]}"; do
        processes=${hybrid_config%% *}
        threads=${hybrid_config##* }
        total_threads=$((processes * threads))
        
        current_config=$((current_config + 1))
        progress=$((current_config * 100 / total_configs))
        
        echo -n "  [${progress}%] Testing ${processes}p × ${threads}t (${total_threads} total): "
        
        if [ ${processes} -eq 1 ] && [ ${threads} -eq 1 ]; then
            # Use baseline time for 1 process, 1 thread
            best_time=$baseline_time
        else
            # Run benchmark for this configuration
            best_time=$(run_benchmark ${resolution} ${iterations} ${processes} ${threads})
        fi
        
        if [ -n "$best_time" ] && [ $(echo "$best_time > 0" | bc -l) -eq 1 ]; then
            # Calculate metrics
            time_seconds=$(echo "scale=6; $best_time / 1000" | bc -l)
            speedup=$(echo "scale=3; $baseline_time / $best_time" | bc -l)
            efficiency=$(echo "scale=1; $speedup * 100 / $total_threads" | bc -l)
            
            # Write to CSV
            echo "${resolution}x${resolution}_${iterations},${resolution},${iterations},${processes},${threads},${total_threads},${best_time},${time_seconds},${speedup},${efficiency}" >> "${OUTPUT_CSV}"
            
            echo "Best time: ${best_time} ms, Speedup: ${speedup}x, Efficiency: ${efficiency}%"
        else
            echo -e "${RED}Failed${NC}"
            echo "${resolution}x${resolution}_${iterations},${resolution},${iterations},${processes},${threads},${total_threads},ERROR,ERROR,ERROR,ERROR" >> "${OUTPUT_CSV}"
        fi
    done
    echo ""
done

# Generate analysis report
echo -e "${YELLOW}Generating analysis report...${NC}"

cat > "${ANALYSIS_REPORT}" << 'EOF'
# Hybrid OpenMP+MPI Mandelbrot Performance Analysis

## Executive Summary

This analysis evaluates hybrid OpenMP+MPI performance for Mandelbrot set computation, 
combining distributed memory parallelization (MPI) with shared memory parallelization 
(OpenMP) to achieve optimal scaling across different system configurations.

## Methodology

- **Parallelization**: Hybrid MPI (inter-node) + OpenMP (intra-node) approach
- **Compiler**: Intel C++ Compiler (icc) with Intel MPI and OpenMP support
- **Threading**: MPI_THREAD_FUNNELED support for thread safety
- **Timing**: High-precision millisecond measurement (best of 3 runs)
- **Scheduling**: OpenMP guided scheduling for optimal load balancing

## Hybrid Configuration Strategy

The hybrid approach divides work hierarchically:
1. **MPI level**: Distributes pixels across processes (nodes/cores)
2. **OpenMP level**: Parallelizes assigned pixels within each process using guided scheduling
3. **Communication**: Single MPI_Gatherv at completion (minimal overhead)

## Test Configurations

EOF

echo -e "${GREEN}Benchmark completed!${NC}"
echo -e "Results saved to: ${OUTPUT_CSV}"
echo -e "Analysis saved to: ${ANALYSIS_REPORT}"

# Clean up
rm -f temp_hybrid_*
