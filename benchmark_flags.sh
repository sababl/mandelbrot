#!/bin/bash

# Script to benchmark Mandelbrot sequential program with different Intel compiler flags
# Results are written to a CSV file with flag, resolution, iterations, and time elapsed

# Configuration
SOURCE_FILE="sequential/mandelbrot.cpp"
OUTPUT_CSV="flag_benchmark_results.csv"
IMAGES_DIR="report/images"

# Compiler flags to test
FLAGS=("-O0" "-O1" "-O2" "-O3" "-xhost" "-fast" "-xSSE3")

# Check if Intel compiler is available
if ! command -v icpx &> /dev/null; then
    echo "Error: Intel C++ compiler (icpx) not found!"
    echo "Please make sure Intel oneAPI is installed and sourced."
    exit 1
fi

# Function to extract values from the source file
extract_resolution() {
    grep "#define RESOLUTION" $SOURCE_FILE | awk '{print $3}'
}

extract_iterations() {
    grep "#define ITERATIONS" $SOURCE_FILE | awk '{print $3}'
}

# Get resolution and iterations from source
RESOLUTION=$(extract_resolution)
ITERATIONS=$(extract_iterations)

echo "Mandelbrot Sequential Program Benchmarking"
echo "=========================================="
echo "Resolution: $RESOLUTION"
echo "Iterations: $ITERATIONS"
echo "Source file: $SOURCE_FILE"
echo "Output CSV: $OUTPUT_CSV"
echo "Images directory: $IMAGES_DIR"
echo ""

# Create images directory if it doesn't exist
mkdir -p "$IMAGES_DIR"

# Create CSV header
echo "Flag,Resolution,Iterations,Time_Elapsed_Seconds" > $OUTPUT_CSV

# Function to compile and run with a specific flag
benchmark_flag() {
    local flag=$1
    local executable="mandelbrot_${flag#-}"  # Remove leading dash for filename
    local flag_clean="${flag//[^a-zA-Z0-9]/_}"  # Replace special chars for filename
    local image_output="$IMAGES_DIR/mandelbrot_${flag_clean}.csv"
    
    echo "Testing flag: $flag"
    
    # Compile with the specific flag
    echo "  Compiling..."
    if icpx $flag -o $executable $SOURCE_FILE; then
        echo "  Compilation successful"
        
        # Run the program and capture output
        echo "  Running..."
        if ./$executable "$image_output" 2>&1 | tee run_output.tmp; then
            # Extract time from the output
            TIME_ELAPSED=$(grep "Time elapsed:" run_output.tmp | awk '{print $3}')
            
            if [ -n "$TIME_ELAPSED" ]; then
                echo "  Time elapsed: $TIME_ELAPSED seconds"
                echo "  Image saved to: $image_output"
                # Write result to CSV
                echo "$flag,$RESOLUTION,$ITERATIONS,$TIME_ELAPSED" >> $OUTPUT_CSV
                echo "  ✓ Result recorded"
            else
                echo "  ✗ Could not extract time from output"
                echo "$flag,$RESOLUTION,$ITERATIONS,ERROR" >> $OUTPUT_CSV
                # Remove image file if there was an error
                rm -f "$image_output"
            fi
        else
            echo "  ✗ Execution failed"
            echo "$flag,$RESOLUTION,$ITERATIONS,EXEC_ERROR" >> $OUTPUT_CSV
            # Remove image file if there was an error
            rm -f "$image_output"
        fi
        
        # Clean up executable
        rm -f $executable
    else
        echo "  ✗ Compilation failed"
        echo "$flag,$RESOLUTION,$ITERATIONS,COMPILE_ERROR" >> $OUTPUT_CSV
    fi
    
    # Clean up temporary files
    rm -f run_output.tmp
    echo ""
}

# Change to the mandelbrot_alg directory
cd "$(dirname "$0")"

# Run benchmarks for each flag
echo "Starting benchmarks..."
echo ""

for flag in "${FLAGS[@]}"; do
    benchmark_flag "$flag"
done

echo "Benchmarking completed!"
echo "Results saved to: $OUTPUT_CSV"
echo ""
echo "Summary of results:"
echo "==================="
cat $OUTPUT_CSV

# Generate a summary report
echo ""
echo "Performance Summary:"
echo "==================="
echo "Flag                 | Time (seconds)"
echo "---------------------|---------------"

# Skip header and show results
tail -n +2 $OUTPUT_CSV | while IFS=',' read -r flag resolution iterations time; do
    if [[ "$time" =~ ^[0-9]+$ ]]; then
        printf "%-20s | %s\n" "$flag" "$time"
    else
        printf "%-20s | %s\n" "$flag" "$time"
    fi
done

echo ""
echo "Best performing flag:"
# Find the flag with minimum time (excluding errors)
tail -n +2 $OUTPUT_CSV | grep -v "ERROR" | sort -t',' -k4 -n | head -1 | while IFS=',' read -r flag resolution iterations time; do
    echo "  $flag with $time seconds"
done

echo ""
echo "Generated Images:"
echo "================="
if [ -d "$IMAGES_DIR" ]; then
    for image in "$IMAGES_DIR"/*.csv; do
        if [ -f "$image" ]; then
            filename=$(basename "$image")
            size=$(wc -l < "$image")
            echo "  $filename ($size lines)"
        fi
    done
else
    echo "  No images directory found"
fi
