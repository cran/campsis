library(testthat)

context("Test all getSeedFor methods")

getAllSeedValues <- function(seed, replicates, iterations) {
  retValue <- NULL
  progress <- SimulationProgress(replicates=replicates)
  retValue <- retValue %>% append(getSeedForParametersSampling(seed=seed))
  for (replicate in seq_len(replicates)) {
    progress@replicate <- replicate
    progress@iterations <- as.integer(iterations)
    retValue <- retValue %>% append(getSeedForDatasetExport(seed=seed, progress=progress))
    #cat(retValue)
    #cat("\n")
    for (iteration in seq_len(iterations)) {
      progress@iteration <- iteration
      retValue <- retValue %>% append(getSeedForIteration(seed=seed, progress=progress))
    }
    #cat(retValue)
    #cat("\n")
  }
  return(retValue)
}

test_that("Original seed=1, replicates=1, iterations=1", {
  seed <- 1
  replicates <- 1
  iterations <- 1
  values <- getAllSeedValues(seed=seed, replicates=replicates, iterations=iterations)
  expect_equal(values, c(0,1,2))
})

test_that("Original seed=1, replicates=1, iterations=2", {
  seed <- 1
  replicates <- 1
  iterations <- 2
  values <- getAllSeedValues(seed=seed, replicates=replicates, iterations=iterations)
  expect_equal(values, c(0,1,2,3))
})

test_that("Original seed=1, replicates=2, iterations=2", {
  seed <- 1
  replicates <- 2
  iterations <- 2
  values <- getAllSeedValues(seed=seed, replicates=replicates, iterations=iterations)
  expect_equal(values, c(0,1,2,3,4,5,6))
})

test_that("Original seed=10, replicates=3, iterations=3", {
  seed <- 10
  replicates <- 3
  iterations <- 3
  values <- getAllSeedValues(seed=seed, replicates=replicates, iterations=iterations)
  expect_equal(values, c(seed - 1, seed + seq_len(replicates*(iterations + 1)) - 1))
})

test_that("Original seed=10, replicates=3, iterations=3", {
  seed <- 5
  replicates <- 3
  iterations <- 4
  values <- getAllSeedValues(seed=seed, replicates=replicates, iterations=iterations)
  expect_equal(values, c(seed - 1, seed + seq_len(replicates*(iterations + 1)) - 1))
})

