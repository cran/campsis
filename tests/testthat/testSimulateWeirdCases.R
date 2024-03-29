library(testthat)

context("Test that simulations with weird cases work as expected")

seed <- 1
source(paste0("", "testUtils.R"))

test_that(getTestName("Simulate a bolus without observation"), {
  model <- model_suite$testing$nonmem$advan4_trans4

  dataset <- Dataset() %>%
    add(Bolus(time=0, amount=1000))

  simulation <- expression()
  test <- expression(
    expect_error(simulate(model=model, dataset=dataset, dest=destEngine, seed=seed),
                 regexp="Dataset does not contain any observation")
  )
  campsisTest(simulation, test, env=environment())
})

test_that(getTestName("Simulate a bolus with single observation at time 0"), {
  model <- model_suite$testing$nonmem$advan4_trans4

  dataset <- Dataset() %>%
    add(Bolus(time=0, amount=1000)) %>%
    add(Observations(time=0))

  simulation <- expression(simulate(model=model, dataset=dataset, dest=destEngine, seed=seed))
  test <- expression(
    expect_equal(nrow(results), 1),
    expect_equal(results[c("ID", "TIME", "CP")], tibble::tibble(ID=1, TIME=0, CP=0))
  )
  campsisTest(simulation, test, env=environment())
})

test_that(getTestName("Simulate a model which is not valid"), {
  model <- model_suite$testing$nonmem$advan4_trans4

  # Corrupt name slot of parameter KA
  model@parameters@list[[1]]@name <- c("KA", "KA2")

  dataset <- Dataset() %>%
    add(Bolus(time=0, amount=1000)) %>%
    add(Observations(time=0))

  simulation <- expression()
  test <- expression(
    expect_error(simulate(model=model, dataset=dataset, dest=destEngine, seed=seed),
                 regexp="name is length 2. Should be 1.")
  )
  campsisTest(simulation, test, env=environment())
})

test_that(getTestName("Simulate a dataset which is not valid"), {
  model <- model_suite$testing$nonmem$advan4_trans4

  dataset <- Dataset() %>%
    add(Bolus(time=0, amount=1000)) %>%
    add(Observations(time=0))

  # Corrupt amount slot of first bolus
  dataset@arms@list[[1]]@protocol@treatment@list[[1]]@amount <- c(1000,1000)

  simulation <- expression()
  test <- expression(
    expect_error(simulate(model=model, dataset=dataset, dest=destEngine, seed=seed),
                 regexp="amount is length 2. Should be 1.")
  )
  campsisTest(simulation, test, env=environment())
})

test_that(getTestName("Covariates must be trimmed by campsis to avoid issues"), {
 
  regFilename <- "trim_covariate"
  
   model <- CampsisModel() %>%
    add(Equation("EQ_DUMMY", "0")) %>% # Needed for rxode2 only
    add(Ode("A_DUMMY", "0")) %>% # Needed
    add(Equation("MY_COV", "COV0 + THETA_SLOPE*t"), pos=Position(OdeRecord())) %>%
    add(Theta("SLOPE", value=1.0))
  
  dataset <- Dataset(3) %>%
    add(Bolus(time=0, amount=1, compartment=1)) %>%
    add(Covariate("COV0 ", c(10,20,30))) %>% # Trailing space has been voluntarily added
    add(Observations(c(0,1,2,3,4,5)))
  
  # Note: without trim,
  # rxode2: error is raised
  # mrgsolve: no error is raised. Variable not initialised properly.
  
  simulation <- expression(simulate(model=model, dataset=dataset, dest=destEngine, seed=seed, outvars="MY_COV"))
  test <- expression(
    outputRegressionTest(results, output="MY_COV", filename=regFilename)
  )
  campsisTest(simulation, test, env=environment())
})
