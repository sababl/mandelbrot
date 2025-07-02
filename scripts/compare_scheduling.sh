#!/bin/bash

# Compare OpenMP Static vs Dynamic vs Guided Scheduling Performance
# Analyzes the differences between the three scheduling approaches

CONSOLIDATED_CSV="report/comprehensive_scheduling_results.csv"
COMPARISON_REPORT="report/openmp_scheduling_comparison.txt"

echo "=== OpenMP Static vs Dynamic vs Guided Scheduling Comparison ===" > ${COMPARISON_REPORT}
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
    echo "Threads | Static (ms) | Dynamic (ms) | Guided (ms) | Best    | Static vs Best | Dynamic vs Best | Guided vs Best" >> ${COMPARISON_REPORT}
    echo "--------|-------------|--------------|-------------|---------|----------------|-----------------|----------------" >> ${COMPARISON_REPORT}
    
    # Compare each thread count for this configuration
    for threads in 64 32 24 16 8 4 2 1; do
        # Get times for each scheduling type from consolidated CSV
        static_time=$(grep "^static,${resolution},${iterations},${threads}," ${CONSOLIDATED_CSV} 2>/dev/null | cut -d',' -f5)
        dynamic_time=$(grep "^dynamic,${resolution},${iterations},${threads}," ${CONSOLIDATED_CSV} 2>/dev/null | cut -d',' -f5)
        guided_time=$(grep "^guided,${resolution},${iterations},${threads}," ${CONSOLIDATED_CSV} 2>/dev/null | cut -d',' -f5)
        
        if [ -n "$static_time" ] || [ -n "$dynamic_time" ] || [ -n "$guided_time" ]; then
            # Find the best time among the three
            best_time=""
            best_type=""
            
            # Initialize with first available time
            if [ -n "$static_time" ]; then
                best_time="$static_time"
                best_type="Static"
            elif [ -n "$dynamic_time" ]; then
                best_time="$dynamic_time"
                best_type="Dynamic"
            elif [ -n "$guided_time" ]; then
                best_time="$guided_time"
                best_type="Guided"
            fi
            
            # Compare with dynamic if available
            if [ -n "$dynamic_time" ] && [ -n "$best_time" ]; then
                if [ $(echo "$dynamic_time < $best_time" | bc) -eq 1 ]; then
                    best_time="$dynamic_time"
                    best_type="Dynamic"
                fi
            fi
            
            # Compare with guided if available
            if [ -n "$guided_time" ] && [ -n "$best_time" ]; then
                if [ $(echo "$guided_time < $best_time" | bc) -eq 1 ]; then
                    best_time="$guided_time"
                    best_type="Guided"
                fi
            fi
            
            # Calculate differences from best
            static_diff=""
            dynamic_diff=""
            guided_diff=""
            
            if [ -n "$static_time" ] && [ -n "$best_time" ]; then
                static_diff=$(echo "scale=1; ($static_time - $best_time) / $best_time * 100" | bc -l)
                static_diff="${static_diff}%"
            else
                static_diff="N/A"
            fi
            
            if [ -n "$dynamic_time" ] && [ -n "$best_time" ]; then
                dynamic_diff=$(echo "scale=1; ($dynamic_time - $best_time) / $best_time * 100" | bc -l)
                dynamic_diff="${dynamic_diff}%"
            else
                dynamic_diff="N/A"
            fi
            
            if [ -n "$guided_time" ] && [ -n "$best_time" ]; then
                guided_diff=$(echo "scale=1; ($guided_time - $best_time) / $best_time * 100" | bc -l)
                guided_diff="${guided_diff}%"
            else
                guided_diff="N/A"
            fi
            
            printf "%-7s | %-11s | %-12s | %-11s | %-7s | %-14s | %-15s | %-14s\n" \
                "$threads" "${static_time:-N/A}" "${dynamic_time:-N/A}" "${guided_time:-N/A}" "$best_type" "$static_diff" "$dynamic_diff" "$guided_diff" >> ${COMPARISON_REPORT}
        else
            printf "%-7s | %-11s | %-12s | %-11s | %-7s | %-14s | %-15s | %-14s\n" \
                "$threads" "N/A" "N/A" "N/A" "N/A" "N/A" "N/A" "N/A" >> ${COMPARISON_REPORT}
        fi
    done
    
    # Find best performance for each scheduling type
    static_best=""
    dynamic_best=""
    guided_best=""
    
    if [ -f "${CONSOLIDATED_CSV}" ]; then
        static_best=$(grep "^static,${resolution},${iterations}," ${CONSOLIDATED_CSV} | sort -t',' -k5 -n | head -1)
        dynamic_best=$(grep "^dynamic,${resolution},${iterations}," ${CONSOLIDATED_CSV} | sort -t',' -k5 -n | head -1)
        guided_best=$(grep "^guided,${resolution},${iterations}," ${CONSOLIDATED_CSV} | sort -t',' -k5 -n | head -1)
        
        if [ -n "$static_best" ]; then
            IFS=',' read -r _ _ _ s_threads s_time s_speedup s_eff _ <<< "$static_best"
        fi
        
        if [ -n "$dynamic_best" ]; then
            IFS=',' read -r _ _ _ d_threads d_time d_speedup d_eff _ <<< "$dynamic_best"
        fi
        
        if [ -n "$guided_best" ]; then
            IFS=',' read -r _ _ _ g_threads g_time g_speedup g_eff _ <<< "$guided_best"
        fi
    fi
    
    echo "" >> ${COMPARISON_REPORT}
    echo "Best Results:" >> ${COMPARISON_REPORT}
    if [ -n "$static_best" ]; then
        echo "• Static:  ${s_threads} threads, ${s_time} ms (${s_speedup}x speedup)" >> ${COMPARISON_REPORT}
    fi
    if [ -n "$dynamic_best" ]; then
        echo "• Dynamic: ${d_threads} threads, ${d_time} ms (${d_speedup}x speedup)" >> ${COMPARISON_REPORT}
    fi
    if [ -n "$guided_best" ]; then
        echo "• Guided:  ${g_threads} threads, ${g_time} ms (${g_speedup}x speedup)" >> ${COMPARISON_REPORT}
    fi
    
    # Determine overall winner for this configuration
    overall_best_time=""
    overall_best_type=""
    
    if [ -n "$s_time" ]; then
        overall_best_time="$s_time"
        overall_best_type="Static"
    fi
    
    if [ -n "$d_time" ] && [ -n "$overall_best_time" ]; then
        if [ $(echo "$d_time < $overall_best_time" | bc) -eq 1 ]; then
            overall_best_time="$d_time"
            overall_best_type="Dynamic"
        fi
    elif [ -n "$d_time" ]; then
        overall_best_time="$d_time"
        overall_best_type="Dynamic"
    fi
    
    if [ -n "$g_time" ] && [ -n "$overall_best_time" ]; then
        if [ $(echo "$g_time < $overall_best_time" | bc) -eq 1 ]; then
            overall_best_time="$g_time"
            overall_best_type="Guided"
        fi
    elif [ -n "$g_time" ]; then
        overall_best_time="$g_time"
        overall_best_type="Guided"
    fi
    
    if [ -n "$overall_best_type" ]; then
        echo "→ Winner: ${overall_best_type} scheduling (${overall_best_time} ms)" >> ${COMPARISON_REPORT}
    fi
    
    echo "" >> ${COMPARISON_REPORT}
