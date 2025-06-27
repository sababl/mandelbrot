#!/bin/bash

# Compare OpenMP Static vs Dynamic Scheduling Performance
# Analyzes the differences between the two scheduling approaches

STATIC_CSV="report/openmp_comprehensive_results.csv"
DYNAMIC_CSV="report/openmp_dynamic_specific_results.csv"
COMPARISON_REPORT="report/openmp_static_vs_dynamic_comparison.txt"

echo "=== OpenMP Static vs Dynamic Scheduling Comparison ===" > ${COMPARISON_REPORT}
echo "Generated: $(date)" >> ${COMPARISON_REPORT}
echo "Compiler: Intel C Compiler (icc) with -qopenmp" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}

# Extract matching configurations from static results
echo "=== Performance Comparison by Configuration ===" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}

# Define the configurations we want to compare
CONFIGS=(
    "1000 1000"   # 1000x1000, 1000 iterations
    "2000 1000"   # 2000x2000, 1000 iterations  
    "3000 1000"   # 3000x3000, 1000 iterations
    "1000 3000"   # 1000x1000, 3000 iterations
    "1000 5000"   # 1000x1000, 5000 iterations
)

for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    
    echo "--- Configuration: ${resolution}x${resolution}, ${iterations} iterations ---" >> ${COMPARISON_REPORT}
    echo "Threads | Static (ms) | Dynamic (ms) | Diff (ms) | Diff (%) | Better" >> ${COMPARISON_REPORT}
    echo "--------|-------------|--------------|-----------|----------|--------" >> ${COMPARISON_REPORT}
    
    # Compare each thread count for this configuration
    for threads in 64 32 24 16 8 4 2 1; do
        # Get static time
        static_time=$(grep "^${resolution},${iterations},${threads}," ${STATIC_CSV} 2>/dev/null | cut -d',' -f4)
        
        # Get dynamic time
        dynamic_time=$(grep "^${resolution},${iterations},${threads}," ${DYNAMIC_CSV} 2>/dev/null | cut -d',' -f4)
        
        if [ -n "$static_time" ] && [ -n "$dynamic_time" ]; then
            # Calculate difference
            diff_ms=$(echo "scale=3; $dynamic_time - $static_time" | bc -l)
            diff_percent=$(echo "scale=1; ($dynamic_time - $static_time) / $static_time * 100" | bc -l)
            
            # Determine which is better
            if [ $(echo "$dynamic_time < $static_time" | bc) -eq 1 ]; then
                better="Dynamic"
            else
                better="Static"
            fi
            
            printf "%-7s | %-11s | %-12s | %-9s | %-8s | %-6s\n" \
                "$threads" "$static_time" "$dynamic_time" "$diff_ms" "$diff_percent%" "$better" >> ${COMPARISON_REPORT}
        else
            printf "%-7s | %-11s | %-12s | %-9s | %-8s | %-6s\n" \
                "$threads" "${static_time:-N/A}" "${dynamic_time:-N/A}" "N/A" "N/A" "N/A" >> ${COMPARISON_REPORT}
        fi
    done
    
    # Find best performance for each scheduling type
    if [ -f "${STATIC_CSV}" ]; then
        static_best=$(grep "^${resolution},${iterations}," ${STATIC_CSV} | sort -t',' -k4 -n | head -1)
        if [ -n "$static_best" ]; then
            IFS=',' read -r _ _ s_threads s_time s_time_s s_speedup s_eff <<< "$static_best"
        fi
    fi
    
    if [ -f "${DYNAMIC_CSV}" ]; then
        dynamic_best=$(grep "^${resolution},${iterations}," ${DYNAMIC_CSV} | sort -t',' -k4 -n | head -1)
        if [ -n "$dynamic_best" ]; then
            IFS=',' read -r _ _ d_threads d_time d_time_s d_speedup d_eff <<< "$dynamic_best"
        fi
    fi
    
    echo "" >> ${COMPARISON_REPORT}
    echo "Best Static:  ${s_threads} threads, ${s_time} ms (${s_speedup}x speedup)" >> ${COMPARISON_REPORT}
    echo "Best Dynamic: ${d_threads} threads, ${d_time} ms (${d_speedup}x speedup)" >> ${COMPARISON_REPORT}
    
    if [ -n "$s_time" ] && [ -n "$d_time" ]; then
        if [ $(echo "$d_time < $s_time" | bc) -eq 1 ]; then
            improvement=$(echo "scale=1; ($s_time - $d_time) / $s_time * 100" | bc -l)
            echo "Winner: Dynamic (${improvement}% faster)" >> ${COMPARISON_REPORT}
        else
            degradation=$(echo "scale=1; ($d_time - $s_time) / $s_time * 100" | bc -l)
            echo "Winner: Static (${degradation}% faster)" >> ${COMPARISON_REPORT}
        fi
    fi
    
    echo "" >> ${COMPARISON_REPORT}
