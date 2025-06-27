# OpenMP Static Mandelbrot - Comprehensive Benchmark Results

## Experiment Overview

**Objective**: Analyze OpenMP static scheduling performance across different problem sizes and thread counts

**Configurations Tested**:
- **Resolutions**: 1000x1000, 2000x2000, 3000x3000
- **Iterations**: 1000, 3000, 5000  
- **Thread Counts**: 64, 32, 24, 16, 8, 4, 2, 1
- **Total Configurations**: 72 (3 × 3 × 8)

**Methodology**:
- High-precision nanosecond timing
- Best of 3 runs per configuration
- Intel C++ Compiler (icpc) with -qopenmp
- Static scheduling for load balancing

## Key Results

### Best Performance by Configuration
| Resolution | Iterations | Best Threads | Time (ms) | Speedup | Efficiency |
|------------|------------|--------------|-----------|---------|------------|
| 1000x1000  | 1000       | 64           | 1,251     | 10.58x  | 16.5%      |
| 1000x1000  | 3000       | 64           | 3,064     | 12.62x  | 19.7%      |
| 1000x1000  | 5000       | 64           | 5,104     | 12.55x  | 19.6%      |
| 2000x2000  | 1000       | 64           | 4,732     | 11.19x  | 17.5%      |
| 2000x2000  | 3000       | 64           | 11,848    | 13.05x  | 20.4%      |
| 2000x2000  | 5000       | 64           | 20,054    | 12.78x  | 20.0%      |
| 3000x3000  | 1000       | 64           | 10,157    | 11.73x  | 18.3%      |
| 3000x3000  | 3000       | 64           | 27,198    | 12.80x  | 20.0%      |
| 3000x3000  | 5000       | 64           | 44,127    | 13.07x  | 20.4%      |

### Key Findings

1. **Optimal Thread Count**: 64 threads consistently provides best performance across all configurations
2. **Maximum Speedup**: 13.07x achieved with 3000x3000 resolution, 5000 iterations
3. **Scaling Efficiency**: Linear scaling up to 2 threads (>95% efficiency), good scaling up to 16 threads (>40% efficiency)
4. **Problem Size Effect**: Larger problems show better parallel efficiency
5. **Iteration Impact**: Higher iteration counts improve speedup ratios

### Performance Patterns

- **Linear Scaling Region**: 1-2 threads (>90% efficiency)
- **Good Scaling Region**: 2-16 threads (40-60% efficiency)  
- **Diminishing Returns**: Beyond 32 threads
- **Resource Efficiency Sweet Spot**: 4-8 threads

## Files Generated

1. **`report/openmp_comprehensive_results.csv`** - Complete raw data (72 configurations)
2. **`report/openmp_comprehensive_analysis.txt`** - Detailed technical analysis
3. **`report/openmp_comprehensive_summary.txt`** - Executive summary with insights

## Recommendations

### Production Deployment
- **Maximum Performance**: Use 64 threads
- **Balanced Performance**: Use 16-32 threads depending on problem size
- **Resource Efficient**: Use 4-8 threads for shared environments

### Problem Size Considerations
- **Small Problems** (1000x1000): 16 threads optimal balance
- **Medium Problems** (2000x2000): 32 threads recommended
- **Large Problems** (3000x3000): 64 threads for maximum performance

### System Considerations
- Monitor memory bandwidth utilization with large problems
- Consider NUMA topology effects for >32 threads
- Balance with other system workloads in production

## Technical Notes

- Static scheduling provides consistent performance for regular workloads
- Memory bandwidth becomes limiting factor for very large problems
- Compute intensity scales well with iteration count
- Intel Compiler optimization flags: -O2 -qopenmp

---
*Generated: June 27, 2025*  
*Execution Time: ~2.5 hours for complete benchmark suite*
