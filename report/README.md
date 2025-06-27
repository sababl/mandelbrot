# Mandelbrot Set Performance Analysis - Comprehensive Study

## Project Overview

**Objective**: Comprehensive analysis of Mandelbrot set computation performance using different parallelization approaches and configurations with Intel C++ compiler.

**Research Focus**: Compare sequential vs parallel implementations, analyze scaling behavior, and determine optimal configurations for different problem sizes.

## Completed Analyses

### 1. Sequential Implementation Analysis ✅
- **Compiler**: Intel C++ Compiler (icc) with optimization flags
- **Baseline Performance**: Established reference metrics for parallel comparison
- **Optimization Flags**: Tested various compiler optimizations (-O0, -O1, -O2, -O3, -xhost)

### 2. OpenMP Static Scheduling Analysis ✅
**Comprehensive benchmark across multiple configurations:**

**Configurations Tested**:
- **Resolutions**: 1000×1000, 2000×2000, 3000×3000
- **Iterations**: 1000, 3000, 5000  
- **Thread Counts**: 64, 32, 24, 16, 8, 4, 2, 1
- **Total Configurations**: 72 (3 × 3 × 8)

**Methodology**:
- High-precision nanosecond timing (best of 3 runs)
- Intel C++ Compiler (icc) with -qopenmp
- Static work distribution for predictable load balancing

### 3. OpenMP Dynamic Scheduling Analysis ✅
**Targeted analysis of specific configurations:**

**Configurations Tested**:
- 1000×1000 resolution, 1000 iterations
- 2000×2000 resolution, 1000 iterations  
- 3000×3000 resolution, 1000 iterations
- 1000×1000 resolution, 3000 iterations
- 1000×1000 resolution, 5000 iterations
- **Thread Counts**: 64, 32, 24, 16, 8, 4, 2, 1 (40 total configurations)

**Methodology**:
- Runtime work distribution for better load balancing
- Direct comparison with static scheduling results
- Same precision timing and compiler setup

## Key Results Summary

### 1. OpenMP Static Scheduling Performance

**Best Performance by Configuration:**
| Resolution | Iterations | Best Threads | Time (ms) | Speedup | Efficiency |
|------------|------------|--------------|-----------|---------|------------|
| 1000×1000  | 1000       | 64           | 1,251     | 10.58×  | 16.5%      |
| 1000×1000  | 3000       | 64           | 3,064     | 12.62×  | 19.7%      |
| 1000×1000  | 5000       | 64           | 5,104     | 12.55×  | 19.6%      |
| 2000×2000  | 1000       | 64           | 4,732     | 11.19×  | 17.5%      |
| 2000×2000  | 3000       | 64           | 11,848    | 13.05×  | 20.4%      |
| 2000×2000  | 5000       | 64           | 20,054    | 12.78×  | 20.0%      |
| 3000×3000  | 1000       | 64           | 10,157    | 11.73×  | 18.3%      |
| 3000×3000  | 3000       | 64           | 27,198    | 12.80×  | 20.0%      |
| 3000×3000  | 5000       | 64           | 44,127    | 13.07×  | 20.4%      |

### 2. OpenMP Dynamic Scheduling Performance

**Best Performance by Configuration:**
| Configuration    | Best Threads | Time (ms) | Speedup | Efficiency | vs Static |
|------------------|--------------|-----------|---------|------------|-----------|
| 1000×1000, 1000  | 32           | 1,066     | 12.41×  | 38.8%      | +14.8%    |
| 2000×2000, 1000  | 64           | 4,217     | 12.55×  | 19.6%      | +10.9%    |
| 3000×3000, 1000  | 24           | 9,460     | 12.59×  | 52.5%      | +6.9%     |
| 1000×1000, 3000  | 24           | 2,829     | 13.67×  | 57.0%      | +16.5%    |
| 1000×1000, 5000  | 24           | 4,590     | 13.96×  | 58.2%      | +10.1%    |

### 3. Static vs Dynamic Scheduling Comparison

**Overall Winner: Dynamic Scheduling**
- **Configurations Compared**: 5
- **Dynamic Wins**: 5 (100%)
- **Average Improvement**: 11.8% faster than static
- **Range**: 6.9% to 16.5% improvement

**Key Differences:**
- **Dynamic**: Better load balancing, optimal at 24-32 threads
- **Static**: More predictable, optimal at 64 threads
- **Dynamic**: Higher efficiency at moderate thread counts
- **Static**: More consistent across different problem sizes

## Performance Insights

### Scaling Characteristics
- **Linear Scaling Region**: 1-2 threads (>90% efficiency)
- **Good Scaling Region**: 2-16 threads (40-70% efficiency)  
- **Diminishing Returns**: Beyond 32 threads
- **Resource Efficiency Sweet Spot**: 4-8 threads for balanced environments

### Problem Size Effects
- **Larger problems** show better parallel efficiency
- **Memory bandwidth** becomes limiting factor for very large problems
- **Compute intensity** scales well with iteration count
- **Dynamic scheduling** benefits increase with problem irregularity

