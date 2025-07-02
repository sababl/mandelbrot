#!/bin/bash
# Intel Advisor Sequential Analysis Script
# Comprehensive performance analysis of Mandelbrot sequential implementation

# Set up Intel oneAPI environment
source /opt/intel/oneapi/setvars.sh

# Check if Intel Advisor is available
if ! command -v advisor &> /dev/null; then
    echo "Error: Intel Advisor not found!"
    echo "Please make sure Intel oneAPI is properly installed and sourced."
    exit 1
fi

# Configuration
SOURCE_FILE="sequential/mandelbrot.cpp"
EXECUTABLE="sequential/mandelbrot_advisor"
ADVISOR_PROJECT="advisor_results/sequential"
REPORT_FILE="report/advisor_sequential_comprehensive_analysis.txt"
CSV_OUTPUT="temp_advisor_output.csv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Intel Advisor Sequential Mandelbrot Analysis ===${NC}"
echo "Source: ${SOURCE_FILE}"
echo "Executable: ${EXECUTABLE}"
echo "Advisor Project: ${ADVISOR_PROJECT}"
echo "Report: ${REPORT_FILE}"
echo ""

# Create directories
mkdir -p advisor_results
mkdir -p report

# Clean previous results
rm -rf "${ADVISOR_PROJECT}"

# Build the sequential version with debug info for better analysis
echo -e "${YELLOW}Building sequential version with Intel compiler...${NC}"
if icc -O2 -g -o "${EXECUTABLE}" "${SOURCE_FILE}"; then
    echo -e "${GREEN}Compilation successful${NC}"
else
    echo -e "${RED}Compilation failed${NC}"
    exit 1
fi

echo -e "${YELLOW}Running Intel Advisor Survey Analysis...${NC}"
advisor --collect=survey --project-dir="${ADVISOR_PROJECT}" -- "./${EXECUTABLE}" "${CSV_OUTPUT}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Survey analysis completed${NC}"
else
    echo -e "${RED}Survey analysis failed${NC}"
    exit 1
fi

echo -e "${YELLOW}Running Intel Advisor Roofline Analysis...${NC}"
advisor --collect=roofline --project-dir="${ADVISOR_PROJECT}" -- "./${EXECUTABLE}" "${CSV_OUTPUT}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Roofline analysis completed${NC}"
else
    echo -e "${RED}Roofline analysis failed${NC}"
    exit 1
fi

echo -e "${YELLOW}Generating comprehensive analysis report...${NC}"

# Generate comprehensive report
cat > "${REPORT_FILE}" << 'EOF'
# Intel Advisor Sequential Mandelbrot Performance Analysis

## Executive Summary

This report provides a comprehensive performance analysis of the sequential Mandelbrot 
set implementation using Intel Advisor, including hotspot identification, time 
distribution analysis, and optimization recommendations.

## Methodology

- **Tool**: Intel Advisor (Survey + Roofline analysis)
- **Compiler**: Intel C++ Compiler (icc) with -O2 -g optimization
- **Target**: Sequential Mandelbrot computation implementation
- **Analysis Types**: 
  - Survey analysis for hotspot identification
  - Roofline analysis for performance characterization

## Analysis Results

EOF

# Extract survey results
echo -e "${YELLOW}Extracting survey analysis results...${NC}"
advisor --report=survey --project-dir="${ADVISOR_PROJECT}" --format=text >> "${REPORT_FILE}"

cat >> "${REPORT_FILE}" << 'EOF'

## Roofline Analysis Results

EOF

# Extract roofline results
echo -e "${YELLOW}Extracting roofline analysis results...${NC}"
advisor --report=roofline --project-dir="${ADVISOR_PROJECT}" --format=text >> "${REPORT_FILE}"

# Generate detailed hotspot analysis
cat >> "${REPORT_FILE}" << 'EOF'

## Detailed Hotspot Analysis

### Function-Level Performance Breakdown

EOF

# Extract function-level timing data
advisor --report=survey --project-dir="${ADVISOR_PROJECT}" --format=csv --report-output=temp_survey.csv

if [ -f "temp_survey.csv" ]; then
    echo -e "${YELLOW}Processing function-level performance data...${NC}"
    
    python3 << 'PYTHON_SCRIPT' >> "${REPORT_FILE}"
import csv
import sys

try:
    with open('temp_survey.csv', 'r') as f:
        reader = csv.DictReader(f)
        functions = []
        
        for row in reader:
            if 'Function' in row and 'Self Time' in row:
                func_name = row.get('Function', 'Unknown')
                self_time = row.get('Self Time', '0')
                total_time = row.get('Total Time', '0')
                
                # Skip empty or header rows
                if func_name and func_name != 'Function' and self_time != 'Self Time':
                    functions.append({
                        'function': func_name,
                        'self_time': self_time,
                        'total_time': total_time
                    })
        
        if functions:
            print("| Function | Self Time | Total Time | Percentage |")
            print("|----------|-----------|------------|------------|")
            
            for func in sorted(functions, key=lambda x: float(x['self_time'].replace('s', '').replace(',', '') if x['self_time'].replace('s', '').replace(',', '').replace('.', '').isdigit() else 0), reverse=True)[:10]:
                print(f"| {func['function'][:30]} | {func['self_time']} | {func['total_time']} | N/A |")
        else:
            print("No detailed function timing data available in CSV format.")

except Exception as e:
    print(f"Error processing survey data: {e}")
    print("Manual inspection of advisor results recommended.")

PYTHON_SCRIPT

fi

cat >> "${REPORT_FILE}" << 'EOF'

