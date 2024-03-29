
#_______________________________________________________________________________
#----                        covariates class                               ----
#_______________________________________________________________________________

#' 
#' Covariates class.
#' 
#' @export
setClass(
  "covariates",
  representation(
  ),
  contains = "pmx_list",
  prototype = prototype(type="covariate") 
)

#_______________________________________________________________________________
#----                           getCovariates                               ----
#_______________________________________________________________________________

#' @rdname getCovariates
setMethod("getCovariates", signature = c("covariates"), definition = function(object) {
  return(object)
})

#_______________________________________________________________________________
#----                         getEventCovariates                            ----
#_______________________________________________________________________________

#' @rdname getEventCovariates
setMethod("getEventCovariates", signature = c("covariates"), definition = function(object) {
  return(object %>% select("event_covariate"))
})

#_______________________________________________________________________________
#----                         getFixedCovariates                            ----
#_______________________________________________________________________________

#' @rdname getFixedCovariates
setMethod("getFixedCovariates", signature = c("covariates"), definition = function(object) {
  return(object %>% select("fixed_covariate"))
})

#_______________________________________________________________________________
#----                       getTimeVaryingCovariates                        ----
#_______________________________________________________________________________

#' @rdname getTimeVaryingCovariates
setMethod("getTimeVaryingCovariates", signature = c("covariates"), definition = function(object) {
  return(object %>% select("time_varying_covariate"))
})

#_______________________________________________________________________________
#----                            getNames                                   ----
#_______________________________________________________________________________

setMethod("getNames", signature=c("covariates"), definition=function(object) {
  return(object@list %>% purrr::map_chr(.f=~.x@name))
})

#_______________________________________________________________________________
#----                                 select                                ----
#_______________________________________________________________________________

setMethod("select", signature=c("covariates"), definition=function(object, ...) {
  args <- list(...)
  type <- args[[1]]
  selection <- c("fixed_covariate", "event_covariate", "time_varying_covariate")
  msg <- paste0("Only these types can be selected: ", paste0("'", selection, "'", collapse=", "))
  assertthat::assert_that(type %>% length() == 1 && type %in% selection, msg=msg)
  object@list <- object@list %>% purrr::keep(~is(.x, type))
  return(object)
})

#_______________________________________________________________________________
#----                                  show                                 ----
#_______________________________________________________________________________

setMethod("show", signature=c("covariates"), definition=function(object) {
  length <- object %>% length()
  if (length==0) {
    cat("No covariates")
    cat("\n")   
  } else {
    fixedCovariates <- object %>% campsismod::select("fixed_covariate")
    if (fixedCovariates %>% length() > 0) {
      cat("Covariates:", paste0(fixedCovariates %>% getNames(), collapse=","))
      cat("\n")
    }
    timeVaryingCovariates <- object %>% campsismod::select("time_varying_covariate")
    if (timeVaryingCovariates %>% length() > 0) {
      cat("Time-varying covariates:", paste0(timeVaryingCovariates %>% getNames(), collapse=","))
      cat("\n")
    }
    eventCovariates <- object %>% campsismod::select("event_covariate")
    if (eventCovariates %>% length() > 0) {
      cat("Event-related covariates:", paste0(eventCovariates %>% getNames(), collapse=","))
      cat("\n")
    }
  }
})

