#!/bin/bash

# Script to benchmark Mandelbrot sequential program with -O2 flag
# Testing different resolutions and iterations combinations
# Results are written to a CSV file with resolution, iterations, and time elapsed

# Configuration
SOURCE_FILE="sequential/mandelbrot.cpp"
OUTPUT_CSV="resolution_iterations_benchmark.csv"
TEMP_SOURCE="sequential/mandelbrot_temp.cpp"
EXECUTABLE="mandelbrot_benchmark"
TEMP_OUTPUT="temp_output.csv"

# Test parameters
RESOLUTIONS=(1000 2000 3000)
ITERATIONS=(1000 2000 3000 4000 5000)

# Check if Intel compiler is available
if ! command -v icc &> /dev/null; then
    echo "Error: Intel C++ compiler (icc) not found!"
    echo "Please make sure Intel oneAPI is installed and sourced."
    exit 1
fi

echo "Mandelbrot Sequential Program - Resolution & Iterations Benchmarking"
echo "====================================================================="
echo "Testing resolutions: ${RESOLUTIONS[@]}"
echo "Testing iterations: ${ITERATIONS[@]}"
echo "Compiler: icc with -O2 flag"
echo "Output CSV: $OUTPUT_CSV"
echo ""

# Create CSV header
echo "Resolution,Iterations,Time_Elapsed_Seconds" > "$OUTPUT_CSV"

# Function to modify source file with new resolution and iterations
modify_source_file() {
    local resolution=$1
    local iterations=$2
    
    # Copy original source to temporary file
    cp "$SOURCE_FILE" "$TEMP_SOURCE"
    
    # Replace RESOLUTION and ITERATIONS defines
    sed -i "s/#define RESOLUTION [0-9]*/#define RESOLUTION $resolution/" "$TEMP_SOURCE"
    sed -i "s/#define ITERATIONS [0-9]*/#define ITERATIONS $iterations/" "$TEMP_SOURCE"
}

# Function to compile and run with specific resolution and iterations
benchmark_combination() {
    local resolution=$1
    local iterations=$2
    
    echo "Testing Resolution: $resolution, Iterations: $iterations"
    
    # Modify source file
    modify_source_file "$resolution" "$iterations"
    
    # Compile with -O2 flag
    echo "  Compiling..."
    if icc -O2 -o "$EXECUTABLE" "$TEMP_SOURCE"; then
        echo "  Compilation successful"
        
        # Run the program and capture output
        echo "  Running..."
        if ./"$EXECUTABLE" "$TEMP_OUTPUT" 2>&1 | tee run_output.tmp; then
            # Extract time from the output
            TIME_ELAPSED=$(grep "Time elapsed:" run_output.tmp | awk '{print $3}')
            
            if [ -n "$TIME_ELAPSED" ]; then
                echo "  Time elapsed: $TIME_ELAPSED seconds"
                # Write result to CSV
                echo "$resolution,$iterations,$TIME_ELAPSED" >> "$OUTPUT_CSV"
                echo "  ✓ Result recorded"
            else
                echo "  ✗ Could not extract time from output"
                echo "$resolution,$iterations,ERROR" >> "$OUTPUT_CSV"
            fi
        else
            echo "  ✗ Execution failed"
            echo "$resolution,$iterations,EXEC_ERROR" >> "$OUTPUT_CSV"
        fi
        
        # Clean up executable
        rm -f "$EXECUTABLE"
    else
        echo "  ✗ Compilation failed"
        echo "$resolution,$iterations,COMPILE_ERROR" >> "$OUTPUT_CSV"
    fi
    
    # Clean up temporary files
    rm -f "$TEMP_OUTPUT" run_output.tmp
    echo ""
}

# Change to the mandelbrot_alg directory
cd "$(dirname "$0")"

# Run benchmarks for each combination
echo "Starting benchmarks..."
echo ""

total_tests=$((${#RESOLUTIONS[@]} * ${#ITERATIONS[@]}))
current_test=0

for resolution in "${RESOLUTIONS[@]}"; do
    for iterations in "${ITERATIONS[@]}"; do
        current_test=$((current_test + 1))
        echo "Progress: $current_test/$total_tests"
        benchmark_combination "$resolution" "$iterations"
    done
done

# Clean up temporary source file
rm -f "$TEMP_SOURCE"

echo "Benchmarking completed!"
echo "Results saved to: $OUTPUT_CSV"
echo ""
echo "Summary of results:"
echo "==================="
cat "$OUTPUT_CSV"

# Generate a summary report
echo ""
echo "Performance Analysis:"
echo "===================="
echo "Resolution | Iterations | Time (seconds)"
echo "-----------|------------|---------------"

# Skip header and show results
tail -n +2 "$OUTPUT_CSV" | while IFS=',' read -r resolution iterations time; do
    if [[ "$time" =~ ^[0-9]+$ ]]; then
        printf "%-10s | %-10s | %s\n" "$resolution" "$iterations" "$time"
    else
        printf "%-10s | %-10s | %s\n" "$resolution" "$iterations" "$time"
    fi
done

echo ""
echo "Performance insights:"
echo "- Higher resolutions will significantly increase computation time"
echo "- Higher iterations will also increase computation time"
echo "- The relationship between parameters and time should be roughly: Time ∝ Resolution² × Iterations"

# Find fastest and slowest valid results
echo ""
fastest=$(tail -n +2 "$OUTPUT_CSV" | grep -v "ERROR" | sort -t',' -k3 -n | head -1)
slowest=$(tail -n +2 "$OUTPUT_CSV" | grep -v "ERROR" | sort -t',' -k3 -nr | head -1)

if [ -n "$fastest" ]; then
    echo "Fastest combination: $fastest"
fi
if [ -n "$slowest" ]; then
    echo "Slowest combination: $slowest"
fi
