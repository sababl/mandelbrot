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

### 4. OpenMP Guided Scheduling Analysis ✅
**Comprehensive adaptive load balancing analysis:**

**Configurations Tested**:
- Same 5 configurations as dynamic for direct comparison
- 1000×1000 resolution (1000, 3000, 5000 iterations)
- 2000×2000 resolution, 1000 iterations  
- 3000×3000 resolution, 1000 iterations
- **Thread Counts**: 64, 32, 24, 16, 8, 4, 2, 1 (40 total configurations)

**Methodology**:
- Adaptive chunk sizing (starts large, reduces progressively)
- Hybrid approach combining static predictability with dynamic flexibility
- Direct comparison with both static and dynamic results
- Intel C++ Compiler (icc) with -qopenmp

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

### 3. OpenMP Guided Scheduling Performance

**Best Performance by Configuration:**
| Configuration    | Best Threads | Time (ms) | Speedup | Efficiency | vs Best |
|------------------|--------------|-----------|---------|------------|---------|
| 1000×1000, 1000  | 32           | 671       | 11.86×  | 37.0%      | +37.0%  |
| 2000×2000, 1000  | 32           | 2,665     | 11.92×  | 37.3%      | +36.8%  |
| 3000×3000, 1000  | 64           | 6,060     | 11.78×  | 18.4%      | +35.9%  |
| 1000×1000, 3000  | 24           | 1,714     | 13.38×  | 55.8%      | +39.4%  |
| 1000×1000, 5000  | 24           | 2,772     | 13.67×  | 57.0%      | +39.6%  |

### 4. Three-Way Scheduling Comparison

**Overall Performance Ranking:**
1. **Guided Scheduling**: Wins all 5 configurations, 37.7% average improvement
2. **Dynamic Scheduling**: Highest speedups (up to 13.96×), best for maximum performance  
3. **Static Scheduling**: Most predictable, good baseline performance

**Key Differences:**
- **Guided**: Best overall performance, good balance of speed and predictability
- **Dynamic**: Highest peak speedups, best efficiency at 24-32 threads
- **Static**: Most consistent, optimal at 64 threads with lower efficiency

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

### Consolidated Performance Data
1. **`openmp_consolidated_results.csv`** - Complete OpenMP data (152 configurations: static, dynamic, guided)
2. **`sequential_consolidated_results.csv`** - Sequential compiler flags and scaling analysis

### Comprehensive Analysis
3. **`openmp_complete_analysis.txt`** - Complete three-way OpenMP scheduling analysis including:
   - Static scheduling detailed results (72 configurations)
   - Dynamic scheduling detailed results (40 configurations)  
   - Guided scheduling detailed results (40 configurations)
   - Head-to-head performance comparison
   - Technical insights and recommendations

### Benchmark Results
4. **`seq-1000.svg`** - Sequential performance visualization

## Implementation Files

### Source Code
- **`openmp/openmp_static_parametric.cpp`** - Configurable static scheduling implementation
- **`openmp/openmp_dynamic_parametric.cpp`** - Configurable dynamic scheduling implementation
- **`openmp/openmp_guided_parametric.cpp`** - Configurable guided scheduling implementation
- **`sequential/mandelbrot.cpp`** - Sequential reference implementation

### Executables
- **`openmp/mandelbrot_static_parametric`** - Compiled static version
- **`openmp/mandelbrot_dynamic_parametric`** - Compiled dynamic version
- **`openmp/mandelbrot_guided_parametric`** - Compiled guided version
- **`sequential/mandelbrot`** - Compiled sequential version

### Benchmark Scripts
- **`scripts/comprehensive_openmp_benchmark.sh`** - Complete static analysis automation
- **`scripts/openmp_dynamic_benchmark.sh`** - Dynamic scheduling benchmark
- **`scripts/openmp_guided_benchmark.sh`** - Guided scheduling benchmark
- **`scripts/benchmark_flags.sh`** - Sequential compiler optimization testing
- **`scripts/benchmark_resolution_iterations.sh`** - Sequential scaling analysis
- **`scripts/compare_scheduling.sh`** - Cross-scheduling comparison utilities

## Recommendations

### For Maximum Performance
- **Use Guided Scheduling** with 24-32 threads
- **Expected Performance**: 37.7% faster than other scheduling approaches
- **Best for**: Highest throughput requirements, dedicated compute workloads
- **Optimal Configurations**: All problem sizes tested

### For Highest Speedups
- **Use Dynamic Scheduling** with 24-32 threads  
- **Expected Performance**: Up to 13.96× speedup over sequential
- **Best for**: Maximum parallelization efficiency, irregular workloads
- **Optimal Configurations**: Medium to large problem sizes

### For Balanced Performance/Efficiency
- **Use Guided Scheduling** with 16-24 threads
- **Resource Usage**: Moderate CPU utilization with good performance
- **Best for**: Production environments, shared compute resources
- **Efficiency**: 55-60% at optimal thread counts

### For Resource Efficiency
- **Use any scheduling approach** with 2-4 threads for high efficiency (>90%)
- **Memory Usage**: Minimal overhead
- **Best for**: Shared systems, background processing, energy-conscious computing

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
1. **MPI Implementation** - Distributed memory parallelization
2. **CUDA Version** - GPU acceleration analysis
3. **Hybrid Approaches** - OpenMP + MPI or OpenMP + CUDA
4. **Algorithm Optimization** - Core computation improvements
5. **Memory Optimization** - Cache efficiency analysis
6. **Vectorization Analysis** - SIMD instruction utilization
7. **Chunk Size Optimization** - Fine-tuning guided scheduling parameters

### Research Extensions
- **Irregular Problem Sizes** - Non-square resolutions
- **Variable Iteration Limits** - Adaptive computation
- **Different Compiler Comparisons** - GCC vs Intel vs Clang
- **Performance Profiling** - Detailed bottleneck analysis
- **Energy Efficiency** - Performance per watt analysis

---

## Summary

This comprehensive analysis demonstrates that **guided scheduling provides superior performance** for Mandelbrot set computation, with **37.7% average improvements** over other scheduling approaches across all tested configurations. 

**Key Findings:**
- **Guided scheduling** wins all 5 configurations tested
- **Dynamic scheduling** achieves highest speedups (up to 13.96×)
- **Static scheduling** provides predictable baseline performance
- **Optimal thread count** is typically 24-32 for guided and dynamic scheduling

The complete three-way analysis establishes guided scheduling as the optimal choice for most scenarios, while dynamic scheduling excels for maximum performance requirements. This study provides a solid foundation for production deployment decisions and future parallelization research.

---

*Project Duration*: June 26-30, 2025  
*Total Configurations Tested*: 152 (72 static + 40 dynamic + 40 guided)  
*Total Execution Time*: ~6 hours for complete benchmark suite  
*Compiler*: Intel C++ Compiler (icc) with OpenMP support