done

# Overall analysis
echo "=== Overall Analysis ===" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}

# Count wins for each scheduling type
static_wins=0
dynamic_wins=0
guided_wins=0
total_comparisons=0

for config in "${CONFIGS[@]}"; do
    resolution=${config%% *}
    iterations=${config##* }
    
    static_best_time=$(grep "^static,${resolution},${iterations}," ${CONSOLIDATED_CSV} 2>/dev/null | sort -t',' -k5 -n | head -1 | cut -d',' -f5)
    dynamic_best_time=$(grep "^dynamic,${resolution},${iterations}," ${CONSOLIDATED_CSV} 2>/dev/null | sort -t',' -k5 -n | head -1 | cut -d',' -f5)
    guided_best_time=$(grep "^guided,${resolution},${iterations}," ${CONSOLIDATED_CSV} 2>/dev/null | sort -t',' -k5 -n | head -1 | cut -d',' -f5)
    
    if [ -n "$static_best_time" ] || [ -n "$dynamic_best_time" ] || [ -n "$guided_best_time" ]; then
        total_comparisons=$((total_comparisons + 1))
        
        # Find the overall best
        best_time=""
        best_type=""
        
        if [ -n "$static_best_time" ]; then
            best_time="$static_best_time"
            best_type="static"
        fi
        
        if [ -n "$dynamic_best_time" ] && [ -n "$best_time" ]; then
            if [ $(echo "$dynamic_best_time < $best_time" | bc) -eq 1 ]; then
                best_time="$dynamic_best_time"
                best_type="dynamic"
            fi
        elif [ -n "$dynamic_best_time" ]; then
            best_time="$dynamic_best_time"
            best_type="dynamic"
        fi
        
        if [ -n "$guided_best_time" ] && [ -n "$best_time" ]; then
            if [ $(echo "$guided_best_time < $best_time" | bc) -eq 1 ]; then
                best_time="$guided_best_time"
                best_type="guided"
            fi
        elif [ -n "$guided_best_time" ]; then
            best_time="$guided_best_time"
            best_type="guided"
        fi
        
        case "$best_type" in
            "static") static_wins=$((static_wins + 1)) ;;
            "dynamic") dynamic_wins=$((dynamic_wins + 1)) ;;
            "guided") guided_wins=$((guided_wins + 1)) ;;
        esac
    fi
