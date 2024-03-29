library(testthat)

context("Test all methods from the arm class")

test_that("Default arm", {
  arm <- Arm()
  expect_equal(arm@id, as.integer(NA))
  expect_equal(arm@subjects, 1)
  expect_equal(arm@label, as.character(NA))
})

test_that("Custom arm", {
  arm <- Arm(id=1, subjects=10, label="Cohort A")
  expect_equal(arm@id, 1)
  expect_equal(arm@subjects, 10)
  expect_equal(arm@label, "Cohort A")
})

test_that("Covariate names can be accessed easily", {
  arm <- Arm()
  arm <- arm %>% add(Covariate("WT", ConstantDistribution(70)))
  arm <- arm %>% add(Covariate("WT2", ConstantDistribution(70)))
  expect_equal(arm %>% getCovariates() %>% getNames(), c("WT", "WT2"))
})

test_that("IOV names can be accessed easily", {
  arm <- Arm()
  arm <- arm %>% add(IOV(colname="IOV_KA", distribution=NormalDistribution(mean=0, sd=0.1)))
  expect_equal(arm %>% getIOVs() %>% getNames(), c("IOV_KA"))
})

test_that("Set subjects works as expected", {
  arm <- Arm(subjects=5)
  arm <- arm %>% setSubjects(2)
  expect_equal(arm %>% length(), 2)
})

test_that("Set label works as expected", {
  arm <- Arm(subjects=5, label="Old label")
  arm <- arm %>% setLabel("New label")
  expect_equal(arm@label, "New label")
})

