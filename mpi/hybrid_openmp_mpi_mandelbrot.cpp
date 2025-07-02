#include <iostream>
#include <fstream>
#include <complex>
#include <chrono>
#include <mpi.h>
#include <omp.h>
#include <vector>

using namespace std;

// Mandelbrot computation function
int mandelbrot_iterations(const complex<double>& c, int max_iterations) {
    complex<double> z(0, 0);
    for (int i = 1; i <= max_iterations; i++) {
        z = z * z + c;
        if (abs(z) >= 2) {
            return i;
        }
    }
    return 0;
}

int main(int argc, char **argv) {
    // Initialize MPI
    int provided;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);
    
    if (provided < MPI_THREAD_FUNNELED) {
        int temp_rank;
        MPI_Comm_rank(MPI_COMM_WORLD, &temp_rank);
        if (temp_rank == 0) {
            cerr << "MPI does not support threading" << endl;
        }
        MPI_Finalize();
        return -1;
    }
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Default parameters (can be overridden by command line)
    int resolution = 1000;
    int iterations = 1000;
    int num_threads = omp_get_max_threads();
    string output_file = "hybrid_output.csv";
    
    // Parse command line arguments
    if (argc >= 2) output_file = argv[1];
    if (argc >= 3) resolution = atoi(argv[2]);
    if (argc >= 4) iterations = atoi(argv[3]);
    if (argc >= 5) num_threads = atoi(argv[4]);
    
    // Set OpenMP thread count
    omp_set_num_threads(num_threads);
    
    // Mandelbrot set parameters
    const double MIN_X = -2.0;
    const double MAX_X = 1.0;
    const double MIN_Y = -1.0;
    const double MAX_Y = 1.0;
    
    const double RATIO_X = (MAX_X - MIN_X);
    const double RATIO_Y = (MAX_Y - MIN_Y);
    const int WIDTH = (int)(RATIO_X * resolution);
    const int HEIGHT = (int)(RATIO_Y * resolution);
    const double STEP = RATIO_X / WIDTH;
    const int total_pixels = HEIGHT * WIDTH;
    
    // Calculate MPI work distribution
    const int pixels_per_process = total_pixels / size;
    const int remainder = total_pixels % size;
    
    // Each process gets pixels_per_process pixels, 
    // and the first 'remainder' processes get one extra pixel
    const int start_pixel = rank * pixels_per_process + min(rank, remainder);
    const int end_pixel = start_pixel + pixels_per_process + (rank < remainder ? 1 : 0);
    const int local_pixels = end_pixel - start_pixel;
    
    if (rank == 0) {
        cout << "Hybrid OpenMP+MPI Mandelbrot Set Computation" << endl;
        cout << "Resolution: " << resolution << "x" << resolution << endl;
        cout << "Actual dimensions: " << WIDTH << "x" << HEIGHT << endl;
        cout << "Iterations: " << iterations << endl;
        cout << "MPI Processes: " << size << endl;
        cout << "OpenMP Threads per process: " << num_threads << endl;
        cout << "Total pixels: " << total_pixels << endl;
        cout << "Pixels per process: " << local_pixels << endl;
    }
    
    // Allocate local array for this process's pixels
    vector<int> local_image(local_pixels);
    
    // Start timing
    double start_time = MPI_Wtime();
    
    // Compute Mandelbrot set for this process's pixels using OpenMP
    #pragma omp parallel for schedule(guided)
    for (int i = 0; i < local_pixels; i++) {
        int pos = start_pixel + i;
        int row = pos / WIDTH;
        int col = pos % WIDTH;
        
        complex<double> c(col * STEP + MIN_X, row * STEP + MIN_Y);
        local_image[i] = mandelbrot_iterations(c, iterations);
    }
    
    // End timing
    double end_time = MPI_Wtime();
    double local_time = end_time - start_time;
    
    // Gather all results to process 0
    vector<int> full_image;
    if (rank == 0) {
        full_image.resize(total_pixels);
    }
    
    // Prepare gather parameters
    vector<int> recvcounts(size);
    vector<int> displs(size);
    
    if (rank == 0) {
        for (int i = 0; i < size; i++) {
            int proc_pixels = pixels_per_process + (i < remainder ? 1 : 0);
            recvcounts[i] = proc_pixels;
            displs[i] = i * pixels_per_process + min(i, remainder);
        }
    }
    
    // Gather all computed pixels
    MPI_Gatherv(local_image.data(), local_pixels, MPI_INT,
                full_image.data(), recvcounts.data(), displs.data(), MPI_INT,
                0, MPI_COMM_WORLD);
    
    // Find maximum time across all processes
    double max_time;
    MPI_Reduce(&local_time, &max_time, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    
    // Process 0 writes the output file and reports timing
    if (rank == 0) {
        cout << "Execution time: " << (max_time * 1000) << " ms" << endl;
        cout << "Total threads used: " << (size * num_threads) << endl;
        cout << "Writing output to: " << output_file << endl;
        
        // Write results to file
        ofstream matrix_out(output_file, ios::trunc);
        if (!matrix_out.is_open()) {
            cout << "Unable to open output file." << endl;
            MPI_Finalize();
            return -1;
        }
        
        for (int row = 0; row < HEIGHT; row++) {
            for (int col = 0; col < WIDTH; col++) {
                matrix_out << full_image[row * WIDTH + col];
                if (col < WIDTH - 1) matrix_out << ',';
            }
            if (row < HEIGHT - 1) matrix_out << endl;
        }
        matrix_out.close();
        cout << "Output written successfully." << endl;
    }
    
    MPI_Finalize();
    return 0;
}
