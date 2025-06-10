# Makefile for Mandelbrot Set Program
# Compatible with Intel Compiler (icpx) and Intel Advisor 2023.2

# Compiler and tools
CXX = icpx
ADVISOR = advisor

# Executable names
TARGET_SERIAL = mandelbrot_serial
TARGET_PARALLEL = mandelbrot_parallel
TARGET_OPTIMIZED = mandelbrot_optimized

# Source files
SOURCES_SERIAL = serial.cpp
SOURCES_PARALLEL = parallel.cpp
SOURCES_OPTIMIZED = parallel_optimized.cpp

# Compiler flags
CXXFLAGS = -O3 -std=c++17 -Wall -Wextra
AVX2_FLAGS = -xCORE-AVX2 -qopt-report=5 -qopt-report-phase=vec
OPENMP_FLAGS = -fopenmp -qopenmp-simd
DEBUG_FLAGS = -g -O0 -DDEBUG
ADVISOR_FLAGS = -g -O2 -qopt-report=5 -qopt-report-phase=vec

# Intel Advisor flags
ADVISOR_COLLECT_FLAGS = --collect=survey,tripcounts
ADVISOR_REPORT_FLAGS = --report=survey,tripcounts

# Output directories
BUILD_DIR = build
REPORTS_DIR = advisor_reports

# Default target
all: serial parallel optimized

# Build the serial executable
serial: $(SOURCES_SERIAL)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -o $(BUILD_DIR)/$(TARGET_SERIAL) $(SOURCES_SERIAL)
	@echo "Built $(TARGET_SERIAL) successfully!"

# Build the parallel executable
parallel: $(SOURCES_PARALLEL)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(OPENMP_FLAGS) -o $(BUILD_DIR)/$(TARGET_PARALLEL) $(SOURCES_PARALLEL)
	@echo "Built $(TARGET_PARALLEL) successfully!"

# Build the optimized parallel executable
optimized: $(SOURCES_OPTIMIZED)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(OPENMP_FLAGS) -o $(BUILD_DIR)/$(TARGET_OPTIMIZED) $(SOURCES_OPTIMIZED)
	@echo "Built $(TARGET_OPTIMIZED) successfully!"

# Legacy target for compatibility
$(TARGET_SERIAL): serial

# Debug builds
debug-serial: $(SOURCES_SERIAL)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(DEBUG_FLAGS) -o $(BUILD_DIR)/$(TARGET_SERIAL)_debug $(SOURCES_SERIAL)
	@echo "Built debug serial version successfully!"

debug-parallel: $(SOURCES_PARALLEL)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(DEBUG_FLAGS) $(OPENMP_FLAGS) -o $(BUILD_DIR)/$(TARGET_PARALLEL)_debug $(SOURCES_PARALLEL)
	@echo "Built debug parallel version successfully!"

debug: debug-serial debug-parallel

# Build with Intel Advisor instrumentation
advisor-build-serial: $(SOURCES_SERIAL)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(ADVISOR_FLAGS) -o $(BUILD_DIR)/$(TARGET_SERIAL)_advisor $(SOURCES_SERIAL)
	@echo "Built Intel Advisor instrumented serial version successfully!"

advisor-build-parallel: $(SOURCES_PARALLEL)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(ADVISOR_FLAGS) $(OPENMP_FLAGS) -o $(BUILD_DIR)/$(TARGET_PARALLEL)_advisor $(SOURCES_PARALLEL)
	@echo "Built Intel Advisor instrumented parallel version successfully!"

advisor-build: advisor-build-serial advisor-build-parallel

# Run Intel Advisor analysis on serial version
advisor-collect-serial: advisor-build-serial
	@mkdir -p $(REPORTS_DIR)/serial
	@echo "Running Intel Advisor data collection on serial version..."
	$(ADVISOR) $(ADVISOR_COLLECT_FLAGS) --project-dir=$(REPORTS_DIR)/serial -- $(BUILD_DIR)/$(TARGET_SERIAL)_advisor output_serial.csv
	@echo "Intel Advisor data collection for serial version completed!"

