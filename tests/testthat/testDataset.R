library(testthat)

context("Test all methods from the dataset class")

seed <- 1
source(paste0("", "testUtils.R"))

test_that("Set subjects works as expected", {
  dataset <- Dataset() %>% setSubjects(3)
  expect_equal(dataset %>% length(), 3)
  expect_equal(dataset@arms %>% length(), 1)
  
  dataset <- Dataset(2) %>% setSubjects(5)
  expect_equal(dataset %>% length(), 5)
  expect_equal(dataset@arms %>% length(), 1)
  
  expect_error(Dataset() %>% setSubjects(c(10,20)), regexp="x must be the same length as the number of arms in dataset")
  dataset <- Dataset() %>%
    add(c(Arm(subjects=5), Arm(subjects=5)))
  dataset <- dataset %>%
    setSubjects(c(10,20))
  expect_equal(dataset@arms@list[[1]] %>% length(), 10)
  expect_equal(dataset@arms@list[[2]] %>% length(), 20)
  expect_equal(dataset %>% length(), 30)
})

test_that("Add entry, order, filter, getTimes (simple example)", {
  
  dataset <- Dataset() 
  
  # Add doses
  dataset <- dataset %>% add(Bolus(time=0, amount=100))
  dataset <- dataset %>% add(Bolus(time=24, amount=100))
  dataset <- dataset %>% add(Bolus(time=48, amount=100))

  # Add observations
  dataset <- dataset %>% add(Observations(times=seq(0, 48, by=4)))
  
  # Get times
  expect_equal(dataset %>% getTimes(), seq(0, 48, by=4))
  
  # Export to RxODE
  table1 <- dataset %>% export(dest="RxODE")
  expect_equal(nrow(table1), 16)
  expect_true(is(table1, "tbl_df"))
  
  # Export to mrgsolve
  table2 <- dataset %>% export(dest="mrgsolve")
  expect_equal(nrow(table2), 16)
  expect_true(is(table2, "tbl_df"))
})

test_that("Two arms example", {
  
  # Create 2 arms
  arm1 <- Arm(id=1, subjects=4)
  arm2 <- Arm(id=2, subjects=3)

  # Add doses in respective arms
  arm1 <- arm1 %>% add(Bolus(time=0, amount=100))
  arm2 <- arm2 %>% add(Bolus(time=0, amount=200))
    
  # Add observations
  obs <- Observations(times=seq(0, 48, by=4))
  arm1 <- arm1 %>% add(obs)
  arm2 <- arm2 %>% add(obs)
  
  # Create dataset
  dataset <- Dataset() 
  dataset <- dataset %>% add(arm1)
  dataset <- dataset %>% add(arm2)
  
  # Total number of subjects
  expect_equal(dataset %>% length(), 7)
  
  # Arms number
  expect_equal(length(dataset@arms), 2)
  
  # Export to RxODE
  table <- dataset %>% export(dest="RxODE")
  expect_equal(nrow(table), 98)
  
  # Replace numbers of subjects in second arm
  arm2Bis <- dataset@arms %>% getByIndex(2)
  arm2Bis@subjects <- as.integer(5)
  dataset <- dataset %>% replace(arm2Bis)
  
  # Total number of subjects
  expect_equal(dataset %>% length(), 9)
})

test_that("Export using config", {
  
  dataset <- Dataset() 
  
  # Add doses
  dataset <- dataset %>% add(Bolus(time=0, amount=100))
  dataset <- dataset %>% add(Bolus(time=24, amount=100))
  dataset <- dataset %>% add(Bolus(time=48, amount=100))
  
  
  # Add observations
  dataset <- dataset %>% add(Observations(times=seq(0, 48, by=10)))
  
  # Export to RxODE
  config <- DatasetConfig(defObsCmt=2)
  dataset <- dataset %>% add(config)
  table <- dataset %>% export(dest="RxODE")
  
  expect_true(all(c(1,2) %in% table$CMT))
  
})