### Thread Count Optimization
- **Static scheduling**: 64 threads consistently optimal
- **Dynamic scheduling**: 24-32 threads optimal for most configurations
- **Efficiency consideration**: 2-4 threads for resource-constrained environments
- **Load balancing**: Dynamic shows better distribution across thread counts

## Generated Data Files

### Raw Performance Data
1. **`openmp_comprehensive_results.csv`** - Complete static scheduling data (72 configurations)
2. **`openmp_dynamic_specific_results.csv`** - Dynamic scheduling data (40 configurations)

### Analysis Reports
3. **`openmp_comprehensive_analysis.txt`** - Detailed static scheduling technical analysis
4. **`openmp_comprehensive_summary.txt`** - Static scheduling executive summary  
5. **`openmp_dynamic_specific_analysis.txt`** - Dynamic scheduling detailed analysis
6. **`openmp_static_vs_dynamic_comparison.txt`** - Head-to-head scheduling comparison

### Benchmark Results
7. **`flag_benchmark_results_sequential.csv`** - Sequential optimization analysis
8. **`resolution_iterations_benchmark_sequential.csv`** - Sequential scaling analysis

## Implementation Files

### Source Code
- **`openmp/openmp_static_parametric.cpp`** - Configurable static scheduling implementation
- **`openmp/openmp_dynamic_parametric.cpp`** - Configurable dynamic scheduling implementation
- **`sequential/mandelbrot.cpp`** - Sequential reference implementation

### Executables
- **`openmp/mandelbrot_static_parametric`** - Compiled static version
- **`openmp/mandelbrot_dynamic_parametric`** - Compiled dynamic version
- **`sequential/mandelbrot`** - Compiled sequential version

### Benchmark Scripts
- **`comprehensive_openmp_benchmark.sh`** - Complete static analysis automation
- **`benchmark_flags.sh`** - Sequential optimization testing
- **`benchmark_resolution_iterations.sh`** - Sequential scaling testing

## Recommendations

### For Maximum Performance
- **Use Dynamic Scheduling** with 24-32 threads
- **Expected Performance**: 7-17% faster than static scheduling
- **Best for**: Batch processing, dedicated compute workloads
- **Optimal Configurations**: Medium to large problem sizes

### For Balanced Performance/Efficiency
- **Static Scheduling**: 16-32 threads depending on problem size
- **Dynamic Scheduling**: 24 threads for most configurations
- **Resource Usage**: Moderate CPU utilization
- **Best for**: Shared compute environments

### For Resource Efficiency
- **Use 2-4 threads** for high efficiency (>90%)
- **Both scheduling types** perform similarly at low thread counts
- **Memory Usage**: Minimal overhead
- **Best for**: Shared systems, background processing

### Problem Size Specific
- **Small Problems** (1000×1000): Dynamic scheduling with 24-32 threads
- **Medium Problems** (2000×2000): Dynamic scheduling with 32 threads  
- **Large Problems** (3000×3000): Dynamic scheduling with 24-64 threads

## Technical Specifications

### Compiler Configuration
- **Compiler**: Intel C++ Compiler (icc) 
- **Optimization**: -O2 -qopenmp
- **Target Architecture**: x86_64
- **OpenMP Version**: 4.0+

### System Considerations
- **Memory Bandwidth**: Monitor utilization with large problems
- **NUMA Topology**: Consider effects for >32 threads
- **Thread Affinity**: May improve consistency
- **System Load**: Balance with other workloads in production

### Measurement Methodology
- **Timing Precision**: Nanosecond resolution
- **Statistical Approach**: Best of 3 runs per configuration
- **Baseline Establishment**: Single-threaded reference for speedup calculations
- **Load Balancing**: Work distribution analysis included

## Future Work

### Potential Next Steps
1. **OpenMP Guided Scheduling** - Hybrid approach analysis
2. **MPI Implementation** - Distributed memory parallelization
3. **CUDA Version** - GPU acceleration analysis
4. **Hybrid Approaches** - OpenMP + MPI or OpenMP + CUDA
5. **Algorithm Optimization** - Core computation improvements
6. **Memory Optimization** - Cache efficiency analysis
7. **Vectorization Analysis** - SIMD instruction utilization

### Research Extensions
- **Irregular Problem Sizes** - Non-square resolutions
- **Variable Iteration Limits** - Adaptive computation
- **Different Compiler Comparisons** - GCC vs Intel vs Clang
- **Performance Profiling** - Detailed bottleneck analysis
- **Energy Efficiency** - Performance per watt analysis

---

## Summary

This comprehensive analysis demonstrates that **dynamic scheduling provides superior performance** for Mandelbrot set computation, with **7-17% improvements** over static scheduling across all tested configurations. The optimal configuration for most scenarios is **dynamic scheduling with 24-32 threads**, providing the best balance of performance and resource efficiency.

The study establishes a solid foundation for comparing other parallelization approaches and provides actionable recommendations for production deployment.

---

*Project Duration*: June 26-27, 2025  
*Total Configurations Tested*: 112 (72 static + 40 dynamic)  
*Total Execution Time*: ~4 hours for complete benchmark suite  
*Compiler*: Intel C++ Compiler (icc) with OpenMP support
