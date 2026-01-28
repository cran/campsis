#_______________________________________________________________________________
#----                       scenario_actions class                          ----
#_______________________________________________________________________________

#' 
#' Scenario actions class.
#' 
#' @export
setClass(
  "scenario_actions",
  representation(
  ),
  contains = "pmx_list",
  prototype = prototype(type="scenario_action") 
)

#_______________________________________________________________________________
#----                           loadFromJSON                                ----
#_______________________________________________________________________________

setMethod("loadFromJSON", signature=c("scenario_actions", "json_element"), definition=function(object, json) {
  for (jsonAction in json@data) {
    if (jsonAction$type=="replace_action") {
      object <- object %>%
        add(loadFromJSON(ReplaceAction(NA), JSONElement(jsonAction)))
    } else {
      stop("Only replacement actions are supported for now")
    }
  }
  return(object)
})