# Run Intel Advisor analysis on parallel version
advisor-collect-parallel: advisor-build-parallel
	@mkdir -p $(REPORTS_DIR)/parallel
	@echo "Running Intel Advisor data collection on parallel version..."
	$(ADVISOR) $(ADVISOR_COLLECT_FLAGS) --project-dir=$(REPORTS_DIR)/parallel -- $(BUILD_DIR)/$(TARGET_PARALLEL)_advisor output_parallel.csv
	@echo "Intel Advisor data collection for parallel version completed!"

advisor-collect: advisor-collect-serial advisor-collect-parallel

# Generate Intel Advisor reports
advisor-report:
	@echo "Generating Intel Advisor reports..."
	@mkdir -p $(REPORTS_DIR)
	$(ADVISOR) --report=survey --project-dir=$(REPORTS_DIR)/serial --format=text --report-output=$(REPORTS_DIR)/serial_survey_report.txt
	$(ADVISOR) --report=tripcounts --project-dir=$(REPORTS_DIR)/serial --format=text --report-output=$(REPORTS_DIR)/serial_tripcounts_report.txt
	$(ADVISOR) --report=survey --project-dir=$(REPORTS_DIR)/parallel --format=text --report-output=$(REPORTS_DIR)/parallel_survey_report.txt
	$(ADVISOR) --report=tripcounts --project-dir=$(REPORTS_DIR)/parallel --format=text --report-output=$(REPORTS_DIR)/parallel_tripcounts_report.txt
	@echo "Reports generated in $(REPORTS_DIR)/"

# Full Intel Advisor workflow
advisor-full: advisor-collect advisor-report
	@echo "Complete Intel Advisor analysis finished!"
	@echo "Check reports in $(REPORTS_DIR)/ directory"

# Build with AVX2 vectorization (highest ISA)
avx2-serial: $(SOURCES_SERIAL)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(AVX2_FLAGS) -o $(BUILD_DIR)/$(TARGET_SERIAL)_avx2 $(SOURCES_SERIAL)
	@echo "Built AVX2-optimized serial version successfully!"

avx2-parallel: $(SOURCES_PARALLEL)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(AVX2_FLAGS) $(OPENMP_FLAGS) -o $(BUILD_DIR)/$(TARGET_PARALLEL)_avx2 $(SOURCES_PARALLEL)
	@echo "Built AVX2-optimized parallel version successfully!"

avx2-optimized: $(SOURCES_OPTIMIZED)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(AVX2_FLAGS) $(OPENMP_FLAGS) -o $(BUILD_DIR)/$(TARGET_OPTIMIZED)_avx2 $(SOURCES_OPTIMIZED)
	@echo "Built AVX2-optimized version successfully!"

avx2: avx2-serial avx2-parallel avx2-optimized

# Run AVX2 versions
run-avx2-serial: avx2-serial
	@echo "Running AVX2-optimized serial version..."
	time ./$(BUILD_DIR)/$(TARGET_SERIAL)_avx2 output_avx2_serial.csv

run-avx2-parallel: avx2-parallel
	@echo "Running AVX2-optimized parallel version..."
	time ./$(BUILD_DIR)/$(TARGET_PARALLEL)_avx2 output_avx2_parallel.csv

run-avx2-optimized: avx2-optimized
	@echo "Running AVX2-optimized version..."
	time ./$(BUILD_DIR)/$(TARGET_OPTIMIZED)_avx2 output_avx2_optimized.csv

# Complete performance comparison
performance-test: all avx2
	@echo "=== PERFORMANCE COMPARISON ==="
	@echo "1. Serial (baseline):"
	@time ./$(BUILD_DIR)/$(TARGET_SERIAL) output_serial.csv
	@echo ""
	@echo "2. Serial + AVX2:"
	@time ./$(BUILD_DIR)/$(TARGET_SERIAL)_avx2 output_serial_avx2.csv
	@echo ""
	@echo "3. Parallel OpenMP:"
	@time ./$(BUILD_DIR)/$(TARGET_PARALLEL) output_parallel.csv
	@echo ""
	@echo "4. Parallel + AVX2:"
	@time ./$(BUILD_DIR)/$(TARGET_PARALLEL)_avx2 output_parallel_avx2.csv
	@echo ""
	@echo "5. Optimized + AVX2:"
	@time ./$(BUILD_DIR)/$(TARGET_OPTIMIZED)_avx2 output_optimized_avx2.csv

