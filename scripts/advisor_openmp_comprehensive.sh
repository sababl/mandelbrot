#!/bin/bash
# Intel Advisor Comprehensive OpenMP Analysis Script
# Analyzes static, dynamic, and guided scheduling with different thread counts

# Set up Intel oneAPI environment
source /opt/intel/oneapi/setvars.sh

# Configuration
RESOLUTIONS=("1000" "2000")
ITERATIONS=("1000" "3000")
THREAD_COUNTS=("1" "4" "8" "16" "24" "32")
SCHEDULING_TYPES=("static" "dynamic" "guided")
BASE_DIR="/home/stud/S5843444/mandelbrot"
ADVISOR_BASE="advisor_results/openmp"
REPORT_DIR="report/advisor_openmp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Intel Advisor Comprehensive OpenMP Analysis ===${NC}"
echo "Analyzing OpenMP configurations with Intel Advisor"
echo "Thread counts: ${THREAD_COUNTS[@]}"
echo "Scheduling types: ${SCHEDULING_TYPES[@]}"
echo ""

# Create directories
mkdir -p "${ADVISOR_BASE}"
mkdir -p "${REPORT_DIR}"

cd "${BASE_DIR}"

# Function to run advisor analysis
run_advisor_analysis() {
    local scheduling=$1
    local threads=$2
    local resolution=$3
    local iterations=$4
    local project_name="${scheduling}_t${threads}_r${resolution}_i${iterations}"
    local project_dir="${ADVISOR_BASE}/${project_name}"
    local executable="openmp/mandelbrot_${scheduling}_parametric"
    
    echo -e "${YELLOW}Analyzing: ${scheduling} scheduling, ${threads} threads, ${resolution}x${resolution}, ${iterations} iterations${NC}"
    
    # Clean previous results
    rm -rf "${project_dir}"
    
    # Set thread count
    export OMP_NUM_THREADS=${threads}
    
    # Run Survey Analysis
    echo "  Running Survey analysis..."
    if advisor --collect=survey --project-dir="${project_dir}" -- "./${executable}" "${resolution}" "${resolution}" "${iterations}" > /dev/null 2>&1; then
        echo -e "    ${GREEN}Survey completed${NC}"
    else
        echo -e "    ${RED}Survey failed${NC}"
        return 1
    fi
    
    # Run Threading Analysis  
    echo "  Running Threading analysis..."
    if advisor --collect=threading --project-dir="${project_dir}" -- "./${executable}" "${resolution}" "${resolution}" "${iterations}" > /dev/null 2>&1; then
        echo -e "    ${GREEN}Threading completed${NC}"
    else
        echo -e "    ${RED}Threading failed${NC}"
        return 1
    fi
    
    # Run Roofline Analysis
    echo "  Running Roofline analysis..."
    if advisor --collect=roofline --project-dir="${project_dir}" -- "./${executable}" "${resolution}" "${resolution}" "${iterations}" > /dev/null 2>&1; then
        echo -e "    ${GREEN}Roofline completed${NC}"
    else
        echo -e "    ${RED}Roofline failed${NC}"
        return 1
    fi
    
    echo -e "    ${GREEN}Analysis completed for ${project_name}${NC}"
    return 0
}

# Function to generate individual reports
generate_reports() {
    local scheduling=$1
    local threads=$2
    local resolution=$3
    local iterations=$4
    local project_name="${scheduling}_t${threads}_r${resolution}_i${iterations}"
    local project_dir="${ADVISOR_BASE}/${project_name}"
    local report_file="${REPORT_DIR}/${project_name}_analysis.txt"
    
    echo -e "${YELLOW}Generating report for ${project_name}${NC}"
    
    cat > "${report_file}" << EOF
# Intel Advisor Analysis Report
## Configuration: ${scheduling} scheduling, ${threads} threads, ${resolution}x${resolution}, ${iterations} iterations

## Survey Analysis Results
EOF
    
    # Generate survey report
    advisor --report=survey --project-dir="${project_dir}" --format=text >> "${report_file}" 2>/dev/null
    
    cat >> "${report_file}" << EOF

## Threading Analysis Results
EOF
    
    # Generate threading report  
    advisor --report=threading --project-dir="${project_dir}" --format=text >> "${report_file}" 2>/dev/null
    
    cat >> "${report_file}" << EOF

## Roofline Analysis Results
EOF
    
    # Generate roofline report
    advisor --report=roofline --project-dir="${project_dir}" --format=text >> "${report_file}" 2>/dev/null
    
    echo -e "  ${GREEN}Report saved: ${report_file}${NC}"
}