### Memory Access Patterns

EOF

# Extract memory access analysis
advisor --report=roofline --project-dir="${ADVISOR_PROJECT}" --format=csv --report-output=temp_roofline.csv

if [ -f "temp_roofline.csv" ]; then
    echo -e "${YELLOW}Processing memory access patterns...${NC}"
    
    python3 << 'PYTHON_SCRIPT' >> "${REPORT_FILE}"
import csv

try:
    with open('temp_roofline.csv', 'r') as f:
        reader = csv.DictReader(f)
        
        print("**Memory Bandwidth Utilization:**")
        print("")
        
        for row in reader:
            # Look for memory bandwidth related metrics
            for key, value in row.items():
                if 'bandwidth' in key.lower() or 'memory' in key.lower():
                    if value and value != key:
                        print(f"- {key}: {value}")
        
        print("")
        print("**Arithmetic Intensity Analysis:**")
        print("- Based on roofline model analysis")
        print("- Computational efficiency vs memory bandwidth")
        
except Exception as e:
    print("Memory access pattern analysis requires manual inspection of roofline results.")

PYTHON_SCRIPT

fi

cat >> "${REPORT_FILE}" << 'EOF'

## Intel Advisor Recommendations

### Automatic Recommendations

EOF

# Extract automatic recommendations
echo -e "${YELLOW}Extracting Intel Advisor recommendations...${NC}"
advisor --report=survey --project-dir="${ADVISOR_PROJECT}" --format=text | grep -A 20 -i "recommendation\|suggestion\|optimization" >> "${REPORT_FILE}" || echo "No automatic recommendations found in text format." >> "${REPORT_FILE}"

cat >> "${REPORT_FILE}" << 'EOF'

### Manual Analysis Recommendations

Based on the Intel Advisor analysis results:

#### 1. Hotspot Optimization
- **Primary Focus**: Target functions consuming the most execution time
- **Method**: Analyze the function-level breakdown above
- **Expected Impact**: Directly proportional to time spent in hotspot

#### 2. Memory Optimization  
- **Cache Efficiency**: Improve data locality for better cache performance
- **Memory Access Patterns**: Optimize memory access patterns identified in roofline analysis
- **Expected Impact**: Significant for memory-bound operations

#### 3. Vectorization Opportunities
- **SIMD Instructions**: Look for loops that can benefit from vectorization
- **Compiler Flags**: Consider additional vectorization flags (-xHost, -xCORE-AVX2)
- **Expected Impact**: 2-8x performance improvement for vectorizable code

#### 4. Parallelization Readiness
- **Loop Analysis**: Identify loops suitable for OpenMP parallelization
- **Data Dependencies**: Check for data races and dependencies
- **Expected Impact**: Basis for successful parallel implementation

## Performance Baseline Metrics

EOF

# Add baseline performance information
echo -e "${YELLOW}Adding baseline performance metrics...${NC}"
echo "**Sequential Performance Baseline:**" >> "${REPORT_FILE}"

# Run a quick benchmark to get baseline timing
echo -n "- Execution time: " >> "${REPORT_FILE}"
(time "./${EXECUTABLE}" "${CSV_OUTPUT}" 2>&1) 2>&1 | grep real | awk '{print $2}' >> "${REPORT_FILE}"

echo "- Configuration: Default (1000x1000, 1000 iterations)" >> "${REPORT_FILE}"
echo "- Compiler: Intel C++ (icc) with -O2 optimization" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

cat >> "${REPORT_FILE}" << 'EOF'

## Next Steps for Optimization

### Immediate Actions
1. **Review Hotspot Functions**: Focus optimization efforts on top time-consuming functions
2. **Memory Access Optimization**: Implement recommendations from roofline analysis  
3. **Vectorization**: Apply compiler vectorization hints where applicable
4. **Algorithm Review**: Consider algorithmic improvements for hotspot regions

### Parallel Implementation Planning
1. **OpenMP Integration**: Use survey results to identify parallel regions
2. **Load Balancing**: Plan work distribution based on computational patterns
3. **Memory Considerations**: Account for memory bandwidth in parallel design
4. **Scaling Validation**: Verify parallel efficiency against these baseline metrics

### Advanced Optimizations
1. **Profile-Guided Optimization (PGO)**: Use Intel compiler PGO features
2. **Advanced Vectorization**: Manual SIMD optimization for critical paths
3. **Cache Optimization**: Implement cache-friendly data structures
4. **Algorithm Variants**: Consider different mathematical approaches

---

*Analysis completed*: $(date)
*Intel Advisor Version*: $(advisor --version 2>/dev/null | head -1 || echo "Version information not available")
*Compiler*: Intel C++ Compiler (icc)
*System*: $(hostname)
EOF

# Clean up temporary files
rm -f temp_survey.csv temp_roofline.csv "${CSV_OUTPUT}"

echo -e "${GREEN}Comprehensive Intel Advisor analysis completed!${NC}"
echo -e "Report saved to: ${REPORT_FILE}"
echo ""
echo -e "${BLUE}To view detailed results in GUI:${NC}"
echo -e "advisor-gui ${ADVISOR_PROJECT}"
echo ""
echo -e "${BLUE}Key files generated:${NC}"
echo -e "  📊 ${REPORT_FILE} - Comprehensive analysis report"
echo -e "  📁 ${ADVISOR_PROJECT}/ - Raw advisor results"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Review the comprehensive report above"
echo -e "  2. Open Intel Advisor GUI for visual analysis"
echo -e "  3. Implement optimization recommendations"
echo -e "  4. Re-run analysis to measure improvements"
