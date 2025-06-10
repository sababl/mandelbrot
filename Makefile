# Makefile for Mandelbrot Set Program
# Compatible with Intel Compiler (icpx) and Intel Advisor 2023.2

# Compiler and tools
CXX = icpx
ADVISOR = advisor

# Executable name
TARGET = mandelbrot_serial

# Source files
SOURCES = serial.cpp

# Compiler flags
CXXFLAGS = -O3 -std=c++17 -Wall -Wextra
DEBUG_FLAGS = -g -O0 -DDEBUG
ADVISOR_FLAGS = -g -O2 -qopt-report=5 -qopt-report-phase=vec

# Intel Advisor flags
ADVISOR_COLLECT_FLAGS = --collect=survey,tripcounts
ADVISOR_REPORT_FLAGS = --report=survey,tripcounts

# Output directories
BUILD_DIR = build
REPORTS_DIR = advisor_reports

# Default target
all: $(TARGET)

# Build the main executable
$(TARGET): $(SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -o $(BUILD_DIR)/$(TARGET) $(SOURCES)
	@echo "Built $(TARGET) successfully!"

# Debug build
debug: $(SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(DEBUG_FLAGS) -o $(BUILD_DIR)/$(TARGET)_debug $(SOURCES)
	@echo "Built debug version successfully!"

# Build with Intel Advisor instrumentation
advisor-build: $(SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(CXX) $(ADVISOR_FLAGS) -o $(BUILD_DIR)/$(TARGET)_advisor $(SOURCES)
	@echo "Built Intel Advisor instrumented version successfully!"

# Run Intel Advisor analysis
advisor-collect: advisor-build
	@mkdir -p $(REPORTS_DIR)
	@echo "Running Intel Advisor data collection..."
	$(ADVISOR) $(ADVISOR_COLLECT_FLAGS) --project-dir=$(REPORTS_DIR) -- $(BUILD_DIR)/$(TARGET)_advisor output.csv
	@echo "Intel Advisor data collection completed!"

# Generate Intel Advisor reports
advisor-report:
	@echo "Generating Intel Advisor reports..."
	$(ADVISOR) $(ADVISOR_REPORT_FLAGS) --project-dir=$(REPORTS_DIR) --format=text --report-output=$(REPORTS_DIR)/survey_report.txt
	$(ADVISOR) --report=tripcounts --project-dir=$(REPORTS_DIR) --format=text --report-output=$(REPORTS_DIR)/tripcounts_report.txt
	@echo "Reports generated in $(REPORTS_DIR)/"

# Full Intel Advisor workflow
advisor-full: advisor-collect advisor-report
	@echo "Complete Intel Advisor analysis finished!"
	@echo "Check reports in $(REPORTS_DIR)/ directory"

# Run the program
run: $(TARGET)
	@echo "Running Mandelbrot set calculation..."
	./$(BUILD_DIR)/$(TARGET) output.csv

# Run with timing
run-time: $(TARGET)
	@echo "Running Mandelbrot set calculation with timing..."
	time ./$(BUILD_DIR)/$(TARGET) output.csv

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)
	rm -f output.csv
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
	@echo "  all              - Build the main executable (default)"
	@echo "  debug            - Build debug version"
	@echo "  advisor-build    - Build with Intel Advisor instrumentation"
	@echo "  advisor-collect  - Run Intel Advisor data collection"
	@echo "  advisor-report   - Generate Intel Advisor reports"
	@echo "  advisor-full     - Complete Intel Advisor workflow"
	@echo "  run              - Build and run the program"
	@echo "  run-time         - Build and run with timing"
	@echo "  clean            - Remove build artifacts"
	@echo "  clean-all        - Remove all artifacts and reports"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Intel Advisor Usage:"
	@echo "  1. make advisor-full    # Complete analysis"
	@echo "  2. Check reports in advisor_reports/ directory"

# Phony targets
.PHONY: all debug advisor-build advisor-collect advisor-report advisor-full run run-time clean clean-all install-intel-tools help
