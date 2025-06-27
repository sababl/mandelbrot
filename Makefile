# Comprehensive Makefile for Mandelbrot Algorithms with Intel Compiler and Advisor
# Fallback to g++ if Intel compiler is not available
CXX := $(shell command -v icpc 2> /dev/null || echo g++)
CXXFLAGS = -O2 -g
ifeq ($(CXX),g++)
    OPENMP_FLAGS = -fopenmp
else
    OPENMP_FLAGS = -qopenmp
endif
MPI_FLAGS = -DWITH_MPI
CUDA_FLAGS = -DWITH_CUDA

# Version control - can be overridden via command line
VERSION ?= sequential
OUTPUT_FILE ?= output.csv
THREADS ?= 4

# Directory structure
SEQUENTIAL_DIR = sequential
OPENMP_DIR = openmp
MPI_DIR = mpi
CUDA_DIR = cuda
HYBRID_DIR = hybrid

# Source files mapping
SEQUENTIAL_SRC = $(SEQUENTIAL_DIR)/mandelbrot.cpp
OPENMP_STATIC_SRC = $(OPENMP_DIR)/openmp_static.cpp
OPENMP_DYNAMIC_SRC = $(OPENMP_DIR)/openmp_dynamic.cpp
OPENMP_GUIDED_SRC = $(OPENMP_DIR)/openmp_guided.cpp

# Target executables mapping
SEQUENTIAL_TARGET = $(SEQUENTIAL_DIR)/mandelbrot
OPENMP_STATIC_TARGET = $(OPENMP_DIR)/mandelbrot_static
OPENMP_DYNAMIC_TARGET = $(OPENMP_DIR)/mandelbrot_dynamic
OPENMP_GUIDED_TARGET = $(OPENMP_DIR)/mandelbrot_guided

# Output files mapping
SEQUENTIAL_OUTPUT = $(SEQUENTIAL_DIR)/$(OUTPUT_FILE)
OPENMP_OUTPUT = $(OPENMP_DIR)/$(OUTPUT_FILE)
MPI_OUTPUT = $(MPI_DIR)/$(OUTPUT_FILE)
CUDA_OUTPUT = $(CUDA_DIR)/$(OUTPUT_FILE)

# Advisor results directories
SEQUENTIAL_ADVISOR = $(SEQUENTIAL_DIR)/advisor-results
OPENMP_ADVISOR = $(OPENMP_DIR)/advisor-results
MPI_ADVISOR = $(MPI_DIR)/advisor-results
CUDA_ADVISOR = $(CUDA_DIR)/advisor-results

# Available versions
VERSIONS = sequential openmp-static openmp-dynamic openmp-guided

# Default target - shows help
.DEFAULT_GOAL := help

# Help target
help:
	@echo "=== Mandelbrot Algorithm Builder ==="
	@echo "Available versions: $(VERSIONS)"
	@echo ""
	@echo "Usage examples:"
	@echo "  make build VERSION=sequential"
	@echo "  make build VERSION=openmp-static"
	@echo "  make run VERSION=openmp-dynamic THREADS=8"
	@echo "  make advisor VERSION=sequential"
	@echo "  make benchmark  # Runs all versions for comparison"
	@echo ""
	@echo "Available targets:"
	@echo "  build      - Build specific version (requires VERSION=)"
	@echo "  run        - Run specific version (requires VERSION=)"
	@echo "  advisor    - Run Intel Advisor analysis (requires VERSION=)"
	@echo "  benchmark  - Run all versions and compare performance"
	@echo "  clean      - Clean all build artifacts"
	@echo "  list       - List all available versions"
	@echo ""
	@echo "Environment variables:"
	@echo "  VERSION    - Algorithm version (default: sequential)"
	@echo "  THREADS    - Number of OpenMP threads (default: 4)"
	@echo "  OUTPUT_FILE- Output filename (default: output.csv)"

# List available versions
list:
	@echo "Available algorithm versions:"
	@for version in $(VERSIONS); do echo "  - $$version"; done

# Build targets
build: build-$(VERSION)

build-sequential: $(SEQUENTIAL_TARGET)
$(SEQUENTIAL_TARGET): $(SEQUENTIAL_SRC)
	@echo "Building sequential version..."
	$(CXX) $(CXXFLAGS) -o $(SEQUENTIAL_TARGET) $(SEQUENTIAL_SRC)

build-openmp-static: $(OPENMP_STATIC_TARGET)
$(OPENMP_STATIC_TARGET): $(OPENMP_STATIC_SRC)
	@echo "Building OpenMP static version..."
	$(CXX) $(CXXFLAGS) $(OPENMP_FLAGS) -o $(OPENMP_STATIC_TARGET) $(OPENMP_STATIC_SRC)

