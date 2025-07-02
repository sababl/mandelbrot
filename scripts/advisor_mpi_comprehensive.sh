#!/bin/bash

# Intel Advisor Comprehensive MPI Analysis Script
# Analyzes both pure MPI and hybrid OpenMP+MPI implementations

set -e

echo "======================================================================"
echo "Intel Advisor Comprehensive MPI Analysis"
echo "======================================================================"

# Setup Intel oneAPI environment (check if already loaded)
if [ -z "$ONEAPI_ROOT" ]; then
    echo "Loading Intel oneAPI environment..."
    source /opt/intel/oneapi/setvars.sh intel64
else
    echo "Intel oneAPI environment already loaded."
fi

# Define directories
PROJECT_DIR="/home/stud/S5843444/mandelbrot"
MPI_DIR="${PROJECT_DIR}/mpi"
ADVISOR_RESULTS_DIR="${PROJECT_DIR}/advisor_results"
REPORT_DIR="${PROJECT_DIR}/report"
MPI_ADVISOR_DIR="${ADVISOR_RESULTS_DIR}/mpi_analysis"

# Create directories
mkdir -p "${MPI_ADVISOR_DIR}"
mkdir -p "${REPORT_DIR}/mpi_advisor_analysis"

echo "Project Directory: ${PROJECT_DIR}"
echo "MPI Executables Directory: ${MPI_DIR}"
echo "Advisor Results Directory: ${MPI_ADVISOR_DIR}"
echo "Report Directory: ${REPORT_DIR}/mpi_advisor_analysis"

# Analysis parameters
RESOLUTION=1000
ITERATIONS=1000
PROCESSES=4
THREADS_PER_PROC=2
OUTPUT_FILE="advisor_mpi_output.csv"

echo ""
echo "Analysis Parameters:"
echo "  Resolution: ${RESOLUTION}x${RESOLUTION}"
echo "  Iterations: ${ITERATIONS}"
echo "  MPI Processes: ${PROCESSES}"
echo "  OpenMP Threads per Process (hybrid): ${THREADS_PER_PROC}"

# Function to run Intel Advisor analysis
run_advisor_analysis() {
    local exe_name=$1
    local analysis_name=$2
    local mpi_command=$3
    local result_dir="${MPI_ADVISOR_DIR}/${analysis_name}"
    
    echo ""
    echo "======================================================================"
    echo "Analyzing: ${analysis_name} (${exe_name})"
    echo "======================================================================"
    
    # Clean previous results
    if [ -d "${result_dir}" ]; then
        echo "Cleaning previous results for ${analysis_name}..."
        rm -rf "${result_dir}"
    fi
    
    mkdir -p "${result_dir}"
    cd "${result_dir}"
    
    echo "Running in directory: $(pwd)"
    echo "MPI Command: ${mpi_command}"
    
    # Create advisor project
    echo "Creating Intel Advisor project..."
    advisor --create-project --project-dir="${result_dir}"
    
    # Survey Analysis (Hotspot detection)
    echo ""
    echo "Running Survey Analysis (Hotspot Detection)..."
    echo "Command: advisor --collect=survey --project-dir='${result_dir}' -- ${mpi_command}"
    
    advisor --collect=survey \
            --project-dir="${result_dir}" \
             -- ${mpi_command}
    
    if [ $? -eq 0 ]; then
        echo "Survey analysis completed successfully for ${analysis_name}"
    else
        echo "Warning: Survey analysis had issues for ${analysis_name}"
    fi
    
    # Roofline Analysis (Memory and compute performance)
    echo ""
    echo "Running Roofline Analysis (Memory & Compute Performance)..."
    echo "Command: advisor --collect=roofline --project-dir='${result_dir}' -- ${mpi_command}"
    
    advisor --collect=roofline \
            --project-dir="${result_dir}" \
             -- ${mpi_command}
    
    if [ $? -eq 0 ]; then
        echo "Roofline analysis completed successfully for ${analysis_name}"
    else
        echo "Warning: Roofline analysis had issues for ${analysis_name}"
    fi
    
    # Generate text reports
    echo ""
    echo "Generating text reports for ${analysis_name}..."
    
    # Survey report
    echo "Generating survey report..."
    advisor --report=survey \
            --project-dir="${result_dir}" \
            --format=text \
            --report-output="${REPORT_DIR}/mpi_advisor_analysis/${analysis_name}_survey.txt"
    
    # Roofline report  
    echo "Generating roofline report..."
    advisor --report=roofline \
            --project-dir="${result_dir}" \
            --report-output="${REPORT_DIR}/mpi_advisor_analysis/${analysis_name}_roofline_report.html"

    # Generate performance summary
    echo "Generating performance summary..."
    advisor --report=summary \
            --project-dir="${result_dir}" \
            --format=text \
            --report-output="${REPORT_DIR}/mpi_advisor_analysis/${analysis_name}_summary.txt"
    
    echo "Analysis completed for ${analysis_name}"
    echo "Results stored in: ${result_dir}"
    echo "Reports generated in: ${REPORT_DIR}/mpi_advisor_analysis/"
}

