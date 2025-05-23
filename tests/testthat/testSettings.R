library(testthat)

context("Test the simulation settings")

test_that("Default simulation settings work as expected", {
  
  settings <- Settings()
  
  # Hardware settings, default values
  expect_equal(settings@hardware@cpu, 1)
  expect_equal(settings@hardware@replicate_parallel, FALSE)
  expect_equal(settings@hardware@scenario_parallel, FALSE)
  expect_equal(settings@hardware@slice_parallel, FALSE)
  expect_equal(settings@hardware@slice_size, as.integer(NA))
  expect_equal(settings@hardware@dataset_parallel, FALSE)
  expect_equal(settings@hardware@dataset_slice_size, 500)
  expect_equal(settings@hardware@auto_setup_plan, FALSE)
  
  # Solver settings, default values
  expect_equal(settings@solver@atol, 1e-08)
  expect_equal(settings@solver@rtol, 1e-08)
  expect_equal(settings@solver@hmax, as.numeric(NA))
  expect_equal(settings@solver@maxsteps, 70000)
  expect_equal(settings@solver@method, "liblsoda")
  
  # NOCB settings, default values
  expect_equal(settings@nocb@enable, NA)
  expect_equal(settings@nocb@variables, character(0))
  
  expect_true("Hardware: default" %in% capture.output(show(settings)))
  expect_true("Solver: default" %in% capture.output(show(settings)))
})

test_that("Hardware settings work as expected", {
  
  settings <- Settings(Hardware(cpu=10, slice_parallel=TRUE, slice_size=100,
                                dataset_parallel=TRUE, dataset_slice_size=250))
  
  # Hardware settings, default values
  expect_equal(settings@hardware@cpu, 10)
  expect_equal(settings@hardware@replicate_parallel, FALSE)
  expect_equal(settings@hardware@scenario_parallel, FALSE)
  expect_equal(settings@hardware@slice_parallel, TRUE)
  expect_equal(settings@hardware@slice_size, as.integer(100))
  expect_equal(settings@hardware@dataset_parallel, TRUE)
  expect_equal(settings@hardware@dataset_slice_size, 250)
  expect_equal(settings@hardware@auto_setup_plan, TRUE)
  
  expect_true("Hardware: 10 CPU core(s), parallelisation enabled (dataset, slices)" %in% capture.output(show(settings)))
})

test_that("Solver settings work as expected", {
  
  settings <- Settings(Solver(atol=1e-12, rtol=1e-12))
  
  # Hardware settings, overridden values
  expect_equal(settings@solver@atol, 1e-12)
  expect_equal(settings@solver@rtol, 1e-12) 
  
  expect_true("Solver: atol=1.0e-12, rtol=1.0e-12, hmax=NA, maxsteps=70000, method=liblsoda" %in% capture.output(show(settings)))
})


test_that("NOCB settings work as expected", {
  
  settings <- Settings(NOCB(FALSE, "OCC"))

  # NOCB settings, overridden values
  expect_equal(settings@nocb@enable, FALSE)
  expect_equal(settings@nocb@variables, "OCC")
  
  expect_true("NOCB: enable=FALSE, variables={OCC}" %in% capture.output(show(settings)))
})

test_that("Declare settings work as expected", {
  
  settings <- Settings(Declare("OCC"))
  
  # Declare settings, overridden values
  expect_equal(settings@declare@variables, "OCC")
  
  expect_true("Declare: variables={OCC}" %in% capture.output(show(settings)))
})

test_that("Progress settings work as expected", {
  
  settings <- Settings(Progress(tick_slice=FALSE))
  
  # Declare settings, overridden values
  expect_equal(settings@progress@tick_slice, FALSE)
  
  expect_true("Progress: tick_slice=FALSE" %in% capture.output(show(settings)))
})

test_that("Replication/parallelisation settings work as expected", {
  
  # Example of settings with replication and parallelisation
  settings <- Settings(Hardware(cpu=6, replicate_parallel=T), AutoReplicationSettings(wishart=TRUE, odf=50, sdf=1000))

  expect_true("Hardware: 6 CPU core(s), parallelisation enabled (replicates)" %in% capture.output(show(settings)))
  expect_true(any(grepl(pattern="Replication settings: .*", x=capture.output(show(settings))))) # Stay generic because show method is implemented in campsismod
})


test_that("Unknown settings shouldn't be accepted", {
  expect_error(Settings(Hardware(cpu=4, replicate_parallel=TRUE), Dataset()), regexp="Unknown argument detected")
  expect_error(Settings(Hardware(cpu=4, replicate_parallel=TRUE), A=c(1,2,3)), regexp="Unknown argument detected")
})
