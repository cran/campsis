% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bootstrap.R
\name{Bootstrap}
\alias{Bootstrap}
\title{Create a bootstrap object.}
\usage{
Bootstrap(
  data,
  id = "BS_ID",
  replacement = FALSE,
  random = FALSE,
  export_id = FALSE
)
}
\arguments{
\item{data}{data frame to be bootstrapped. It must have a unique identifier column
named according to the specified argument 'id' (default value is 'BS_ID').
Other columns are covariates to bootstrap. They must all be numeric.
Whatever the configuration of the bootstrap, these covariates are always read
row by row and belong to a same individual.}

\item{id}{unique identifier column name in data}

\item{replacement}{values can be reused or not when drawn, logical}

\item{random}{values are drawn randomly, logical}

\item{export_id}{tell CAMPSIS if the identifier 'BS_ID' must be output or not, logical}
}
\value{
a bootstrap object
}
\description{
Create a bootstrap object.
}