test_that("Export constant covariates work well (N=1, N=2)", {
  
  dataset <- Dataset()
  
  # Add doses
  dataset <- dataset %>% add(Bolus(time=0, amount=100))
  dataset <- dataset %>% add(Bolus(time=24, amount=100))
  dataset <- dataset %>% add(Bolus(time=48, amount=100))
  
  # Add covariate
  dataset <- dataset %>% add(Covariate(name="WT", 70))
  dataset <- dataset %>% add(Covariate(name="HT", 180))
  dataset <- dataset %>% add(EventCovariate(name="DOSE", 100))
  
  expect_equal(dataset %>% getCovariates() %>% getNames(), c("WT", "HT", "DOSE"))
  expect_equal(dataset %>% getEventCovariates() %>% getNames(), c("DOSE"))
  
  # Add observations
  dataset <- dataset %>% add(Observations(times=seq(0, 48, by=10)))
  
  # Export to RxODE N=1
  config <- DatasetConfig(defObsCmt=2)
  dataset <- dataset %>% add(config)
  table <- dataset %>% export(dest="RxODE")
  
  expect_true(all(table$WT==70))
  expect_true(all(table$HT==180))
  expect_true(all(table$DOSE==100)) # Even if covariate can be adapted by events
  
  # Export to RxODE N=2
  arm <- dataset@arms %>% default()
  arm@subjects <- as.integer(2)
  dataset@arms <- dataset@arms %>% replace(arm)
  
  dataset <- dataset %>% add(config)
  table <- dataset %>% export(dest="RxODE")
  
  expect_true(all(table$WT==70))
  expect_true(all(table$HT==180))
  expect_true(all(table$DOSE==100)) # Even if covariate can be adapted by events
  
})

test_that("Export fixed covariates work well (N=3)", {

  arm <- Arm(id=1, subjects=3)
  
  # Add doses
  arm <- arm %>% add(Bolus(time=0, amount=100))
  arm <- arm %>% add(Bolus(time=24, amount=100))
  arm <- arm %>% add(Bolus(time=48, amount=100))
  
  # Add covariate
  arm <- arm %>% add(Covariate(name="WT", FixedDistribution(values=c(65, 70, 75))))
  arm <- arm %>% add(Covariate(name="HT", FixedDistribution(values=c(175, 180, 185))))
  
  # Add observations
  arm <- arm %>% add(Observations(times=seq(0, 48, by=10)))
  
  dataset <- Dataset()
  dataset <- dataset %>% add(arm)
  
  # Export to RxODE N=1
  config <- DatasetConfig(defObsCmt=2)
  dataset <- dataset %>% add(config)
  table <- dataset %>% export(dest="RxODE")
  
  subTable <- table %>% dplyr::select(ID, WT, HT) %>% dplyr::distinct()
  expect_equal(subTable, tibble::tibble(ID=c(1,2,3), WT=c(65,70,75), HT=c(175,180,185)))
})


test_that("Export function covariates work well (N=3)", {
  
  arm <- Arm(id=1, subjects=3)
  
  # Add doses
  arm <- arm %>% add(Bolus(time=0, amount=100))
  arm <- arm %>% add(Bolus(time=24, amount=100))
  arm <- arm %>% add(Bolus(time=48, amount=100))
  
  # Add covariate
  arm <- arm %>% add(Covariate(name="WT", FunctionDistribution(fun="rnorm", args=list(mean=70, sd=10))))
  arm <- arm %>% add(Covariate(name="HT", FunctionDistribution(fun="rnorm", args=list(mean=180, sd=20))))
  
  # Add observations
  arm <- arm %>% add(Observations(times=seq(0, 48, by=10)))
  
  dataset <- Dataset()
  dataset <- dataset %>% add(arm)
  
  # Export to RxODE N=1
  config <- new("dataset_config", def_depot_cmt=as.integer(1), def_obs_cmt=as.integer(2))
  dataset <- dataset %>% add(config)
  table <- dataset %>% export(dest="RxODE", seed=1)
  
  subTable <- table %>% dplyr::select(ID, WT, HT) %>% dplyr::distinct() %>% dplyr::mutate(WT=round(WT), HT=round(HT))
  expect_equal(subTable, tibble::tibble(ID=c(1,2,3), WT=c(64,72,62), HT=c(212,187,164)))
})

