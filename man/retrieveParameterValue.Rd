% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/distribution.R
\name{retrieveParameterValue}
\alias{retrieveParameterValue}
\title{Retrieve the parameter value (standardized) for the specified parameter name.}
\usage{
retrieveParameterValue(model, paramName, default = NULL, mandatory = FALSE)
}
\arguments{
\item{model}{model}

\item{paramName}{parameter name}

\item{default}{default value if not found}

\item{mandatory}{must be in model or not}
}
\value{
the standardized parameter value or the given default value if not found
}
\description{
Retrieve the parameter value (standardized) for the specified parameter name.
}
