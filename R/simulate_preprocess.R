
#' Pre-process destination engine. Throw an error message if the destination 
#' engine is not installed.
#'
#' @param dest destination engine
#' @return 'rxode2', 'RxODE' or 'mrgsolve'
#' @keywords internal
#' 
preprocessDest <- function(dest) {
  if (is.null(dest)) {
    if (find.package("rxode2", quiet=TRUE) %>% length() > 0) {
      dest <- "rxode2" # Default package
    } else if (find.package("RxODE", quiet=TRUE) %>% length() > 0) {
      dest <- "RxODE"
    } else if (find.package("mrgsolve", quiet=TRUE) %>% length() > 0) {
      dest <- "mrgsolve"
    } else {
      stop("Simulation engine 'rxode2', 'RxODE' or 'mrgsolve' is required to run CAMPSIS")
    }
  } else if (is.vector(dest)) {
    if (!(dest %in% c("rxode2", "RxODE", "mrgsolve"))) {
      stop("Argument 'dest' must be one of: 'rxode2', 'RxODE', 'mrgsolve' or NULL")
    }
    if (find.package(dest, quiet=TRUE) %>% length()==0) {
      stop(paste0("Simulation engine '", dest, "' is not installed"))
    }
  } else {
    # Do nothing, dest can also be the simulation engine in its S4 form
  }
  return(dest)
}

#' Pre-process events.
#'
#' @param events interruption events
#' @keywords internal
#' 
preprocessEvents <- function(events) {
  if (is.null(events)) {
    return(Events())
  } else {
    return(events)
  }
}

#' Pre-process scenarios.
#'
#' @param scenarios scenarios
#' @keywords internal
#' 
preprocessScenarios <- function(scenarios) {
  if (is.null(scenarios)) {
    return(Scenarios() %>% add(Scenario()))
  } else {
    return(scenarios)
  }
}

#' Pre-process function argument.
#'
#' @param fun function or lambda formula
#' @param name function name
#' @return a function in any case
#' @importFrom assertthat assert_that
#' @importFrom plyr is.formula
#' @importFrom rlang as_function
#' @keywords internal
#' 
preprocessFunction <- function(fun, name) {
  if (is.null(fun)) {
    fun <- function(x){x}
    return(fun)
  } else {
    assertthat::assert_that(is.function(fun) || plyr::is.formula(fun),
                            msg=paste0(name, " must be a function or a lambda formula"))
    if (plyr::is.formula(fun)) {
      fun <- rlang::as_function(fun)
      # Class of fun is c("rlang_lambda_function","function")
      # However, not accepted as argument if method signature is "function"... Bug?
      # Workaround is to set a unique class
      class(fun) <- "function"
    }
    return(fun)
  }
}

#' Preprocess 'outvars' argument. 'Outvars' is a character vector which tells
#' CAMPSIS the mandatory columns to keep in the output dataframe.
#'
#' @param outvars character vector or function
#' @return outvars
#' @importFrom assertthat assert_that
#' @keywords internal
#' 
preprocessOutvars <- function(outvars) {
  if (is.null(outvars)) {
    return(character(0))
  } else {
    assertthat::assert_that(is.character(outvars), 
                            msg="outvars must be a character vector with the column names to keep")
    
    # In any cases, we should never see these special variables
    outvars <- outvars[!(toupper(outvars) %in% c("ID", "EVID", "CMT", "AMT", "TIME", "ARM"))]
    return(outvars)
  }
}

#' Preprocess 'replicates' argument.
#' 
#' @param replicates number of replicates
#' @return same number, but as integer
#' @importFrom assertthat assert_that
#' @keywords internal
#' 
preprocessReplicates <- function(replicates) {
  assertthat::assert_that(is.numeric(replicates) && replicates%%1==0 && replicates > 0,
                          msg="replicates not a positive integer")
  return(as.integer(replicates))
}

