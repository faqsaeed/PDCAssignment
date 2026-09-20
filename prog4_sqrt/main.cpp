#include <stdio.h>
#include <algorithm>
#include <pthread.h>
#include <math.h>
#include <string>

#include "CycleTimer.h"
#include "sqrt_ispc.h"

using namespace ispc;

extern void sqrtSerial(int N, float startGuess, float* values, float* output);

static void verifyResult(int N, float* result, float* gold) {
    for (int i=0; i<N; i++) {
        if (fabs(result[i] - gold[i]) > 1e-4) {
            printf("Error: [%d] Got %f expected %f\n", i, result[i], gold[i]);
            return;
        }
    }
}

int main(int argc, char** argv) {
    const unsigned int N = 20 * 1000 * 1000;
    const float initialGuess = 1.0f;
    std::string inputCase = "normal";
    if (argc == 3 && std::string(argv[1]) == "--case")
        inputCase = argv[2];

    float* values = new float[N];
    float* output = new float[N];
    float* gold = new float[N];

    static const float divergent[8] = {
        0.001f, 0.01f, 0.05f, 0.20f, 0.70f, 1.0f, 2.0f, 2.999f
    };

    for (unsigned int i=0; i<N; i++) {
        if (inputCase == "uniform")
            values[i] = 2.0f;
        else if (inputCase == "divergent")
            values[i] = divergent[i % 8];
        else
            values[i] = .001f + 2.998f * static_cast<float>(rand()) / RAND_MAX;
    }
    printf("[input case]: %s\n", inputCase.c_str());

    for (unsigned int i=0; i<N; i++)
        gold[i] = sqrt(values[i]);

    double minSerial = 1e30;
    for (int i = 0; i < 3; ++i) {
        double startTime = CycleTimer::currentSeconds();
        sqrtSerial(N, initialGuess, values, output);
        double endTime = CycleTimer::currentSeconds();
        minSerial = std::min(minSerial, endTime - startTime);
    }
    printf("[sqrt serial]:\t\t[%.3f] ms\n", minSerial * 1000);
    verifyResult(N, output, gold);

    double minISPC = 1e30;
    for (int i = 0; i < 3; ++i) {
        double startTime = CycleTimer::currentSeconds();
        sqrt_ispc(N, initialGuess, values, output);
        double endTime = CycleTimer::currentSeconds();
        minISPC = std::min(minISPC, endTime - startTime);
    }
    printf("[sqrt ispc]:\t\t[%.3f] ms\n", minISPC * 1000);
    verifyResult(N, output, gold);

    for (unsigned int i = 0; i < N; ++i)
        output[i] = 0;

    double minTaskISPC = 1e30;
    for (int i = 0; i < 3; ++i) {
        double startTime = CycleTimer::currentSeconds();
        sqrt_ispc_withtasks(N, initialGuess, values, output);
        double endTime = CycleTimer::currentSeconds();
        minTaskISPC = std::min(minTaskISPC, endTime - startTime);
    }
    printf("[sqrt task ispc]:\t[%.3f] ms\n", minTaskISPC * 1000);
    verifyResult(N, output, gold);

    printf("\t\t\t\t(%.2fx speedup from ISPC)\n", minSerial/minISPC);
    printf("\t\t\t\t(%.2fx speedup from task ISPC)\n", minSerial/minTaskISPC);

    delete [] values;
    delete [] output;
    delete [] gold;
    return 0;
}
