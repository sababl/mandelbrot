#!/usr/bin/env python3
"""
Mandelbrot Performance Analysis Chart Generator
Generates comprehensive charts from all CSV data in the repository
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import os
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

# Set up plotting style
plt.style.use('seaborn-v0_8')
sns.set_palette("husl")
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 10

def load_data():
    """Load all CSV data files"""
    data = {}
    
    # Sequential data
    data['sequential'] = pd.read_csv('report/sequential_consolidated_results.csv')
    
    # OpenMP data
    data['openmp_consolidated'] = pd.read_csv('report/openmp_consolidated_results.csv')
    data['openmp_static'] = pd.read_csv('openmp/output_static.csv')
    data['openmp_dynamic'] = pd.read_csv('openmp/output_dynamic.csv') 
    data['openmp_guided'] = pd.read_csv('openmp/output_guided.csv')
    data['comprehensive_scheduling'] = pd.read_csv('report/comprehensive_scheduling_results.csv')
    
    # MPI data
    data['mpi'] = pd.read_csv('report/mpi_performance_results.csv')
    
    # Hybrid data
    data['hybrid'] = pd.read_csv('report/hybrid_performance_results.csv')
    
    # CUDA data
    data['cuda'] = pd.read_csv('cuda/cuda_report.csv')
    
    # Compiler optimization data
    compiler_files = [
        'report/images/mandelbrot__O0.csv',
        'report/images/mandelbrot__O1.csv', 
        'report/images/mandelbrot__O2.csv',
        'report/images/mandelbrot__O3.csv',
        'report/images/mandelbrot__xhost.csv',
        'report/images/mandelbrot__xSSE3.csv',
        'report/images/mandelbrot__fast.csv'
    ]
    
    compiler_data = []
    for file in compiler_files:
        if os.path.exists(file):
            flag = file.split('__')[1].split('.')[0]
            df = pd.read_csv(file)
            df['compiler_flag'] = flag
            compiler_data.append(df)
    
    if compiler_data:
        data['compiler'] = pd.concat(compiler_data, ignore_index=True)
    
    return data

def create_sequential_analysis_charts(data):
    """Generate charts for sequential analysis section"""
    
    seq_data = data['sequential']
    
    # Chart 1: Compiler Optimization Impact
    fig, ax = plt.subplots(figsize=(10, 6))
    compiler_data = seq_data[seq_data['benchmark_type'] == 'compiler_flags']
    
    if not compiler_data.empty:
        flags = compiler_data['flag_or_config'].tolist()
        times = compiler_data['execution_time_ms'].tolist()
        
        ax.bar(flags, times, color='steelblue', alpha=0.7)
        ax.set_title('Sequential Performance: Compiler Optimization Impact')
        ax.set_xlabel('Compiler Flag')
        ax.set_ylabel('Execution Time (ms)')
        ax.tick_params(axis='x', rotation=45)
        ax.grid(True, alpha=0.3, axis='y')
        
        plt.tight_layout()
        plt.savefig('charts/sequential_compiler_optimization.png', dpi=300, bbox_inches='tight')
        plt.close()
    
    # Chart 2: Problem Size Scaling
    fig, ax = plt.subplots(figsize=(10, 6))
    scaling_data = seq_data[seq_data['benchmark_type'] == 'scaling_analysis']
    
    # Group by resolution
    for resolution in scaling_data['flag_or_config'].unique():
        if 'x' in str(resolution):
            res_data = scaling_data[scaling_data['flag_or_config'] == resolution]
            ax.plot(res_data['iterations'], res_data['execution_time_ms'], 
                    marker='o', label=f'{resolution}', linewidth=2)
    
    ax.set_title('Sequential Performance: Problem Size Scaling')
    ax.set_xlabel('Iterations')
    ax.set_ylabel('Execution Time (ms)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('charts/sequential_scaling_analysis.png', dpi=300, bbox_inches='tight')
    plt.close()

def create_openmp_analysis_charts(data):
    """Generate charts for OpenMP analysis section"""
    
    sched_data = data['comprehensive_scheduling']
    
    # Chart 1: OpenMP Speedup Comparison
    fig, ax = plt.subplots(figsize=(10, 6))
    for sched_type in ['static', 'dynamic', 'guided']:
        type_data = sched_data[sched_data['scheduling_type'] == sched_type]
        if not type_data.empty:
            config_data = type_data[(type_data['resolution'] == 1000) & 
                                  (type_data['iterations'] == 1000)]
            if not config_data.empty:
                ax.plot(config_data['threads'], config_data['speedup'], 
                        marker='o', label=f'{sched_type.title()}', linewidth=2)
    
    ax.set_title('OpenMP Speedup Comparison (1000×1000, 1000 iterations)')
    ax.set_xlabel('Thread Count')
    ax.set_ylabel('Speedup')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/openmp_speedup_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 2: OpenMP Efficiency Comparison
    fig, ax = plt.subplots(figsize=(10, 6))
    for sched_type in ['static', 'dynamic', 'guided']:
        type_data = sched_data[sched_data['scheduling_type'] == sched_type]
        if not type_data.empty:
            config_data = type_data[(type_data['resolution'] == 1000) & 
                                  (type_data['iterations'] == 1000)]
            if not config_data.empty:
                ax.plot(config_data['threads'], config_data['efficiency_percent'], 
                        marker='s', label=f'{sched_type.title()}', linewidth=2)
    
    ax.set_title('OpenMP Efficiency Comparison')
    ax.set_xlabel('Thread Count') 
    ax.set_ylabel('Efficiency (%)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/openmp_efficiency_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 3: Strong Scaling Analysis
    fig, ax = plt.subplots(figsize=(10, 6))
    thread_counts = [1, 2, 4, 8, 16, 32, 64]
    best_times = []
    
    for threads in thread_counts:
        thread_data = sched_data[sched_data['threads'] == threads]
        if not thread_data.empty:
            best_time = thread_data['execution_time_ms'].min()
            best_times.append(best_time)
        else:
            best_times.append(None)
    
    valid_data = [(t, time) for t, time in zip(thread_counts, best_times) if time is not None]
    if valid_data:
        threads, times = zip(*valid_data)
        ax.plot(threads, times, marker='o', color='green', linewidth=2)
        ax.set_title('Strong Scaling Analysis (Best Performance)')
        ax.set_xlabel('Thread Count')
        ax.set_ylabel('Execution Time (ms)')
        ax.set_yscale('log')
        ax.set_xscale('log', base=2)
        ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('charts/openmp_strong_scaling.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 4: Problem Size Impact
    fig, ax = plt.subplots(figsize=(10, 6))
    resolutions = [1000, 2000, 3000]
    for resolution in resolutions:
        res_data = sched_data[(sched_data['resolution'] == resolution) & 
                             (sched_data['iterations'] == 1000) &
                             (sched_data['scheduling_type'] == 'guided')]
        if not res_data.empty:
            ax.plot(res_data['threads'], res_data['speedup'], 
                    marker='o', label=f'{resolution}×{resolution}', linewidth=2)
    
    ax.set_title('Problem Size Impact on Speedup (Guided Scheduling)')
    ax.set_xlabel('Thread Count')
    ax.set_ylabel('Speedup')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/openmp_problem_size_impact.png', dpi=300, bbox_inches='tight')
    plt.close()

def create_mpi_analysis_charts(data):
    """Generate charts for MPI analysis section"""
    
    mpi_data = data['mpi']
    
    # Chart 1: MPI Speedup by Configuration
    fig, ax = plt.subplots(figsize=(10, 6))
    configs = mpi_data['configuration'].unique()
    for config in configs[:3]:  # Show first 3 configs to avoid clutter
        config_data = mpi_data[mpi_data['configuration'] == config]
        ax.plot(config_data['processes'], config_data['speedup'], 
                marker='o', label=config, linewidth=2)
    
    ax.set_title('MPI Speedup by Configuration')
    ax.set_xlabel('Process Count')
    ax.set_ylabel('Speedup')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/mpi_speedup_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 2: MPI Efficiency
    fig, ax = plt.subplots(figsize=(10, 6))
    for config in configs[:3]:
        config_data = mpi_data[mpi_data['configuration'] == config]
        ax.plot(config_data['processes'], config_data['efficiency_percent'], 
                marker='s', label=config, linewidth=2)
    
    ax.set_title('MPI Efficiency by Configuration')
    ax.set_xlabel('Process Count')
    ax.set_ylabel('Efficiency (%)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/mpi_efficiency_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 3: MPI vs Ideal Scaling
    fig, ax = plt.subplots(figsize=(10, 6))
    baseline_config = mpi_data[mpi_data['configuration'] == '1000x1000_1000']
    if not baseline_config.empty:
        processes = baseline_config['processes'].values
        speedups = baseline_config['speedup'].values
        ideal_speedup = processes  # Ideal linear scaling
        
        ax.plot(processes, speedups, marker='o', label='Actual MPI', linewidth=2)
        ax.plot(processes, ideal_speedup, '--', label='Ideal Linear', alpha=0.7)
        ax.set_title('MPI vs Ideal Scaling (1000×1000, 1000 iterations)')
        ax.set_xlabel('Process Count')
        ax.set_ylabel('Speedup')
        ax.legend()
        ax.grid(True, alpha=0.3)
        ax.set_xscale('log', base=2)
        ax.set_yscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/mpi_vs_ideal_scaling.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 4: MPI Execution Time by Problem Size
    fig, ax = plt.subplots(figsize=(10, 6))
    configs_to_plot = ['1000x1000_1000', '2000x2000_1000', '3000x3000_1000']
    
    for config in configs_to_plot:
        config_data = mpi_data[mpi_data['configuration'] == config]
        if not config_data.empty:
            ax.plot(config_data['processes'], config_data['execution_time_ms'], 
                    marker='o', label=config, linewidth=2)
    
    ax.set_title('MPI Execution Time by Problem Size')
    ax.set_xlabel('Process Count')
    ax.set_ylabel('Execution Time (ms)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    ax.set_yscale('log')
    
    plt.tight_layout()
    plt.savefig('charts/mpi_execution_time_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()

def create_hybrid_analysis_charts(data):
    """Generate charts for Hybrid MPI+OpenMP analysis section"""
    
    hybrid_data = data['hybrid']
    
    # Chart 1: Hybrid Speedup
    fig, ax = plt.subplots(figsize=(10, 6))
    configs = hybrid_data['configuration'].unique()
    for config in configs[:3]:  # Show first 3 configs
        config_data = hybrid_data[hybrid_data['configuration'] == config]
        ax.plot(config_data['total_threads'], config_data['speedup'], 
                marker='o', label=config, linewidth=2)
    
    ax.set_title('Hybrid MPI+OpenMP Speedup')
    ax.set_xlabel('Total Threads (Processes × Threads/Process)')
    ax.set_ylabel('Speedup')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/hybrid_speedup.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 2: Hybrid Efficiency
    fig, ax = plt.subplots(figsize=(10, 6))
    for config in configs[:3]:
        config_data = hybrid_data[hybrid_data['configuration'] == config]
        ax.plot(config_data['total_threads'], config_data['efficiency_percent'], 
                marker='s', label=config, linewidth=2)
    
    ax.set_title('Hybrid MPI+OpenMP Efficiency')
    ax.set_xlabel('Total Threads')
    ax.set_ylabel('Efficiency (%)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/hybrid_efficiency.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 3: Process vs Thread Configuration Heatmap
    fig, ax = plt.subplots(figsize=(10, 8))
    baseline_config = hybrid_data[hybrid_data['configuration'] == '1000x1000_1000']
    if not baseline_config.empty:
        # Create pivot table for heatmap
        pivot_data = baseline_config.pivot_table(
            values='speedup', 
            index='processes', 
            columns='threads_per_process', 
            fill_value=0
        )
        
        sns.heatmap(pivot_data, annot=True, fmt='.1f', cmap='YlOrRd', ax=ax)
        ax.set_title('Hybrid Configuration Heatmap (Speedup)\n1000×1000, 1000 iterations')
        ax.set_xlabel('Threads per Process')
        ax.set_ylabel('MPI Processes')
    
    plt.tight_layout()
    plt.savefig('charts/hybrid_configuration_heatmap.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 4: Hybrid Execution Time Trends
    fig, ax = plt.subplots(figsize=(10, 6))
    for config in configs[:3]:
        config_data = hybrid_data[hybrid_data['configuration'] == config]
        ax.plot(config_data['total_threads'], config_data['execution_time_ms'], 
                marker='o', label=config, linewidth=2)
    
    ax.set_title('Hybrid Execution Time Trends')
    ax.set_xlabel('Total Threads')
    ax.set_ylabel('Execution Time (ms)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    ax.set_yscale('log')
    
    plt.tight_layout()
    plt.savefig('charts/hybrid_execution_time.png', dpi=300, bbox_inches='tight')
    plt.close()

def create_cuda_analysis_charts(data):
    """Generate charts for CUDA analysis section"""
    
    cuda_data = data['cuda']
    
    # Chart 1: CUDA Performance by Block Size
    fig, ax = plt.subplots(figsize=(10, 6))
    baseline_data = cuda_data[(cuda_data['res'] == '1000×1000') & 
                             (cuda_data[' iters'] == 1000)]
    if not baseline_data.empty:
        ax.bar(baseline_data[' block'].astype(str), baseline_data[' time (ms)'], 
               color='orange', alpha=0.7)
        ax.set_title('CUDA Performance by Block Size\n(1000×1000, 1000 iterations)')
        ax.set_xlabel('Block Size')
        ax.set_ylabel('Execution Time (ms)')
        ax.tick_params(axis='x', rotation=45)
        ax.grid(True, alpha=0.3, axis='y')
    
    plt.tight_layout()
    plt.savefig('charts/cuda_block_size_performance.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 2: CUDA Resolution Scaling
    fig, ax = plt.subplots(figsize=(10, 6))
    resolutions = ['1000×1000', '2000×2000', '3000×3000']
    best_times = []
    pixel_counts = []
    
    for res in resolutions:
        res_data = cuda_data[(cuda_data['res'] == res) & (cuda_data[' iters'] == 1000)]
        if not res_data.empty:
            best_time = res_data[' time (ms)'].min()
            best_times.append(best_time)
            # Extract resolution numbers
            width = int(res.split('×')[0])
            pixel_counts.append(width * width)
    
    if best_times:
        ax.plot(pixel_counts, best_times, marker='o', color='red', linewidth=2)
        ax.set_title('CUDA Resolution Scaling')
        ax.set_xlabel('Total Pixels')
        ax.set_ylabel('Best Execution Time (ms)')
        ax.grid(True, alpha=0.3)
        ax.set_xscale('log')
        ax.set_yscale('log')
        
        # Add labels for each point
        for i, (pixels, time) in enumerate(zip(pixel_counts, best_times)):
            ax.annotate(f'{resolutions[i]}', (pixels, time), 
                       textcoords="offset points", xytext=(0,10), ha='center')
    
    plt.tight_layout()
    plt.savefig('charts/cuda_resolution_scaling.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 3: CUDA Iteration Scaling
    fig, ax = plt.subplots(figsize=(10, 6))
    iter_data = cuda_data[cuda_data['res'] == '1000×1000']
    if not iter_data.empty:
        # Group by iterations and get best time for each
        iter_groups = iter_data.groupby(' iters')[' time (ms)'].min().reset_index()
        ax.plot(iter_groups[' iters'], iter_groups[' time (ms)'], 
                marker='o', color='green', linewidth=2)
        ax.set_title('CUDA Iteration Scaling\n(1000×1000 resolution)')
        ax.set_xlabel('Iterations')
        ax.set_ylabel('Best Execution Time (ms)')
        ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('charts/cuda_iteration_scaling.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 4: CUDA Block Size Optimization
    fig, ax = plt.subplots(figsize=(10, 6))
    block_data = cuda_data[(cuda_data['res'] == '1000×1000') & 
                          (cuda_data[' iters'] == 1000)]
    if not block_data.empty:
        block_sizes = block_data[' block'].values
        times = block_data[' time (ms)'].values
        
        colors = plt.cm.viridis(np.linspace(0, 1, len(block_sizes)))
        bars = ax.bar(range(len(block_sizes)), times, color=colors, alpha=0.7)
        ax.set_title('CUDA Block Size Optimization Detail')
        ax.set_xlabel('Block Configuration Index')
        ax.set_ylabel('Execution Time (ms)')
        ax.set_xticks(range(len(block_sizes)))
        ax.set_xticklabels(block_sizes, rotation=45)
        ax.grid(True, alpha=0.3, axis='y')
        
        # Add value labels on bars
        for bar, time in zip(bars, times):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height + height*0.01,
                    f'{time:.1f}', ha='center', va='bottom')
    
    plt.tight_layout()
    plt.savefig('charts/cuda_block_optimization.png', dpi=300, bbox_inches='tight')
    plt.close()

def create_comprehensive_comparison_charts(data):
    """Generate charts for comprehensive comparison across all implementations"""
    
    # Get best performance from each approach for 1000x1000, 1000 iterations
    implementations = []
    speedups = []
    exec_times = []
    
    # Sequential baseline
    seq_data = data['sequential']
    seq_baseline = seq_data[(seq_data['benchmark_type'] == 'scaling_analysis') & 
                           (seq_data['flag_or_config'] == '1000x1000') &
                           (seq_data['iterations'] == 1000)]
    if not seq_baseline.empty:
        seq_time = seq_baseline['execution_time_ms'].iloc[0]
        implementations.append('Sequential')
        speedups.append(1.0)
        exec_times.append(seq_time)
        
        # OpenMP best (guided scheduling)
        openmp_data = data['comprehensive_scheduling']
        openmp_best = openmp_data[(openmp_data['resolution'] == 1000) & 
                                 (openmp_data['iterations'] == 1000) &
                                 (openmp_data['scheduling_type'] == 'guided')]
        if not openmp_best.empty:
            best_openmp = openmp_best.loc[openmp_best['speedup'].idxmax()]
            implementations.append('OpenMP (Guided)')
            speedups.append(best_openmp['speedup'])
            exec_times.append(best_openmp['execution_time_ms'])
        
        # MPI best
        mpi_data = data['mpi']
        mpi_best = mpi_data[mpi_data['configuration'] == '1000x1000_1000']
        if not mpi_best.empty:
            best_mpi = mpi_best.loc[mpi_best['speedup'].idxmax()]
            implementations.append('MPI')
            speedups.append(best_mpi['speedup'])
            exec_times.append(best_mpi['execution_time_ms'])
        
        # Hybrid best
        hybrid_data = data['hybrid']
        hybrid_best = hybrid_data[hybrid_data['configuration'] == '1000x1000_1000']
        if not hybrid_best.empty:
            best_hybrid = hybrid_best.loc[hybrid_best['speedup'].idxmax()]
            implementations.append('Hybrid (MPI+OpenMP)')
            speedups.append(best_hybrid['speedup'])
            exec_times.append(best_hybrid['execution_time_ms'])
        
        # CUDA best
        cuda_data = data['cuda']
        cuda_best = cuda_data[(cuda_data['res'] == '1000×1000') & 
                             (cuda_data[' iters'] == 1000)]
        if not cuda_best.empty:
            best_cuda_time = cuda_best[' time (ms)'].min()
            cuda_speedup = seq_time / best_cuda_time
            implementations.append('CUDA')
            speedups.append(cuda_speedup)
            exec_times.append(best_cuda_time)
    
    # Chart 1: Maximum Speedup Comparison
    fig, ax = plt.subplots(figsize=(12, 6))
    if implementations:
        colors = ['gray', 'blue', 'red', 'green', 'orange']
        bars1 = ax.bar(implementations, speedups, color=colors[:len(implementations)], alpha=0.7)
        ax.set_title('Maximum Speedup Comparison\n(1000×1000, 1000 iterations)')
        ax.set_ylabel('Speedup vs Sequential')
        ax.tick_params(axis='x', rotation=45)
        ax.grid(True, alpha=0.3, axis='y')
        
        # Add value labels on bars
        for bar, speedup in zip(bars1, speedups):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height + height*0.01,
                    f'{speedup:.1f}×', ha='center', va='bottom')
    
    plt.tight_layout()
    plt.savefig('charts/speedup_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 2: Execution Time Comparison
    fig, ax = plt.subplots(figsize=(12, 6))
    if implementations:
        bars2 = ax.bar(implementations, exec_times, color=colors[:len(implementations)], alpha=0.7)
        ax.set_title('Execution Time Comparison')
        ax.set_ylabel('Execution Time (ms)')
        ax.set_yscale('log')
        ax.tick_params(axis='x', rotation=45)
        ax.grid(True, alpha=0.3, axis='y')
        
        # Add value labels
        for bar, time in zip(bars2, exec_times):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height * 1.1,
                    f'{time:.0f}ms', ha='center', va='bottom', rotation=45)
    
    plt.tight_layout()
    plt.savefig('charts/execution_time_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 3: Scaling Comparison
    fig, ax = plt.subplots(figsize=(12, 8))
    thread_counts = [1, 2, 4, 8, 16, 32, 64]
    
    # OpenMP guided scaling
    openmp_scaling = data['comprehensive_scheduling']
    openmp_guided = openmp_scaling[(openmp_scaling['resolution'] == 1000) & 
                                  (openmp_scaling['iterations'] == 1000) &
                                  (openmp_scaling['scheduling_type'] == 'guided')]
    if not openmp_guided.empty:
        ax.plot(openmp_guided['threads'], openmp_guided['speedup'], 
                marker='o', label='OpenMP (Guided)', linewidth=2, color='blue')
    
    # MPI scaling
    mpi_scaling = data['mpi']
    mpi_1000 = mpi_scaling[mpi_scaling['configuration'] == '1000x1000_1000']
    if not mpi_1000.empty:
        ax.plot(mpi_1000['processes'], mpi_1000['speedup'], 
                marker='s', label='MPI', linewidth=2, color='red')
    
    # Hybrid scaling
    hybrid_scaling = data['hybrid']
    hybrid_1000 = hybrid_scaling[hybrid_scaling['configuration'] == '1000x1000_1000']
    if not hybrid_1000.empty:
        ax.plot(hybrid_1000['total_threads'], hybrid_1000['speedup'], 
                marker='^', label='Hybrid (MPI+OpenMP)', linewidth=2, color='green')
    
    # Ideal scaling line
    ax.plot(thread_counts, thread_counts, '--', label='Ideal Linear', 
            alpha=0.7, color='black')
    
    ax.set_title('Scaling Comparison')
    ax.set_xlabel('Thread/Process Count')
    ax.set_ylabel('Speedup')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    ax.set_yscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/scaling_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Chart 4: Efficiency Comparison
    fig, ax = plt.subplots(figsize=(12, 8))
    if not openmp_guided.empty:
        ax.plot(openmp_guided['threads'], openmp_guided['efficiency_percent'], 
                marker='o', label='OpenMP (Guided)', linewidth=2, color='blue')
    
    if not mpi_1000.empty:
        ax.plot(mpi_1000['processes'], mpi_1000['efficiency_percent'], 
                marker='s', label='MPI', linewidth=2, color='red')
    
    if not hybrid_1000.empty:
        ax.plot(hybrid_1000['total_threads'], hybrid_1000['efficiency_percent'], 
                marker='^', label='Hybrid (MPI+OpenMP)', linewidth=2, color='green')
    
    ax.set_title('Parallel Efficiency Comparison')
    ax.set_xlabel('Thread/Process Count')
    ax.set_ylabel('Efficiency (%)')
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.set_xscale('log', base=2)
    
    plt.tight_layout()
    plt.savefig('charts/efficiency_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()

def main():
    """Main function to generate all charts"""
    
    # Create charts directory
    os.makedirs('charts', exist_ok=True)
    
    print("Loading data from CSV files...")
    data = load_data()
    
    print("Generating Sequential Analysis charts...")
    create_sequential_analysis_charts(data)
    
    print("Generating OpenMP Analysis charts...")
    create_openmp_analysis_charts(data)
    
    print("Generating MPI Analysis charts...")
    create_mpi_analysis_charts(data)
    
    print("Generating Hybrid Analysis charts...")
    create_hybrid_analysis_charts(data)
    
    print("Generating CUDA Analysis charts...")
    create_cuda_analysis_charts(data)
    
    print("Generating Comprehensive Comparison charts...")
    create_comprehensive_comparison_charts(data)
    
    print("\nChart generation complete!")
    print("Generated charts:")
    print("  Sequential Analysis:")
    print("    - charts/sequential_compiler_optimization.png")
    print("    - charts/sequential_scaling_analysis.png")
    print("  OpenMP Analysis:")
    print("    - charts/openmp_speedup_comparison.png")
    print("    - charts/openmp_efficiency_comparison.png") 
    print("    - charts/openmp_strong_scaling.png")
    print("    - charts/openmp_problem_size_impact.png")
    print("  MPI Analysis:")
    print("    - charts/mpi_speedup_comparison.png")
    print("    - charts/mpi_efficiency_comparison.png")
    print("    - charts/mpi_vs_ideal_scaling.png")
    print("    - charts/mpi_execution_time_comparison.png")
    print("  Hybrid Analysis:")
    print("    - charts/hybrid_speedup.png")
    print("    - charts/hybrid_efficiency.png")
    print("    - charts/hybrid_configuration_heatmap.png")
    print("    - charts/hybrid_execution_time.png")
    print("  CUDA Analysis:")
    print("    - charts/cuda_block_size_performance.png")
    print("    - charts/cuda_resolution_scaling.png")
    print("    - charts/cuda_iteration_scaling.png")
    print("    - charts/cuda_block_optimization.png")
    print("  Comprehensive Comparison:")
    print("    - charts/speedup_comparison.png")
    print("    - charts/execution_time_comparison.png")
    print("    - charts/scaling_comparison.png")
    print("    - charts/efficiency_comparison.png")

if __name__ == "__main__":
    main()