test_that("Export boostrap covariates work well (N=8)", {
  
  arm <- new("arm", id=as.integer(1), subjects=as.integer(8))
  
  # Add doses
  arm <- arm %>% add(Bolus(time=0, amount=100))
  arm <- arm %>% add(Bolus(time=24, amount=100))
  arm <- arm %>% add(Bolus(time=48, amount=100))
  
  # Add covariate
  arm <- arm %>% add(Covariate("WT", BootstrapDistribution(data=c(65, 70, 75), random=TRUE, replacement=TRUE)))
  arm <- arm %>% add(Covariate("HT", BootstrapDistribution(data=c(175, 180, 185), random=TRUE, replacement=TRUE)))
  
  # Add observations
  arm <- arm %>% add(Observations(times=seq(0, 48, by=10)))
  
  dataset <- Dataset()
  dataset <- dataset %>% add(arm)
  
  # Export to RxODE
  config <- DatasetConfig(defObsCmt=2)
  dataset <- dataset %>% add(config)
  table <- dataset %>% export(dest="RxODE", seed=1)
  
  subTable <- table %>% dplyr::select(ID, WT, HT) %>% dplyr::distinct()
  expect_equal(subTable, tibble::tibble(ID=c(1,2,3,4,5,6,7,8), WT=c(65,75,65,70,65,75,75,70), HT=c(180,185,185,175,175,175,180,180)))
})

test_that("Export occasions works well - example 1", {
  
  ds <- Dataset(2)
  
  # Add doses
  ds <- ds %>% add(Bolus(time=0, amount=100))
  ds <- ds %>% add(Bolus(time=24, amount=100))
  ds <- ds %>% add(Bolus(time=48, amount=100))
  
  # Add observations
  ds <- ds %>% add(Observations(times=seq(0, 60, by=10)))
  
  # Add occasions
  ds <- ds %>% add(Occasion("MY_OCC", values=c(1,2,3), doseNumbers=c(1,2,3)))

  # Export to RxODE
  table <- ds %>% export(dest="RxODE", seed=1)
  
  # All OCC values are used because 3 doses
  expect_equal(table$MY_OCC, rep(c(1,1,1,1,2,2,2,3,3,3), 2))
})

test_that("Export occasions works well - example 2", {
  
  ds <- Dataset(2)
  
  # Add doses
  ds <- ds %>% add(Bolus(time=0, amount=100))
  ds <- ds %>% add(Bolus(time=24, amount=100))
  
  # Add observations
  ds <- ds %>% add(Observations(times=seq(0, 60, by=10)))
  
  # Add occasions
  ds <- ds %>% add(Occasion("MY_OCC", values=c(1,2,3), doseNumbers=c(1,2,3)))
  
  # Export to RxODE
  table <- ds %>% export(dest="RxODE", seed=1)
  
  # Check value 3 is not used (no 3rd dose)
  expect_equal(table$MY_OCC, rep(c(1,1,1,1,2,2,2,2,2), 2))
})


test_that("Export occasions works well - example 3", {
  
  ds <- Dataset(2)
  
  # Add doses
  ds <- ds %>% add(Bolus(time=0, amount=100))
  ds <- ds %>% add(Bolus(time=24, amount=100))
  ds <- ds %>% add(Bolus(time=48, amount=100))
  ds <- ds %>% add(Bolus(time=72, amount=100))
  
  # Add observations
  ds <- ds %>% add(Observations(times=seq(0, 80, by=10)))
  
  # Add occasions (skip occasion on dose 3)
  ds <- ds %>% add(Occasion("MY_OCC", values=c(1,2,4), doseNumbers=c(1,2,4)))
  
  # Export to RxODE
  table <- ds %>% export(dest="RxODE", seed=1)
  
  # All OCC values are used because 3 doses
  expect_equal(table$MY_OCC, rep(c(1,1,1,1,2,2,2,2,2,2,2,4,4), 2))
})

test_that("Export occasions works well - example 4", {
  
  ds <- Dataset(2)
  
  # Add doses
  ds <- ds %>% add(Bolus(time=0, amount=100))
  ds <- ds %>% add(Bolus(time=24, amount=100))
  ds <- ds %>% add(Bolus(time=48, amount=100))
  ds <- ds %>% add(Bolus(time=72, amount=100))
  
  # Add observations
  ds <- ds %>% add(Observations(times=seq(0, 80, by=10)))
  
  # Add occasions (skip occasion on dose 3)
  ds <- ds %>% add(Occasion("MY_OCC", values=c(2,3,4), doseNumbers=c(2,3,4)))
  
  # Export to RxODE
  table <- ds %>% export(dest="RxODE", seed=1)
  
  # Is this the expected behaviour ? This is arbitrary, for sure
  expect_equal(table$MY_OCC, rep(c(0,0,0,0,2,2,2,3,3,3,3,4,4), 2))
})