done

echo "Performance Summary:" >> ${COMPARISON_REPORT}
echo "• Total configurations compared: ${total_comparisons}" >> ${COMPARISON_REPORT}
echo "• Static scheduling wins: ${static_wins}" >> ${COMPARISON_REPORT}
echo "• Dynamic scheduling wins: ${dynamic_wins}" >> ${COMPARISON_REPORT}
echo "• Guided scheduling wins: ${guided_wins}" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}

# Key insights
echo "=== Key Insights ===" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "1. Scheduling Overhead:" >> ${COMPARISON_REPORT}
echo "   • Static: Minimal overhead, work distributed at compile time" >> ${COMPARISON_REPORT}
echo "   • Dynamic: Runtime overhead for work distribution" >> ${COMPARISON_REPORT}
echo "   • Guided: Adaptive overhead, starts with large chunks, decreases over time" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "2. Load Balancing:" >> ${COMPARISON_REPORT}
echo "   • Static: Poor load balancing for irregular workloads" >> ${COMPARISON_REPORT}
echo "   • Dynamic: Excellent load balancing but with overhead cost" >> ${COMPARISON_REPORT}
echo "   • Guided: Good compromise between load balancing and overhead" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "3. Problem Size Effects:" >> ${COMPARISON_REPORT}
echo "   • Larger problems: Dynamic and guided may show benefits" >> ${COMPARISON_REPORT}
echo "   • Smaller problems: Static often performs best due to low overhead" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "4. Thread Count Impact:" >> ${COMPARISON_REPORT}
echo "   • Higher thread counts: Guided often shows best scaling" >> ${COMPARISON_REPORT}
echo "   • Lower thread counts: Static often sufficient" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}

echo "=== Recommendations ===" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "1. For Mandelbrot Set Computation:" >> ${COMPARISON_REPORT}
echo "   • Regular computation patterns favor static scheduling" >> ${COMPARISON_REPORT}
echo "   • Guided scheduling provides good balance for various problem sizes" >> ${COMPARISON_REPORT}
echo "   • Dynamic scheduling best for highly irregular workloads" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "2. General Guidelines:" >> ${COMPARISON_REPORT}
echo "   • Static: Use for predictable, regular workloads with low overhead priority" >> ${COMPARISON_REPORT}
echo "   • Dynamic: Use for highly irregular or unpredictable workloads" >> ${COMPARISON_REPORT}
echo "   • Guided: Use as default choice for unknown workload characteristics" >> ${COMPARISON_REPORT}
echo "" >> ${COMPARISON_REPORT}
echo "3. Performance Tuning:" >> ${COMPARISON_REPORT}
echo "   • Test all three scheduling types for your specific workload" >> ${COMPARISON_REPORT}
echo "   • Consider chunk size tuning for dynamic and guided scheduling" >> ${COMPARISON_REPORT}
echo "   • Monitor scaling behavior with increasing thread counts" >> ${COMPARISON_REPORT}
echo "   • Profile load balancing effectiveness" >> ${COMPARISON_REPORT}

echo "Comparison analysis report generated: ${COMPARISON_REPORT}"