done

# Overall analysis
echo "=== Overall Analysis ===" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}

# Count wins for each scheduling type
static_wins=0
dynamic_wins=0
total_comparisons=0

for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    
    static_best_time=$(grep "^${resolution},${iterations}," ${STATIC_CSV} 2>/dev/null | sort -t',' -k4 -n | head -1 | cut -d',' -f4)
    dynamic_best_time=$(grep "^${resolution},${iterations}," ${DYNAMIC_CSV} 2>/dev/null | sort -t',' -k4 -n | head -1 | cut -d',' -f4)
    
    if [ -n "$static_best_time" ] && [ -n "$dynamic_best_time" ]; then
        total_comparisons=$((total_comparisons + 1))
        if [ $(echo "$dynamic_best_time < $static_best_time" | bc) -eq 1 ]; then
            dynamic_wins=$((dynamic_wins + 1))
        else
            static_wins=$((static_wins + 1))
        fi
    fi
done

echo "Performance Summary:" >> ${COMPARISON_REPORT}
echo "• Total configurations compared: ${total_comparisons}" >> ${COMPARISON_REPORT}
echo "• Static scheduling wins: ${static_wins}" >> ${COMPARISON_REPORT}
echo "• Dynamic scheduling wins: ${dynamic_wins}" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}

# Key insights
echo "=== Key Insights ===" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "1. Scheduling Overhead:" >> ${COMPARISON_REPORT}
echo "   • Dynamic scheduling introduces runtime overhead for work distribution" >> ${COMPARISON_REPORT}
echo "   • This overhead is more noticeable in regular computational patterns" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "2. Load Balancing:" >> ${COMPARISON_REPORT}
echo "   • Dynamic scheduling can provide better load balancing" >> ${COMPARISON_REPORT}
echo "   • Benefits are more apparent with irregular workloads" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "3. Problem Size Effects:" >> ${COMPARISON_REPORT}
echo "   • Larger problems may benefit more from dynamic scheduling" >> ${COMPARISON_REPORT}
echo "   • Smaller problems often perform better with static scheduling" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "4. Thread Count Impact:" >> ${COMPARISON_REPORT}
echo "   • Higher thread counts may show different relative performance" >> ${COMPARISON_REPORT}
echo "   • Dynamic scheduling optimal thread count may differ from static" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}

echo "=== Recommendations ===" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "1. For Mandelbrot Set Computation:" >> ${COMPARISON_REPORT}
echo "   • Static scheduling generally preferred for regular computation patterns" >> ${COMPARISON_REPORT}
echo "   • Dynamic scheduling may be beneficial for very large problems" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "2. General Guidelines:" >> ${COMPARISON_REPORT}
echo "   • Use static scheduling for predictable, regular workloads" >> ${COMPARISON_REPORT}
echo "   • Use dynamic scheduling for irregular or unpredictable workloads" >> ${COMPARISON_REPORT}
echo "   • Consider guided scheduling as a compromise between the two" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "3. Performance Tuning:" >> ${COMPARISON_REPORT}
echo "   • Test both scheduling types for your specific workload" >> ${COMPARISON_REPORT}
echo "   • Consider chunk size tuning for dynamic scheduling" >> ${COMPARISON_REPORT}
echo "   • Monitor load balancing effectiveness" >> ${COMPARISON_REPORT}

echo "Comparison analysis report generated: ${COMPARISON_REPORT}"