build-openmp-dynamic: $(OPENMP_DYNAMIC_TARGET)
$(OPENMP_DYNAMIC_TARGET): $(OPENMP_DYNAMIC_SRC)
	@echo "Building OpenMP dynamic version..."
	$(CXX) $(CXXFLAGS) $(OPENMP_FLAGS) -o $(OPENMP_DYNAMIC_TARGET) $(OPENMP_DYNAMIC_SRC)

build-openmp-guided: $(OPENMP_GUIDED_TARGET)
$(OPENMP_GUIDED_TARGET): $(OPENMP_GUIDED_SRC)
	@echo "Building OpenMP guided version..."
	$(CXX) $(CXXFLAGS) $(OPENMP_FLAGS) -o $(OPENMP_GUIDED_TARGET) $(OPENMP_GUIDED_SRC)

# Build all versions
build-all: build-sequential build-openmp-static build-openmp-dynamic build-openmp-guided
	@echo "All versions built successfully!"

# Run targets
run: run-$(VERSION)

run-sequential: build-sequential
	@echo "Running sequential version..."
	@echo "Output will be saved to: $(SEQUENTIAL_OUTPUT)"
	./$(SEQUENTIAL_TARGET) $(SEQUENTIAL_OUTPUT)

run-openmp-static: build-openmp-static
	@echo "Running OpenMP static version with $(THREADS) threads..."
	@echo "Output will be saved to: $(OPENMP_OUTPUT)"
	OMP_NUM_THREADS=$(THREADS) ./$(OPENMP_STATIC_TARGET) $(OPENMP_OUTPUT)

run-openmp-dynamic: build-openmp-dynamic
	@echo "Running OpenMP dynamic version with $(THREADS) threads..."
	@echo "Output will be saved to: $(OPENMP_OUTPUT)"
	OMP_NUM_THREADS=$(THREADS) ./$(OPENMP_DYNAMIC_TARGET) $(OPENMP_OUTPUT)

run-openmp-guided: build-openmp-guided
	@echo "Running OpenMP guided version with $(THREADS) threads..."
	@echo "Output will be saved to: $(OPENMP_OUTPUT)"
	OMP_NUM_THREADS=$(THREADS) ./$(OPENMP_GUIDED_TARGET) $(OPENMP_OUTPUT)

# Benchmark all versions
benchmark: build-all
	@echo "=== Performance Benchmark ==="
	@echo "Running all algorithm versions for comparison..."
	@echo ""
	@echo "1. Sequential version:"
	@make run-sequential --silent
	@echo ""
	@echo "2. OpenMP Static ($(THREADS) threads):"
	@make run-openmp-static THREADS=$(THREADS) --silent
	@echo ""
	@echo "3. OpenMP Dynamic ($(THREADS) threads):"
	@make run-openmp-dynamic THREADS=$(THREADS) --silent
	@echo ""
	@echo "4. OpenMP Guided ($(THREADS) threads):"
	@make run-openmp-guided THREADS=$(THREADS) --silent
	@echo ""
	@echo "Benchmark completed! Check individual output files for results."

# Intel Advisor analysis
advisor: advisor-$(VERSION)

advisor-sequential: build-sequential
	@echo "Running Intel Advisor analysis on sequential version..."
	advisor --collect=survey --project-dir=$(SEQUENTIAL_ADVISOR) -- $(SEQUENTIAL_TARGET) $(SEQUENTIAL_OUTPUT)
	advisor --collect=roofline --project-dir=$(SEQUENTIAL_ADVISOR) -- $(SEQUENTIAL_TARGET) $(SEQUENTIAL_OUTPUT)
	@echo "Analysis complete. Use 'make advisor-gui VERSION=sequential' to view results."

advisor-openmp-static: build-openmp-static
	@echo "Running Intel Advisor analysis on OpenMP static version..."
	advisor --collect=survey --project-dir=$(OPENMP_ADVISOR) -- $(OPENMP_STATIC_TARGET) $(OPENMP_OUTPUT)
	advisor --collect=roofline --project-dir=$(OPENMP_ADVISOR) -- $(OPENMP_STATIC_TARGET) $(OPENMP_OUTPUT)
	@echo "Analysis complete. Use 'make advisor-gui VERSION=openmp-static' to view results."

advisor-openmp-dynamic: build-openmp-dynamic
	@echo "Running Intel Advisor analysis on OpenMP dynamic version..."
	advisor --collect=survey --project-dir=$(OPENMP_ADVISOR) -- $(OPENMP_DYNAMIC_TARGET) $(OPENMP_OUTPUT)
	advisor --collect=roofline --project-dir=$(OPENMP_ADVISOR) -- $(OPENMP_DYNAMIC_TARGET) $(OPENMP_OUTPUT)
	@echo "Analysis complete. Use 'make advisor-gui VERSION=openmp-dynamic' to view results."