test_that("Occasion can be added into arms", {

  addProtocol <- function(x) {
    # Add doses
    x <- x %>% add(Bolus(time=0, amount=100))
    x <- x %>% add(Bolus(time=24, amount=100))
    x <- x %>% add(Bolus(time=48, amount=100))
    
    # Add observations
    x <- x %>% add(Observations(times=seq(0, 60, by=10)))
    
    # Add occasions
    x <- x %>% add(Occasion("MY_OCC", values=c(1,2,3), doseNumbers=c(1,2,3)))
  }
  
  arm1 <- Arm(id=1, subjects=1) %>% addProtocol()
  arm2 <- Arm(id=2, subjects=1) %>% addProtocol()
  ds <- Dataset() %>% add(c(arm1, arm2))
  
  # Export to RxODE
  table <- ds %>% export(dest="RxODE", seed=1)
  
  # All OCC values are used because 3 doses
  expect_equal(table$MY_OCC, rep(c(1,1,1,1,2,2,2,3,3,3), 2))
})

test_that("Export IOV works well - example 1", {
  
  ds <- Dataset(2)
  
  # Add doses
  ds <- ds %>% add(Bolus(time=0, amount=100))
  ds <- ds %>% add(Bolus(time=24, amount=100))
  ds <- ds %>% add(Bolus(time=48, amount=100))
  ds <- ds %>% add(Bolus(time=72, amount=100))
  
  # Add observations
  ds <- ds %>% add(Observations(times=seq(0, 80, by=10)))
  
  # Add occasions (skip occasion on dose 3)
  ds <- ds %>% add(IOV("IOV_KA", distribution=NormalDistribution(0, sd=1), doseNumbers=c(3,4)))
  
  # Export to RxODE
  table <- ds %>% export(dest="RxODE", seed=1)
  
  # Arbitrary but OK
  expect_equal(round(table$IOV_KA,2), c(0,0,0,0,0,0,0,-0.63,-0.63,-0.63,-0.63,0.18,0.18,0,0,0,0,0,0,0,-0.84,-0.84,-0.84,-0.84,1.60,1.60))
})

test_that("Export IOV works well - example 2", {
  
  ds <- Dataset(2)
  
  # Add doses
  ds <- ds %>% add(Bolus(time=0, amount=100))
  ds <- ds %>% add(Bolus(time=24, amount=100))
  ds <- ds %>% add(Bolus(time=48, amount=100))
  ds <- ds %>% add(Bolus(time=72, amount=100))
  
  # Add observations
  ds <- ds %>% add(Observations(times=seq(0, 80, by=10)))
  
  # Add occasions (skip occasion on dose 3)
  ds <- ds %>% add(IOV("IOV_KA", distribution=NormalDistribution(0, sd=1), doseNumbers=c(1,3)))
  
  # Export to RxODE
  table <- ds %>% export(dest="RxODE", seed=1)
  
  # Arbitrary but OK
  expect_equal(round(table$IOV_KA,2), c(-0.63,-0.63,-0.63,-0.63,-0.63,-0.63,-0.63,0.18,0.18,0.18,0.18,0.18,0.18,-0.84,-0.84,-0.84,-0.84,-0.84,-0.84,-0.84,1.60,1.60,1.60,1.60,1.60,1.60))
})