# Ensure we're in the MPI directory
cd "${MPI_DIR}"

echo ""
echo "======================================================================"
echo "Starting Intel Advisor MPI Analysis"
echo "======================================================================"

# Analysis 1: Pure MPI Implementation
echo ""
echo "ANALYSIS 1: Pure MPI Implementation"
echo "====================================="

MPI_CMD="mpirun -np ${PROCESSES} ${MPI_DIR}/mpi_mandelbrot_parametric ${OUTPUT_FILE} ${RESOLUTION} ${ITERATIONS}"
run_advisor_analysis "mpi_mandelbrot_parametric" "mpi_pure_p${PROCESSES}" "${MPI_CMD}"

# Analysis 2: Hybrid OpenMP+MPI Implementation  
echo ""
echo "ANALYSIS 2: Hybrid OpenMP+MPI Implementation"
echo "============================================="

HYBRID_CMD="mpirun -np ${PROCESSES} ${MPI_DIR}/hybrid_openmp_mpi_mandelbrot ${OUTPUT_FILE} ${RESOLUTION} ${ITERATIONS} ${THREADS_PER_PROC}"
run_advisor_analysis "hybrid_openmp_mpi_mandelbrot" "hybrid_p${PROCESSES}_t${THREADS_PER_PROC}" "${HYBRID_CMD}"

# Generate comprehensive comparison report
echo ""
echo "======================================================================"
echo "Generating Comprehensive MPI Analysis Report"
echo "======================================================================"

COMPREHENSIVE_REPORT="${REPORT_DIR}/mpi_advisor_analysis/comprehensive_mpi_advisor_analysis.md"

cat > "${COMPREHENSIVE_REPORT}" << 'EOF'
# Intel Advisor Comprehensive MPI Analysis Report

## Overview

This report presents a comprehensive Intel Advisor analysis of MPI implementations for the Mandelbrot set computation, comparing pure MPI vs hybrid OpenMP+MPI approaches.

## Analysis Configurations

### Pure MPI Implementation
- **Executable**: `mpi_mandelbrot_parametric`
- **Processes**: 4
- **Threading**: Single-threaded per process
- **Total Cores**: 4

### Hybrid OpenMP+MPI Implementation  
- **Executable**: `hybrid_openmp_mpi_mandelbrot`
- **MPI Processes**: 4
- **OpenMP Threads per Process**: 2
- **Total Cores**: 8 (4 processes × 2 threads)

### Common Parameters
- **Resolution**: 1000×1000
- **Iterations**: 1000
- **Domain**: Complex plane [-2.0, 1.0] × [-1.0, 1.0]

## Intel Advisor Analysis Types

### 1. Survey Analysis (Hotspot Detection)
- Identifies performance bottlenecks
- Analyzes function-level timing
- Detects threading opportunities
- Provides call tree analysis

### 2. Roofline Analysis (Memory & Compute Performance)
- Memory bandwidth utilization
- Computational intensity analysis
- Performance ceiling identification
- Cache hierarchy effects

### 3. Performance Summary
- Overall execution metrics
- Resource utilization analysis
- Scalability indicators

## Analysis Results

### Pure MPI Performance Characteristics

**Expected Findings:**
- Communication overhead analysis
- Memory distribution patterns
- Process synchronization costs
- Inter-process communication efficiency

### Hybrid OpenMP+MPI Performance Characteristics

