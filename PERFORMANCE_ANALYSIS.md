# Mandelbrot Set Parallelization and Performance Analysis

## Overview
This project implements three versions of the Mandelbrot set calculation:
1. **Serial Version** (`serial.cpp`) - Original single-threaded implementation
2. **Parallel Version** (`parallel.cpp`) - OpenMP parallelized version
3. **Optimized Parallel Version** (`parallel_optimized.cpp`) - Highly optimized with manual vectorization hints

## Performance Results

### Configuration
- **Resolution**: 3000x6000 (18M pixels)
- **Iterations**: 3000 per pixel
- **Hardware**: 24 CPU cores available
- **Compiler**: Intel icpx with -O3 optimization

### Execution Times
| Version | Time (seconds) | Speedup | Notes |
|---------|----------------|---------|-------|
| Serial | 143s | 1.0x (baseline) | Single threaded |
| Parallel | 153s | 0.93x | OpenMP with dynamic scheduling |
| Optimized | 99s | 1.44x | Manual vectorization + static scheduling |

## Key Optimizations Implemented

### 1. OpenMP Parallelization
```cpp
#pragma omp parallel for schedule(static) shared(image)
for (int pos = 0; pos < HEIGHT * WIDTH; pos++) {
    // Mandelbrot calculation
}
```

### 2. Manual Complex Arithmetic
Replaced `std::complex` and `pow()` with manual arithmetic for better vectorization:
```cpp
// Instead of: z = pow(z, 2) + c;
const double real_z_new = real_z * real_z - imag_z * imag_z + real_c;
const double imag_z_new = 2.0 * real_z * imag_z + imag_c;
```

### 3. Vectorization Hints
```cpp
#pragma omp simd
for (int col = 0; col < WIDTH; col++) {
    // Inner loop optimized for SIMD
}
```

## Intel Advisor Analysis Results

### Serial Version Hotspots
- **Main computation loop** (line 43): 123.451s (86% of total time)
- **Outer loop overhead** (line 33): 0.064s
- **File I/O loops**: ~1.2s

### Parallel Version Analysis
- **Main computation loop** (line 51): 132.658s 
- **Limited scalability** due to memory bandwidth and loop structure
- **Thread overhead** slightly increased total time

## Key Findings

1. **Memory-bound workload**: The Mandelbrot calculation is memory-intensive, limiting parallel scalability
2. **Vectorization challenges**: Complex arithmetic doesn't vectorize well with standard library functions
3. **Optimal scheduling**: Static scheduling performed better than dynamic for this workload
4. **Manual optimization wins**: Hand-optimized code achieved 44% speedup over serial

## Recommendations for Further Optimization

1. **SIMD intrinsics**: Use Intel AVX-512 intrinsics for explicit vectorization
2. **Memory optimization**: Implement cache-blocking techniques
3. **GPU acceleration**: Consider CUDA or OpenCL implementation
4. **Algorithmic improvements**: Implement escape-time optimization or perturbation theory

## Build and Run Instructions

```bash
# Build all versions
make all

# Run performance comparison
make benchmark

# Run Intel Advisor analysis
make advisor-full

# Control OpenMP threads
OMP_NUM_THREADS=8 make run-parallel
```

## Intel Advisor Reports Location
- Serial analysis: `advisor_reports/serial_survey_report.txt`
- Parallel analysis: `advisor_reports/parallel_survey_report.txt`