test_that("Replace, delete, find, contains methods works well", {
  ds <- Dataset(1)
  
  # Add 3 doses
  ds <- ds %>% add(Bolus(time=c(0,24,48), amount=100))

  # Add observations
  ds <- ds %>% add(Observations(c(1,2,3)))
  
  # Add IOV
  ds <- ds %>% add(IOV("IOV_KA", distribution=c(1,2,3)))
  
  # Add occasions
  ds <- ds %>% add(Occasion("OCC", values=c(1,2,3), doseNumbers=c(1,2,3)))
  
  # Add covariate
  ds <- ds %>% add(Covariate("WT", 0))
  
  # Add dose adaptation
  ds <- ds %>% add(DoseAdaptation("AMT*2", compartments=1))
  
  # Double the first dose
  updatedDs <- ds %>% replace(Bolus(time=0, amount=200))
  expect_true(updatedDs %>% contains(Bolus(time=0, amount=0))) # Only time matters
  expect_equal((updatedDs %>% find(Bolus(time=0, amount=0)))@amount, 200)
  
  # Change IOV distribution
  updatedDs <- ds %>% replace(IOV("IOV_KA", distribution=c(1,2,3,4)))
  expect_true(updatedDs %>% contains(IOV("IOV_KA", 0))) # Only name matters
  expect_equal((updatedDs %>% find(IOV("IOV_KA", 0)))@distribution, FixedDistribution(c(1,2,3,4)))
  
  # Change occasion numbers
  updatedDs <- ds %>% replace(Occasion("OCC", values=c(1,2), doseNumbers=c(1,2)))
  expect_true(updatedDs %>% contains(Occasion("OCC", 0, 0))) # Only name matters
  expect_equal((updatedDs %>% find(Occasion("OCC", 0, 0)))@values, c(1,2))
  
  # Change covariate value
  updatedDs <- ds %>% replace(Covariate("WT", 1))
  expect_true(updatedDs %>% contains(Covariate("WT", 0))) # Only name matters
  expect_equal((updatedDs %>% find(Covariate("WT", 0)))@distribution, ConstantDistribution(1))
  
  # Adapt dose adaptation formula
  updatedDs <- ds %>% replace(DoseAdaptation("AMT*3", compartments=1))
  expect_true(updatedDs %>% contains(DoseAdaptation("", compartments=1))) # Only compartments matters
  expect_equal((updatedDs %>% find(DoseAdaptation("", compartments=1)))@formula, "AMT*3")
  
  # Delete the last dose
  bolus <- Bolus(time=48, amount=100)
  expect_true(ds %>% contains(bolus))
  updatedDs <- ds %>% delete(bolus)
  expect_false(updatedDs %>% contains(bolus))
  
  # Delete IOV
  iov <- IOV("IOV_KA", distribution=c(1,2,3))
  expect_true(ds %>% contains(iov))
  updatedDs <- ds %>% delete(iov)
  expect_false(updatedDs %>% contains(iov))
  
  # Delete occasions
  occ <- Occasion("OCC", values=c(1,2,3), doseNumbers=c(1,2,3))
  expect_true(ds %>% contains(occ))
  updatedDs <- ds %>% delete(occ)
  expect_false(updatedDs %>% contains(occ))
  
  # Delete covariate
  cov <- Covariate("WT", 0)
  expect_true(ds %>% contains(cov))
  updatedDs <- ds %>% delete(cov)
  expect_false(updatedDs %>% contains(cov))
  
  # Delete observations
  obs <- Observations(c(1,2,3))
  expect_true(ds %>% contains(obs))
  updatedDs <- ds %>% delete(obs)
  expect_false(updatedDs %>% contains(obs))
  
  # Delete dose adaptation
  doseAdaptation <- DoseAdaptation("", compartments=1)
  expect_true(ds %>% contains(doseAdaptation))
  updatedDs <- ds %>% delete(doseAdaptation)
  expect_false(updatedDs %>% contains(doseAdaptation))
})

test_that("Export works well even if objects are defined in a different order", {
  regFilename <- "objects_defined_in_different_order"
  
  arm1 <- Arm(1, subjects=1) %>%
    add(Bolus(time=0, amount=1000, compartment=1, ii=24, addl=2)) %>%
    add(Observations(times=seq(0,72, by=5))) %>%
    add(TimeVaryingCovariate("TVCOV", data.frame(TIME=c(0, 10), VALUE=c(10, 15)))) %>%
    add(Occasion("OCC", values=c(1,2,3), doseNumbers=c(1,2,3))) %>%
    add(Covariate("BW", 70)) %>%
    add(Covariate("HT", 180))
    
  
  arm2 <- Arm(2, subjects=1) %>%
    add(Covariate("HT", 170)) %>%
    add(Covariate("BW", 60)) %>%
    add(Occasion("OCC", values=c(1,2,3), doseNumbers=c(1,2,3))) %>%
    add(TimeVaryingCovariate("TVCOV", data.frame(TIME=c(0, 10), VALUE=c(9, 14)))) %>%
    add(Observations(times=seq(0,72, by=5))) %>%
    add(Bolus(time=0, amount=2000, compartment=1, ii=24, addl=2))
  
  ds <- Dataset() %>% add(c(arm1, arm2))
  table <- ds %>% export(dest="RxODE")
  
  datasetRegressionTest(dataset=ds, seed=1, doseOnly=FALSE,
                        filename=regFilename)
  
})