# Intel Advisor analysis with AVX2
advisor-avx2: avx2-optimized
	@mkdir -p $(REPORTS_DIR)/avx2
	@echo "Running Intel Advisor on AVX2-optimized version..."
	$(ADVISOR) --collect=survey --project-dir=$(REPORTS_DIR)/avx2 -- $(BUILD_DIR)/$(TARGET_OPTIMIZED)_avx2 output_avx2_advisor.csv
	@echo "Generating AVX2 report..."
	$(ADVISOR) --report=survey --project-dir=$(REPORTS_DIR)/avx2 --format=html --report-output=$(REPORTS_DIR)/avx2_survey.html 2>/dev/null || true
	@echo "AVX2 analysis complete! Check $(REPORTS_DIR)/avx2_survey.html"

# Run the serial program
run-serial: serial
	@echo "Running serial Mandelbrot set calculation..."
	./$(BUILD_DIR)/$(TARGET_SERIAL) output_serial.csv

# Run the parallel program
run-parallel: parallel
	@echo "Running parallel Mandelbrot set calculation..."
	./$(BUILD_DIR)/$(TARGET_PARALLEL) output_parallel.csv

# Run both programs for comparison
run-both: run-serial run-parallel

# Run with timing
run-time-serial: serial
	@echo "Running serial Mandelbrot set calculation with timing..."
	time ./$(BUILD_DIR)/$(TARGET_SERIAL) output_serial.csv

run-time-parallel: parallel
	@echo "Running parallel Mandelbrot set calculation with timing..."
	time ./$(BUILD_DIR)/$(TARGET_PARALLEL) output_parallel.csv

# Performance comparison
benchmark: serial parallel
	@echo "=== Performance Benchmark ==="
	@echo "Serial version:"
	@time ./$(BUILD_DIR)/$(TARGET_SERIAL) output_serial.csv
	@echo ""
	@echo "Parallel version:"
	@time ./$(BUILD_DIR)/$(TARGET_PARALLEL) output_parallel.csv
	@echo ""
	@echo "=== Benchmark Complete ==="

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -f output_serial.csv output_parallel.csv output.csv
	@echo "Cleaned build artifacts"

# Clean everything including advisor reports
clean-all: clean
	rm -rf $(REPORTS_DIR)
	@echo "Cleaned all artifacts and reports"

# Install Intel tools (if needed)
install-intel-tools:
	@echo "Make sure Intel oneAPI toolkit is installed and sourced:"
	@echo "source /opt/intel/oneapi/setvars.sh"

# Help target
help:
	@echo "Available targets:"
	@echo "  all              - Build both serial and parallel executables (default)"
	@echo "  serial           - Build serial version"
	@echo "  parallel         - Build parallel version with OpenMP"
	@echo "  debug            - Build debug versions"
	@echo "  debug-serial     - Build debug serial version"
	@echo "  debug-parallel   - Build debug parallel version"
	@echo "  advisor-build    - Build with Intel Advisor instrumentation"
	@echo "  advisor-collect  - Run Intel Advisor data collection"
	@echo "  advisor-report   - Generate Intel Advisor reports"
	@echo "  advisor-full     - Complete Intel Advisor workflow"
	@echo "  run-serial       - Build and run serial version"
	@echo "  run-parallel     - Build and run parallel version"
	@echo "  run-both         - Run both versions for comparison"
	@echo "  run-time-serial  - Build and run serial version with timing"
	@echo "  run-time-parallel- Build and run parallel version with timing"
	@echo "  benchmark        - Performance comparison between versions"
	@echo "  clean            - Remove build artifacts"
	@echo "  clean-all        - Remove all artifacts and reports"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "OpenMP Usage:"
	@echo "  Set OMP_NUM_THREADS environment variable to control thread count"
	@echo "  Example: OMP_NUM_THREADS=8 make run-parallel"
	@echo ""
	@echo "Intel Advisor Usage:"
	@echo "  1. make advisor-full    # Complete analysis"
	@echo "  2. Check reports in advisor_reports/ directory"

# Phony targets
.PHONY: all serial parallel debug debug-serial debug-parallel advisor-build advisor-build-serial advisor-build-parallel advisor-collect advisor-collect-serial advisor-collect-parallel advisor-report advisor-full run-serial run-parallel run-both run-time-serial run-time-parallel benchmark clean clean-all install-intel-tools help
