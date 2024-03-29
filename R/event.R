
#_______________________________________________________________________________
#----                           event class                                 ----
#_______________________________________________________________________________

checkEvent <- function(object) {
  checkName <- expectOne(object, "name")
  checkTimes <- expectOneOrMore(object, "times")
  checkTimesPositive <- expectPositiveValues(object, "times")
  checkFunction <- expectOne(object, "fun")
  checkDebug <- expectOne(object, "debug")
  return(c(checkName, checkTimes, checkTimesPositive, checkFunction, checkDebug))
}

#' 
#' Event class.
#' 
#' @slot name event name, character value
#' @slot times interruption times, numeric vector
#' @slot fun event function to apply at each interruption
#' @slot debug output the variables that were changed through this event
#' @export
setClass(
  "event",
  representation(
    name = "character",
    times = "numeric",
    fun = "function",
    debug = "logical"
  ),
  contains="pmx_element",
  prototype=prototype(name="", debug=FALSE),
  validity=checkEvent
)

#' 
#' Create an interruption event.
#' 
#' @param name event name, character value
#' @param times interruption times, numeric vector
#' @param fun event function to apply at each interruption
#' @param debug output the variables that were changed through this event
#' @return an event definition
#' @export
Event <- function(name=NULL, times, fun, debug=FALSE) {
  if (is.null(name)) {
    name <- "Unnamed event"
  }
  return(new("event", name=name, times=times, fun=fun, debug=debug))
}

#_______________________________________________________________________________
#----                           getName                                     ----
#_______________________________________________________________________________

setMethod("getName", signature = c("event"), definition = function(x) {
  return(paste0("EVENT (", x@name, ")"))
})
