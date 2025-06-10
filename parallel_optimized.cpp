#include <iostream>
#include <fstream>
#include <complex>
#include <chrono>
#include <omp.h>

// Ranges of the set
#define MIN_X -2
#define MAX_X 1
#define MIN_Y -1
#define MAX_Y 1

// Image ratio
#define RATIO_X (MAX_X - MIN_X)
#define RATIO_Y (MAX_Y - MIN_Y)

// Image size
#define RESOLUTION 3000  
#define WIDTH (RATIO_X * RESOLUTION)
#define HEIGHT (RATIO_Y * RESOLUTION)

#define STEP ((double)RATIO_X / WIDTH)

#define DEGREE 3        // Degree of the polynomial
#define ITERATIONS 3000 

using namespace std;

int main(int argc, char **argv)
{
    int *const image = new int[HEIGHT * WIDTH];
    
    // Get number of threads for reporting
    const int num_threads = omp_get_max_threads();
    cout << "Using " << num_threads << " OpenMP threads" << endl;

    const auto start = chrono::steady_clock::now();
    
    // Initialize image array in parallel
    #pragma omp parallel for simd
    for (int pos = 0; pos < HEIGHT * WIDTH; pos++)
    {
        image[pos] = 0;
    }
    
    // Main computation loop - optimized for both parallelization and vectorization
    #pragma omp parallel for schedule(dynamic, 128) 
    for (int row = 0; row < HEIGHT; row++)
    {
        #pragma omp simd
        for (int col = 0; col < WIDTH; col++)
        {
            const int pos = row * WIDTH + col;
            const double real_c = col * STEP + MIN_X;
            const double imag_c = row * STEP + MIN_Y;

            // Manual complex arithmetic for better vectorization
            double real_z = 0.0;
            double imag_z = 0.0;
            
            int iter = 0;
            for (int i = 1; i <= ITERATIONS; i++)
            {
                // z = z^2 + c
                const double real_z_new = real_z * real_z - imag_z * imag_z + real_c;
                const double imag_z_new = 2.0 * real_z * imag_z + imag_c;
                
                real_z = real_z_new;
                imag_z = imag_z_new;

                // If it is convergent (|z|^2 >= 4)
                if (real_z * real_z + imag_z * imag_z >= 4.0)
                {
                    iter = i;
                    break;
                }
            }
            image[pos] = iter;
        }
    }
    
    const auto end = chrono::steady_clock::now();
    cout << "Time elapsed: "
         << chrono::duration_cast<chrono::seconds>(end - start).count()
         << " seconds." << endl;

    // Write the result to a file
    ofstream matrix_out;

    if (argc < 2)
    {
        cout << "Please specify the output file as a parameter." << endl;
        return -1;
    }

    matrix_out.open(argv[1], ios::trunc);
    if (!matrix_out.is_open())
    {
        cout << "Unable to open file." << endl;
        return -2;
    }

    for (int row = 0; row < HEIGHT; row++)
    {
        for (int col = 0; col < WIDTH; col++)
        {
            matrix_out << image[row * WIDTH + col];

            if (col < WIDTH - 1)
                matrix_out << ',';
        }
        if (row < HEIGHT - 1)
            matrix_out << endl;
    }
    matrix_out.close();

    delete[] image;
    return 0;
}