#' Preprocess the simulation settings.
#' 
#' @param settings simulation settings
#' @param dest destination engine
#' @return updated simulation settings
#' @importFrom assertthat assert_that
#' @keywords internal
#' 
preprocessSettings <- function(settings, dest) {
  # Use default settings if not specified
  if (is.null(settings)) {
    settings <- Settings()
  }
  
  # Check if NOCB is specified
  enable <- settings@nocb@enable
  if (is.na(enable)) {
    if (dest=="mrgsolve") {
      enable <- TRUE
    } else {
      enable <- FALSE
    }
  }
  # Assign final value
  settings@nocb@enable <- enable
  
  # Preprocess slice_size
  if (is.na(settings@hardware@slice_size)) {
     if (dest=="mrgsolve") {
       settings@hardware@slice_size <- as.integer(500)
     } else {
       # There seems to be an issue in RxODE/rxode2 when dealing with large datasets
       # From what I notice, a too large slice size (e.g. > 25) slows down RxODE/rxode2
       # while mrgsolve can work with a large slice size without any problem...
       settings@hardware@slice_size <- as.integer(6)
     }
  }
  
  return(settings)
}

#' Preprocess 'dosing' argument.
#' 
#' @param dosing dosing argument, logical value
#' @return user value, if not specified, return FALSE (observations only)
#' @importFrom assertthat assert_that
#' @keywords internal
#' 
preprocessDosing <- function(dosing) {
  if (is.null(dosing)) {
    dosing <- FALSE
  }
  assertthat::assert_that(is.logical(dosing) && dosing %>% length()==1 && !is.na(dosing),
                          msg="dosing not a logical value TRUE/FALSE")
  return(dosing)
}

#' Preprocess subjects ID's.
#' 
#' @param dataset current dataset, data frame form
#' @return list of consecutive ID's
#' @importFrom assertthat assert_that
#' @keywords internal
#' 
preprocessIds <- function(dataset) {
  ids <- unique(dataset$ID)
  maxID <- max(ids)
  assertthat::assert_that(all(ids==seq_len(maxID)), msg="ID's must be consecutive numbers, starting at 1")
  return(ids)
}

#' Preprocess ARM column. Add ARM equation in model automatically.
#' 
#' @param dataset current dataset, data frame form
#' @param model model
#' @return updated model
#' @importFrom assertthat assert_that
#' @keywords internal
#' 
preprocessArmColumn <- function(dataset, model) {
  if ("ARM" %in% colnames(dataset)) {
    pkRecord <- model@model %>% getByName("MAIN")
    pkRecord <- pkRecord %>% add(Equation("ARM", "ARM"))
    model@model <- model@model %>% replace(pkRecord)
  }
  if ("EVENT_RELATED" %in% colnames(dataset)) {
    pkRecord <- model@model %>% getByName("MAIN")
    pkRecord <- pkRecord %>% add(Equation("EVENT_RELATED", "EVENT_RELATED"))
    model@model <- model@model %>% replace(pkRecord)
  }
  return(model)
}

#' Preprocess 'slices' argument.
#' 
#' @param slices slices argument corresponding to the number of subjects simulated at once
#' @return slices if not NULL, otherwise total number of subjects
#' @importFrom assertthat assert_that
#' @keywords internal
#' 
preprocessSlices <- function(slices, maxID) {
  if (is.null(slices)) {
    return(maxID)
  } else {
    assertthat::assert_that(is.numeric(slices) && slices%%1==0 && slices > 0,
                            msg="slices not a positive integer")
    return(slices)
  }
}

#' Return the 'DROP_OTHERS' string that may be used in the 'outvars' vector for
#' RxODE/mrgsolve to drop all others variables that are usually output in the resulting data frame.
#' 
#' @return a character value
#' @keywords internal
#' 
dropOthers <- function() {
  return("DROP_OTHERS")
}

#' Process 'DROP_OTHERS'.
#'
#' @param x the current data frame
#' @param outvars variables to keep
#' @param dropOthers logical value
#' @return processed data frame
#' @keywords internal
#' 
processDropOthers <- function(x, outvars=character(0), dropOthers) {
  if (!dropOthers) {
    return(x)
  }
  outvars_ <- outvars[!(outvars %in% dropOthers())]
  out <- c("ID", "TIME", "ARM", "EVENT_RELATED", outvars_)
  names <- colnames(x)
  return(x[, names[names %in% out]])
}