test_that("Any layer added to the multiple-arm dataset apply to each arm.", {
  regFilename <- "layer_added_to_multiple_arm_dataset"
  
  arm1 <- Arm(label="10 mg") %>%
    add(Bolus(time=0, amount=10))
  
  arm2 <- Arm(label="20 mg") %>%
    add(Bolus(time=0, amount=20))
  
  dataset <- Dataset() %>%
    add(c(arm1, arm2))
  
  dataset <- dataset %>%
    setSubjects(c(4,8))
  
  expect_equal(length(dataset), 12)
  
  dataset <- dataset %>% 
    add(IOV("IOVKA", distribution=NormalDistribution(0, 1))) %>%
    add(Bootstrap(data=data.frame(ID=1:20, BW=70 + 1:20), id="ID", replacement=TRUE)) %>%
    add(Observations(1:5))
  
  # Check IOV has been created in arm1
  arm1 <- dataset %>% find(Arm(1))
  expect_true(!is.null(arm1 %>% find(IOV("IOVKA", distribution=0))))
  
  # Check IOV has been created in arm2
  arm2 <- dataset %>% find(Arm(2))
  expect_true(!is.null(arm2 %>% find(IOV("IOVKA", distribution=0))))
  
  table <- dataset %>% export(dest="RxODE", seed=1)
  
  datasetRegressionTest(dataset=dataset, seed=1, doseOnly=FALSE,
                        filename=regFilename)
})

test_that("Boluses/Infusions can now be given at same time and into the same compartment", {
  
  # Now this code is working
  dataset <- Dataset() %>%
    add(Bolus(time=0, amount=100, compartment=1)) %>%
    add(Bolus(time=0, amount=100, compartment=1, ii=24, add=1))
  
  # Amounts have been added
  bolusTime0 <- dataset %>%
    find(Bolus(time=0, amount=0, compartment=1))
  expect_equal(bolusTime0@amount, 100 + 100)
  
  # Check 200 is given at 0, 100 at time 24
  expect_true("-> Adm. times (bolus into CMT=1): 0 (200),24 (100)" %in% capture.output(show(dataset)))
  
  # Same code with infusions
  dataset <- Dataset() %>%
    add(Infusion(time=0, amount=100, compartment=2)) %>%
    add(Infusion(time=0, amount=100, compartment=2, ii=24, add=1))
  
  # Infusion amounts have been added
  infusionTime0 <- dataset %>%
    find(Infusion(time=0, amount=0, compartment=2))
  expect_equal(infusionTime0@amount, 100 + 100)
  
  # Check 200 is given at 0, 100 at time 24
  expect_true("-> Adm. times (infusion into CMT=2): 0 (200),24 (100)" %in% capture.output(show(dataset)))
  
  # Same code but rate is provided in second infusion
  # Not accepted
  expect_error(Dataset() %>%
    add(Infusion(time=0, amount=100, compartment=2)) %>%
    add(Infusion(time=0, amount=100, compartment=2, ii=24, add=1, duration=2)),
    regexp="Element 'INFUSION \\[TIME=0, CMT=2\\]' already exists in dataset and has different properties\\. Amounts cannot be added\\.")
  
  # Similar test but with 2 arms
  expect_error(Dataset() %>%
    add(Arm(subjects=10)) %>%
    add(Arm(subjects=10)) %>%
    add(Infusion(time=0, amount=100, compartment=2)) %>%
    add(Infusion(time=0, amount=100, compartment=2, ii=24, add=1, duration=2)),
    regexp="Element 'INFUSION \\[TIME=0, CMT=2\\]' already exists in ARM 1 and has different properties\\. Amounts cannot be added\\.")
  # Note that the same error would have been raised in ARM 2 if process was not interrupted.
})
