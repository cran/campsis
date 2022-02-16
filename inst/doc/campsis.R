## ---- message=FALSE-----------------------------------------------------------
library(campsis)

## -----------------------------------------------------------------------------
model <- model_library$advan4_trans4

## -----------------------------------------------------------------------------
dataset <- Dataset(10) %>%
  add(Bolus(time=c(0,24,48), amount=1000)) %>%
  add(Observations(times=seq(0,72, by=1)))

## -----------------------------------------------------------------------------
results <- model %>% simulate(dataset, dest="RxODE", seed=1)
head(results)

## ----get_started_spaguetti_plot, fig.align='center', fig.height=4, fig.width=8----
spaghettiPlot(results, "CP")

## ----get_started_shaded_plot, fig.align='center', fig.height=4, fig.width=8----
shadedPlot(results, "CP")

## ----get_started_2arms_plot, fig.align='center', fig.height=4, fig.width=8----
arm1 <- Arm(subjects=50, label="1000 mg QD")
arm2 <- Arm(subjects=50, label="2000 mg QD")

arm1 <- arm1 %>% add(Bolus(time=c(0,24,48), amount=1000))
arm1 <- arm1 %>% add(Observations(times=seq(0,72, by=1)))

arm2 <- arm2 %>% add(Bolus(time=c(0,24,48), amount=2000))
arm2 <- arm2 %>% add(Observations(times=seq(0,72, by=1)))

dataset <- Dataset() %>% add(c(arm1, arm2))

results <- model %>% simulate(dataset, dest="RxODE", seed=1)
shadedPlot(results, "CP", scenarios="ARM")