**Expected Findings:**
- Multi-level parallelism efficiency
- Memory access patterns with nested parallelism
- Thread vs process overhead comparison
- NUMA effects and locality optimization

## Key Performance Metrics to Analyze

### Computational Metrics
- **GFLOPS**: Floating-point operations per second
- **Computational Intensity**: Operations per byte
- **Cache Performance**: Hit ratios and bandwidth
- **Memory Bandwidth**: Effective vs theoretical

### Parallelization Metrics
- **Load Balancing**: Work distribution efficiency
- **Communication Overhead**: MPI synchronization costs
- **Threading Efficiency**: OpenMP overhead analysis
- **Scalability**: Performance per core utilization

## Comparison Framework

### Performance Efficiency
- Pure MPI: Single-level parallelism efficiency
- Hybrid: Multi-level parallelism trade-offs

### Memory Performance  
- Pure MPI: Distributed memory access patterns
- Hybrid: Shared+distributed memory hierarchy

### Synchronization Overhead
- Pure MPI: Inter-process communication
- Hybrid: Thread synchronization + MPI communication

## Intel Advisor GUI Access

### View Pure MPI Analysis
```bash
advisor-gui /home/stud/S5843444/mandelbrot/advisor_results/mpi_analysis/mpi_pure_p4
```

### View Hybrid Analysis
```bash
advisor-gui /home/stud/S5843444/mandelbrot/advisor_results/mpi_analysis/hybrid_p4_t2
```

## Generated Reports

1. **Survey Reports**: `*_survey.txt` - Hotspot and timing analysis
2. **Roofline Reports**: `*_roofline_report.html` - Memory and compute performance
3. **Summary Reports**: `*_summary.txt` - Overall performance metrics

## Research Insights

This Intel Advisor analysis provides scientific validation for:

1. **MPI Communication Efficiency**: Quantifying inter-process overhead
2. **Hybrid Parallelism Benefits**: Multi-level parallelism effectiveness  
3. **Memory Access Optimization**: NUMA and cache performance
4. **Scalability Patterns**: Core utilization efficiency

## Recommendations

Based on Intel Advisor analysis:

1. **Memory Optimization**: Focus on cache-friendly data layouts
2. **Communication Reduction**: Minimize MPI synchronization points
3. **Load Balancing**: Optimize work distribution across processes/threads
4. **NUMA Awareness**: Consider processor topology in thread placement

---

*Generated by Intel Advisor Comprehensive MPI Analysis*
*Analysis Date: $(date)*
*System: $(hostname)*
EOF

echo "Comprehensive analysis report generated: ${COMPREHENSIVE_REPORT}"

# Generate execution summary
echo ""
echo "======================================================================"
echo "Intel Advisor MPI Analysis Summary"
echo "======================================================================"
echo ""
echo "Analysis completed successfully!"
echo ""
echo "Generated Advisor Projects:"
echo "  1. Pure MPI (4 processes): ${MPI_ADVISOR_DIR}/mpi_pure_p4"
echo "  2. Hybrid MPI+OpenMP (4×2): ${MPI_ADVISOR_DIR}/hybrid_p4_t2"
echo ""
echo "Generated Reports:"
echo "  - Survey reports: ${REPORT_DIR}/mpi_advisor_analysis/*_survey.txt"
echo "  - Roofline reports: ${REPORT_DIR}/mpi_advisor_analysis/*_roofline_report.html"
echo "  - Summary reports: ${REPORT_DIR}/mpi_advisor_analysis/*_summary.txt"
echo "  - Comprehensive analysis: ${COMPREHENSIVE_REPORT}"
echo ""
echo "GUI Access Commands:"
echo "  advisor-gui ${MPI_ADVISOR_DIR}/mpi_pure_p4"
echo "  advisor-gui ${MPI_ADVISOR_DIR}/hybrid_p4_t2"
echo ""
echo "Next Steps:"
echo "  1. Review generated reports for performance insights"
echo "  2. Use GUI for interactive analysis"
echo "  3. Compare MPI vs Hybrid performance characteristics"
echo "  4. Analyze memory access patterns and communication overhead"
echo ""
echo "Intel Advisor MPI analysis completed successfully!"
echo "======================================================================"
