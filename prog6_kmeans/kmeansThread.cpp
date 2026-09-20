#include <algorithm>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <thread>
#include <vector>

#include "CycleTimer.h"

using namespace std;

typedef struct {
  int start, end;
  double *data;
  double *clusterCentroids;
  int *clusterAssignments;
  double *currCost;
  int M, N, K;
} WorkerArgs;

static bool stoppingConditionMet(double *prevCost, double *currCost,
                                 double epsilon, int K) {
  for (int k = 0; k < K; k++) {
    if (abs(prevCost[k] - currCost[k]) > epsilon)
      return false;
  }
  return true;
}

double dist(double *x, double *y, int nDim) {
  double accum = 0.0;
  for (int i = 0; i < nDim; i++)
    accum += pow((x[i] - y[i]), 2);
  return sqrt(accum);
}

static int configuredThreads() {
  const char *env = getenv("KMEANS_THREADS");
  if (env) {
    int value = atoi(env);
    if (value > 0) return value;
  }
  return 1;
}

static void computeAssignmentsRange(WorkerArgs *const args) {
  for (int m = args->start; m < args->end; m++) {
    double minDist = 1e30;
    int best = -1;
    for (int k = 0; k < args->K; k++) {
      double d = dist(&args->data[m * args->N],
                      &args->clusterCentroids[k * args->N], args->N);
      if (d < minDist) {
        minDist = d;
        best = k;
      }
    }
    args->clusterAssignments[m] = best;
  }
}

void computeAssignments(WorkerArgs *const args) {
  int numThreads = configuredThreads();

  if (numThreads <= 1) {
    double *minDist = new double[args->M];
    for (int m = 0; m < args->M; m++) {
      minDist[m] = 1e30;
      args->clusterAssignments[m] = -1;
    }
    for (int k = 0; k < args->K; k++) {
      for (int m = 0; m < args->M; m++) {
        double d = dist(&args->data[m * args->N],
                        &args->clusterCentroids[k * args->N], args->N);
        if (d < minDist[m]) {
          minDist[m] = d;
          args->clusterAssignments[m] = k;
        }
      }
    }
    delete[] minDist;
    return;
  }

  numThreads = min(numThreads, args->M);
  vector<thread> workers;
  vector<WorkerArgs> threadArgs(numThreads);
  workers.reserve(numThreads - 1);

  for (int t = 0; t < numThreads; t++) {
    threadArgs[t] = *args;
    threadArgs[t].start = (t * args->M) / numThreads;
    threadArgs[t].end = ((t + 1) * args->M) / numThreads;
  }
  for (int t = 1; t < numThreads; t++)
    workers.emplace_back(computeAssignmentsRange, &threadArgs[t]);
  computeAssignmentsRange(&threadArgs[0]);
  for (auto &worker : workers)
    worker.join();
}

void computeCentroids(WorkerArgs *const args) {
  int *counts = new int[args->K];
  for (int k = 0; k < args->K; k++) {
    counts[k] = 0;
    for (int n = 0; n < args->N; n++)
      args->clusterCentroids[k * args->N + n] = 0.0;
  }

  for (int m = 0; m < args->M; m++) {
    int k = args->clusterAssignments[m];
    for (int n = 0; n < args->N; n++)
      args->clusterCentroids[k * args->N + n] += args->data[m * args->N + n];
    counts[k]++;
  }

  for (int k = 0; k < args->K; k++) {
    counts[k] = max(counts[k], 1);
    for (int n = 0; n < args->N; n++)
      args->clusterCentroids[k * args->N + n] /= counts[k];
  }
  delete[] counts;
}

void computeCost(WorkerArgs *const args) {
  double *accum = new double[args->K];
  for (int k = 0; k < args->K; k++)
    accum[k] = 0.0;

  for (int m = 0; m < args->M; m++) {
    int k = args->clusterAssignments[m];
    accum[k] += dist(&args->data[m * args->N],
                     &args->clusterCentroids[k * args->N], args->N);
  }

  for (int k = args->start; k < args->end; k++)
    args->currCost[k] = accum[k];
  delete[] accum;
}

void kMeansThread(double *data, double *clusterCentroids, int *clusterAssignments,
                  int M, int N, int K, double epsilon) {
  double *prevCost = new double[K];
  double *currCost = new double[K];

  WorkerArgs args;
  args.data = data;
  args.clusterCentroids = clusterCentroids;
  args.clusterAssignments = clusterAssignments;
  args.currCost = currCost;
  args.M = M;
  args.N = N;
  args.K = K;

  for (int k = 0; k < K; k++) {
    prevCost[k] = 1e30;
    currCost[k] = 0.0;
  }

  double assignmentSeconds = 0.0;
  double centroidSeconds = 0.0;
  double costSeconds = 0.0;
  int iter = 0;

  while (!stoppingConditionMet(prevCost, currCost, epsilon, K)) {
    for (int k = 0; k < K; k++)
      prevCost[k] = currCost[k];

    args.start = 0;
    args.end = K;

    double t0 = CycleTimer::currentSeconds();
    computeAssignments(&args);
    double t1 = CycleTimer::currentSeconds();
    computeCentroids(&args);
    double t2 = CycleTimer::currentSeconds();
    computeCost(&args);
    double t3 = CycleTimer::currentSeconds();

    assignmentSeconds += t1 - t0;
    centroidSeconds += t2 - t1;
    costSeconds += t3 - t2;
    iter++;
  }

  double measured = assignmentSeconds + centroidSeconds + costSeconds;
  printf("[KMeans threads]: %d\n", configuredThreads());
  printf("[KMeans iterations]: %d\n", iter);
  printf("[Profile computeAssignments]: %.3f ms (%.2f%%)\n",
         assignmentSeconds * 1000.0,
         measured > 0.0 ? assignmentSeconds * 100.0 / measured : 0.0);
  printf("[Profile computeCentroids]: %.3f ms (%.2f%%)\n",
         centroidSeconds * 1000.0,
         measured > 0.0 ? centroidSeconds * 100.0 / measured : 0.0);
  printf("[Profile computeCost]: %.3f ms (%.2f%%)\n",
         costSeconds * 1000.0,
         measured > 0.0 ? costSeconds * 100.0 / measured : 0.0);

  delete[] currCost;
  delete[] prevCost;
}
