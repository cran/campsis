library(testthat)

context("Test the simulate method with time-to-event models (TTE)")

source(paste0("", "testUtils.R"))

test_that(getTestName("Simulate simple TTE model"), {
  if (skipLongTests()) return(TRUE)
  regFilename <- "simple_tte_model"
  model <- read.campsis(paste0(testFolder, "models/simple_tte_model/"))
  
  events <- Events()
  duration <- 24
  
  event <- Event(name="Check patient state", times=seq(1,duration), fun=function(inits) {
    updateCount <- inits$A_SURVIVAL < inits$TRIGGER
    
    # Update counter and trigger
    inits$COUNT <- ifelse(updateCount, inits$COUNT + 1, inits$COUNT)
    inits$TRIGGER <- ifelse(updateCount, runif(updateCount %>% length(), 0, 1), inits$TRIGGER)

    # Reset survival compartment
    inits$A_SURVIVAL <- ifelse(updateCount, 1, inits$A_SURVIVAL)
    
    return(inits)
  })
  
  ds <- Dataset(2) %>%
    add(EventCovariate("COUNT", 0)) %>%
    add(EventCovariate("TRIGGER", UniformDistribution(0, 1))) %>%
    add(Observations(times=seq(0, duration, by=0.1)))
  
  events <- events %>% add(event)

  # p1 <- spaghettiPlot(results1, "A_SURVIVAL")
  # p2 <- spaghettiPlot(results1, "COUNT")
  # p3 <- spaghettiPlot(results1, "TRIGGER")
  # gridExtra::grid.arrange(p1, p2, p3, ncol=1)
  # 
  # p1 <- spaghettiPlot(results2, "A_SURVIVAL")
  # p2 <- spaghettiPlot(results2, "COUNT")
  # p3 <- spaghettiPlot(results2, "TRIGGER")
  # gridExtra::grid.arrange(p1, p2, p3, ncol=1)
  
  simulation <- expression(simulate(model=model, dataset=ds, dest=destEngine,
                                    events=events, outvars=c("COUNT", "TRIGGER"), seed=5))
  test <- expression(
    outputRegressionTest(results, output=c("A_SURVIVAL", "TRIGGER"), filename=regFilename)
  )
  campsisTest(simulation, test, env=environment())
})