advisor-openmp-guided: build-openmp-guided
	@echo "Running Intel Advisor analysis on OpenMP guided version..."
	advisor --collect=survey --project-dir=$(OPENMP_ADVISOR) -- $(OPENMP_GUIDED_TARGET) $(OPENMP_OUTPUT)
	advisor --collect=roofline --project-dir=$(OPENMP_ADVISOR) -- $(OPENMP_GUIDED_TARGET) $(OPENMP_OUTPUT)
	@echo "Analysis complete. Use 'make advisor-gui VERSION=openmp-guided' to view results."

# View advisor results
advisor-gui: advisor-gui-$(VERSION)

advisor-gui-sequential:
	advisor-gui $(SEQUENTIAL_ADVISOR) &

advisor-gui-openmp-static:
	advisor-gui $(OPENMP_ADVISOR) &

advisor-gui-openmp-dynamic:
	advisor-gui $(OPENMP_ADVISOR) &

advisor-gui-openmp-guided:
	advisor-gui $(OPENMP_ADVISOR) &

# Generate text reports
advisor-report: advisor-report-$(VERSION)

advisor-report-sequential:
	advisor --report=survey --project-dir=$(SEQUENTIAL_ADVISOR)
	advisor --report=roofline --project-dir=$(SEQUENTIAL_ADVISOR)

advisor-report-openmp-static:
	advisor --report=survey --project-dir=$(OPENMP_ADVISOR)
	advisor --report=roofline --project-dir=$(OPENMP_ADVISOR)

advisor-report-openmp-dynamic:
	advisor --report=survey --project-dir=$(OPENMP_ADVISOR)
	advisor --report=roofline --project-dir=$(OPENMP_ADVISOR)

advisor-report-openmp-guided:
	advisor --report=survey --project-dir=$(OPENMP_ADVISOR)
	advisor --report=roofline --project-dir=$(OPENMP_ADVISOR)

# Utility targets
clean:
	@echo "Cleaning all build artifacts..."
	rm -f $(SEQUENTIAL_TARGET) $(SEQUENTIAL_OUTPUT)
	rm -f $(OPENMP_STATIC_TARGET) $(OPENMP_DYNAMIC_TARGET) $(OPENMP_GUIDED_TARGET) $(OPENMP_OUTPUT)
	rm -rf $(SEQUENTIAL_ADVISOR) $(OPENMP_ADVISOR)
	@echo "Clean completed!"

# Clean specific version
clean-sequential:
	rm -f $(SEQUENTIAL_TARGET) $(SEQUENTIAL_OUTPUT)
	rm -rf $(SEQUENTIAL_ADVISOR)

clean-openmp:
	rm -f $(OPENMP_STATIC_TARGET) $(OPENMP_DYNAMIC_TARGET) $(OPENMP_GUIDED_TARGET) $(OPENMP_OUTPUT)
	rm -rf $(OPENMP_ADVISOR)

# Test if a version is built
test-build: test-build-$(VERSION)

test-build-sequential:
	@test -f $(SEQUENTIAL_TARGET) && echo "Sequential version is built" || echo "Sequential version not built"

test-build-openmp-static:
	@test -f $(OPENMP_STATIC_TARGET) && echo "OpenMP static version is built" || echo "OpenMP static version not built"

test-build-openmp-dynamic:
	@test -f $(OPENMP_DYNAMIC_TARGET) && echo "OpenMP dynamic version is built" || echo "OpenMP dynamic version not built"

test-build-openmp-guided:
	@test -f $(OPENMP_GUIDED_TARGET) && echo "OpenMP guided version is built" || echo "OpenMP guided version not built"

# Show current configuration
config:
	@echo "=== Current Configuration ==="
	@echo "Compiler: $(CXX)"
	@echo "CXXFLAGS: $(CXXFLAGS)"
	@echo "OpenMP Flags: $(OPENMP_FLAGS)"
	@echo "Selected Version: $(VERSION)"
	@echo "Threads: $(THREADS)"
	@echo "Output File: $(OUTPUT_FILE)"
	@echo "Available Versions: $(VERSIONS)"

.PHONY: help list build build-all run benchmark advisor advisor-gui advisor-report clean config test-build \
        build-sequential build-openmp-static build-openmp-dynamic build-openmp-guided \
        run-sequential run-openmp-static run-openmp-dynamic run-openmp-guided \
        advisor-sequential advisor-openmp-static advisor-openmp-dynamic advisor-openmp-guided \
        advisor-gui-sequential advisor-gui-openmp-static advisor-gui-openmp-dynamic advisor-gui-openmp-guided \
        advisor-report-sequential advisor-report-openmp-static advisor-report-openmp-dynamic advisor-report-openmp-guided \
        clean-sequential clean-openmp test-build-sequential test-build-openmp-static test-build-openmp-dynamic test-build-openmp-guided
