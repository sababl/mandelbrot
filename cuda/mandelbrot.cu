#include <iostream>
#include <fstream>
#include <complex>
#include <cuda_runtime.h>

// CUDA kernel to compute Mandelbrot iterations per pixel
__global__ void mandelbrotKernel(int *image, int width, int height,
                                 double minX, double minY,
                                 double stepX, double stepY,
                                 int maxIterations) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;
    if (x >= width || y >= height) return;

    int idx = y * width + x;
    double cx = minX + x * stepX;
    double cy = minY + y * stepY;
    double zx = 0.0;
    double zy = 0.0;
    int iter = 0;
    while (zx * zx + zy * zy < 4.0 && iter < maxIterations) {
        double xt = zx * zx - zy * zy + cx;
        zy = 2.0 * zx * zy + cy;
        zx = xt;
        ++iter;
    }
    image[idx] = iter;
}

int main(int argc, char **argv) {
    if (argc < 4) {
        std::cout << "Usage: " << argv[0] << " <output_file> <resolution> <iterations>" << std::endl;
        return -1;
    }
    
    const char *outputFile = argv[1];
    int resolution = atoi(argv[2]);
    int maxIterations = atoi(argv[3]);

    double minX = -2.0;
    double maxX = 1.0;
    double minY = -1.0;
    double maxY = 1.0;
    int width = resolution * (maxX - minX);
    int height = resolution * (maxY - minY);
    double stepX = (maxX - minX) / width;
    double stepY = (maxY - minY) / height;

    size_t imageSize = width * height * sizeof(int);
    int *h_image = (int*)malloc(imageSize);
    int *d_image;
    cudaMalloc(&d_image, imageSize);

    // Launch kernel
    dim3 block(16, 16);
    dim3 grid((width + block.x - 1) / block.x,
              (height + block.y - 1) / block.y);
    mandelbrotKernel<<<grid, block>>>(d_image, width, height,
                                      minX, minY, stepX, stepY,
                                      maxIterations);
    cudaDeviceSynchronize();

    cudaMemcpy(h_image, d_image, imageSize, cudaMemcpyDeviceToHost);

    // Write output
    std::ofstream out(outputFile, std::ios::trunc);
    if (!out.is_open()) {
        std::cerr << "Unable to open file: " << outputFile << std::endl;
        return -1;
    }
    for (int row = 0; row < height; ++row) {
        for (int col = 0; col < width; ++col) {
            out << h_image[row * width + col];
            if (col < width - 1) out << ',';
        }
        if (row < height - 1) out << '\n';
    }
    out.close();

    cudaFree(d_image);
    free(h_image);
    return 0;
}
