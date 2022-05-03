## ---- message=FALSE-----------------------------------------------------------
library(campsis)

## -----------------------------------------------------------------------------
model <- model_library$advan4_trans4

## -----------------------------------------------------------------------------
dataset <- Dataset(10) %>%
  add(Bolus(time=0, amount=1000, ii=24, addl=2)) %>%
  add(Observations(times=seq(0,72, by=1)))

## ---- message=F---------------------------------------------------------------
results <- model %>% simulate(dataset, seed=1)
head(results)

## ----get_started_spaguetti_plot, fig.align='center', fig.height=4, fig.width=8----
spaghettiPlot(results, "CP")

## ----get_started_shaded_plot, fig.align='center', fig.height=4, fig.width=8----
shadedPlot(results, "CP")

## ----get_started_2arms_plot, fig.align='center', fig.height=4, fig.width=8, message=F----
# First treatment arm
arm1 <- Arm(subjects=50, label="1000 mg QD") %>%
  add(Bolus(time=0, amount=1000, ii=24, addl=2)) %>%
  add(Observations(times=seq(0,72, by=1)))

# Second treatment arm
arm2 <- Arm(subjects=50, label="2000 mg QD") %>%
  add(Bolus(time=0, amount=2000, ii=24, addl=2)) %>%
  add(Observations(times=seq(0,72, by=1)))

dataset <- Dataset() %>% add(c(arm1, arm2))

results <- model %>% simulate(dataset, seed=1)
shadedPlot(results, "CP", scenarios="ARM")

