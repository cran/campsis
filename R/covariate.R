
#_______________________________________________________________________________
#----                      covariate class (abstract)                       ----
#_______________________________________________________________________________

checkCovariate <- function(object) {
  return(expectOneForAll(object, c("name", "distribution")))
}

#' 
#' Covariate class.
#' 
#' @slot name covariate name, single character value
#' @slot distribution covariate distribution
#' @export
setClass(
  "covariate",
  representation(
    name = "character",
    distribution = "distribution"
  ),
  contains="pmx_element",
  validity=checkCovariate
)

setMethod("getName", signature = c("covariate"), definition = function(x) {
  return(x@name)
})

#_______________________________________________________________________________
#----                         fixed_covariate class                         ----
#_______________________________________________________________________________

#' 
#' Fixed covariate class.
#' 
#' @export
setClass(
  "fixed_covariate",
  representation(
  ),
  contains="covariate"
)

#' 
#' Create a non time-varying (fixed) covariate.
#' 
#' @param name covariate name, single character value
#' @param distribution covariate distribution
#' @return a fixed covariate  
#' @export
Covariate <- function(name, distribution) {
  return(new("fixed_covariate", name=trimws(name), distribution=toExplicitDistribution(distribution)))
}

#_______________________________________________________________________________
#----                         event_covariate class                         ----
#_______________________________________________________________________________

#' 
#' Event covariate class.
#' 
#' @export
setClass(
  "event_covariate",
  representation(
  ),
  contains="covariate"
)

#' 
#' Create an event covariate. These covariates can be modified further in
#' interruption events.
#' 
#' @param name covariate name, character
#' @param distribution covariate distribution at time 0
#' @return a time-varying covariate  
#' @export
EventCovariate <- function(name, distribution) {
  return(new("event_covariate", name=trimws(name), distribution=toExplicitDistribution(distribution)))
}

#_______________________________________________________________________________
#----                         time_varying_covariate class                  ----
#_______________________________________________________________________________

#' 
#' Time-varying covariate class.
#' 
#' @export
setClass(
  "time_varying_covariate",
  representation(
    table="data.frame"
  ),
  contains="covariate"
)

#' 
#' Create a time-varying covariate. This covariate will be implemented using 
#' EVID=2 rows in the exported dataset and will not use interruption events.
#' 
#' @param name covariate name, character
#' @param table data.frame, must contain the mandatory columns 'TIME' and 'VALUE'.
#'  An 'ID' column may also be specified. In that case, ID's between 1 and the
#'  max number of subjects in the dataset/arm can be used. All ID's must have a VALUE
#'  defined for TIME 0.
#' @return a time-varying covariate
#' @importFrom dplyr across arrange filter
#' @export
TimeVaryingCovariate <- function(name, table) {
  if (!(all(c("TIME", "VALUE") %in% colnames(table)))) {
    stop("TIME and VALUE are mandatory columns")
  }
  hasID <- "ID" %in% colnames(table)
  
  # Sort dataframe
  if (hasID) {
    table <- table %>% dplyr::arrange(dplyr::across(c("ID","TIME")))
  } else {
    table <- table %>% dplyr::arrange(dplyr::across("TIME"))
  }
  tableT0 <- table %>% dplyr::filter(.data$TIME==0)
  tableAfterT0 <- table %>% dplyr::filter(.data$TIME>0)
  
  if (hasID) {
    requiredIDs <- seq_len(max(table$ID))
    missingIDs <- requiredIDs[!(requiredIDs %in% tableT0$ID)]
    if (missingIDs %>% length() > 0) {
      stop(paste0("Some ID's don't have a value for time 0: ", paste0(missingIDs, collapse=",")))
    }
    if (tableT0$ID %>% length() != requiredIDs %>% length()) {
      stop("Some ID's have several values for time 0")
    }
  } else {
    if (nrow(tableT0) == 0) {
      stop("Please provide a value for time 0")
    }
    if (nrow(tableT0) > 1) {
      stop("Only 1 value for time 0 is accepted")
    }
  }
  
  return(new("time_varying_covariate", name=trimws(name),
             distribution=toExplicitDistribution(tableT0$VALUE), table=tableAfterT0))
}

#' Merge time-varying covariates into a single data frame. This last data frame
#' will be merged afterwards with all treatment and observation rows.
#' 
#' @param covariates covariates, only time-varying covariates will be extracted
#' @param ids_within_arm ids within the current arm being sampled
#' @param arm_offset arm offset (in term of ID's)
#' @return a data.frame
#' @importFrom campsismod select
#' @importFrom dplyr bind_rows mutate
#' @importFrom purrr map_df
#' @importFrom tidyr pivot_wider
#' @keywords internal
#' 
mergeTimeVaryingCovariates <- function(covariates, ids_within_arm, arm_offset) {
  timeVaryingCovariates <- covariates %>% campsismod::select("time_varying_covariate")
  tables <- timeVaryingCovariates@list %>%
    purrr::map_df(.f=function(covariate) {
      table <- covariate@table %>% dplyr::mutate(VARIABLE=covariate@name)
      if (("ID" %in% colnames(table))) {
        tmp <- table %>%
          dplyr::filter(.data$ID %in% ids_within_arm) %>%
          dplyr::mutate(ID=.data$ID + arm_offset)
        return(tmp)
      } else {
        tmp <- ids_within_arm %>% purrr::map_df(.f=function(id) {
          return(cbind(ID=id + arm_offset, table))
        })
        return(tmp)
      }
    })
  return(dplyr::bind_rows(tables) %>% tidyr::pivot_wider(id_cols=c("ID", "TIME"),
                                                         names_from="VARIABLE", values_from="VALUE"))
}

#' Sample time-varying covariates.
#' 
#' @param object time-varying covariates, data.frame form
#' @param armID treatment arm ID
#' @param needsDV append extra column DV, logical value
#' @return a data.frame
#' @importFrom tibble add_column tibble
#' @keywords internal
#' 
sampleTimeVaryingCovariates <- function(object, armID, needsDV) {
  covNames <- colnames(object)
  covNames <- covNames[!(covNames %in% c("ID", "TIME"))]
  
  retValue <- tibble::tibble(
    ID=object$ID, ARM=as.integer(armID), TIME=object$TIME,
    EVID=as.integer(2), MDV=as.integer(1), AMT=as.numeric(NA), CMT=as.character(NA), RATE=as.numeric(0), DOSENO=as.integer(NA),
    INFUSION_TYPE=as.integer(NA), EVENT_RELATED=as.integer(0)
  )
  if (needsDV) {
    retValue <- retValue %>% tibble::add_column(DV=as.numeric(0), .before="INFUSION_TYPE")
  }
  
  retValue <- cbind(retValue, object[, covNames])
  return(retValue)
}

#_______________________________________________________________________________
#----                              sample                                   ----
#_______________________________________________________________________________

#' @rdname sample
setMethod("sample", signature = c("covariate", "integer"), definition = function(object, n) {
  object@distribution <- object@distribution %>% sample(n)
  return(object)
})