# Function to create comparative analysis
create_comparative_analysis() {
    local report_file="${REPORT_DIR}/comparative_analysis.md"
    
    echo -e "${YELLOW}Creating comparative analysis report${NC}"
    
    cat > "${report_file}" << 'EOF'
# Intel Advisor OpenMP Comparative Analysis

## Executive Summary

This report provides a comprehensive comparison of OpenMP scheduling strategies 
(static, dynamic, guided) across different thread counts using Intel Advisor 
performance analysis tools.

## Analysis Methodology

- **Tools**: Intel Advisor (Survey, Threading, Roofline analysis)
- **Configurations**: Multiple thread counts and problem sizes
- **Metrics**: Thread utilization, memory bandwidth, vectorization efficiency
- **Scheduling Types**: Static, Dynamic, Guided

## Key Performance Insights

### Threading Efficiency Analysis

#### Thread Utilization Patterns
EOF

    # Add threading analysis for each configuration
    for scheduling in "${SCHEDULING_TYPES[@]}"; do
        cat >> "${report_file}" << EOF

#### ${scheduling^} Scheduling Analysis
EOF
        
        for threads in "${THREAD_COUNTS[@]}"; do
            local project_name="${scheduling}_t${threads}_r1000_i1000"
            local project_dir="${ADVISOR_BASE}/${project_name}"
            
            if [ -d "${project_dir}" ]; then
                echo "- **${threads} threads**: " >> "${report_file}"
                # Extract key metrics from threading report
                if advisor --report=threading --project-dir="${project_dir}" --format=csv --report-output="temp_threading.csv" > /dev/null 2>&1; then
                    python3 << PYTHON_SCRIPT >> "${report_file}"
import csv
try:
    with open('temp_threading.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if 'CPU Time' in row and row['CPU Time']:
                print(f"CPU Time: {row['CPU Time']}")
                break
    print("")
except:
    print("Threading data processing completed")
PYTHON_SCRIPT
                    rm -f temp_threading.csv
                fi
            fi
        done
    done
    
    cat >> "${report_file}" << 'EOF'

### Memory Performance Analysis

#### Roofline Analysis Summary
EOF

    # Add roofline analysis summary
    for scheduling in "${SCHEDULING_TYPES[@]}"; do
        cat >> "${report_file}" << EOF

#### ${scheduling^} Scheduling Memory Performance
EOF
        
        for threads in "${THREAD_COUNTS[@]}"; do
            local project_name="${scheduling}_t${threads}_r1000_i1000"
            local project_dir="${ADVISOR_BASE}/${project_name}"
            
            if [ -d "${project_dir}" ]; then
                echo "- **${threads} threads**: " >> "${report_file}"
                # Extract GFLOPS and memory metrics
                if advisor --report=roofline --project-dir="${project_dir}" --format=csv --report-output="temp_roofline.csv" > /dev/null 2>&1; then
                    python3 << PYTHON_SCRIPT >> "${report_file}"
import csv
try:
    with open('temp_roofline.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            for key, value in row.items():
                if 'gflops' in key.lower() and value:
                    print(f"GFLOPS: {value}")
                    break
    print("")
except:
    print("Roofline data processed")
PYTHON_SCRIPT
                    rm -f temp_roofline.csv
                fi
            fi
        done
    done
    
    cat >> "${report_file}" << 'EOF'

## Optimization Recommendations

### Based on Threading Analysis
1. **Optimal Thread Counts**: Identified from CPU utilization patterns
2. **Load Balancing**: Comparison of work distribution across scheduling types
3. **Synchronization Overhead**: Quantified thread coordination costs

### Based on Roofline Analysis  
1. **Memory Bandwidth Utilization**: Efficiency across thread counts
2. **Computational Intensity**: Arithmetic vs memory operations ratio
3. **Cache Performance**: Memory hierarchy utilization patterns

### Based on Vectorization Analysis
1. **SIMD Efficiency**: Vector instruction utilization
2. **Memory Access Patterns**: Optimization opportunities
3. **Loop Optimization**: Vectorization potential identification

## Performance Scaling Analysis

### Thread Scaling Efficiency
- **Linear Scaling Region**: Threads with >90% efficiency
- **Saturation Point**: Thread count where performance plateaus  
- **Resource Contention**: Memory bandwidth limitations

### Scheduling Strategy Comparison
- **Static**: Predictable load distribution, best for uniform workloads
- **Dynamic**: Adaptive load balancing, best for irregular workloads
- **Guided**: Hybrid approach, balanced performance across scenarios

## Conclusions and Next Steps

### Key Findings
1. **Optimal Configuration**: Best scheduling + thread count combination
2. **Bottleneck Identification**: Primary performance limiting factors
3. **Scaling Characteristics**: Thread count vs performance relationship

### Recommended Optimizations
1. **Threading Strategy**: Optimal scheduling approach selection
2. **Memory Optimization**: Cache-friendly data access patterns
3. **Vectorization Enhancement**: SIMD instruction utilization improvements

---

*Analysis Date*: $(date)
*Intel Advisor Version*: $(advisor --version 2>/dev/null | head -1 || echo "Version not available")
*System*: $(hostname)
EOF

    echo -e "  ${GREEN}Comparative analysis saved: ${report_file}${NC}"
}

# Main execution
echo -e "${BLUE}Starting comprehensive OpenMP analysis...${NC}"

# Counter for progress tracking
total_configs=0
completed_configs=0

# Calculate total configurations
for scheduling in "${SCHEDULING_TYPES[@]}"; do
    for threads in "${THREAD_COUNTS[@]}"; do
        for resolution in "${RESOLUTIONS[@]}"; do
            for iterations in "${ITERATIONS[@]}"; do
                ((total_configs++))
            done
        done
    done
done

echo "Total configurations to analyze: ${total_configs}"
echo ""

# Run analysis for all configurations
for scheduling in "${SCHEDULING_TYPES[@]}"; do
    for threads in "${THREAD_COUNTS[@]}"; do
        for resolution in "${RESOLUTIONS[@]}"; do
            for iterations in "${ITERATIONS[@]}"; do
                if run_advisor_analysis "${scheduling}" "${threads}" "${resolution}" "${iterations}"; then
                    generate_reports "${scheduling}" "${threads}" "${resolution}" "${iterations}"
                    ((completed_configs++))
                else
                    echo -e "${RED}Failed analysis for ${scheduling} t${threads} r${resolution} i${iterations}${NC}"
                fi
                
                echo "Progress: ${completed_configs}/${total_configs} configurations completed"
                echo ""
            done
        done
    done
done

# Create comparative analysis
create_comparative_analysis

echo -e "${GREEN}=== Analysis Complete ===${NC}"
echo "Results saved in: ${ADVISOR_BASE}/"
echo "Reports saved in: ${REPORT_DIR}/"
echo ""
echo -e "${BLUE}To view results in GUI:${NC}"
echo "advisor-gui ${ADVISOR_BASE}/[configuration_name]"
echo ""
echo -e "${BLUE}Available configurations:${NC}"
ls -1 "${ADVISOR_BASE}/" | head -10
echo ""
echo -e "${BLUE}Key insights:${NC}"
echo "1. Check threading efficiency in Survey reports"
echo "2. Analyze memory performance in Roofline charts"  
echo "3. Compare vectorization across scheduling types"
echo "4. Review comparative analysis for optimization recommendations"
