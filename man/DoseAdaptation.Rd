% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dose_adaptation.R
\name{DoseAdaptation}
\alias{DoseAdaptation}
\title{Create a dose adaptation.}
\usage{
DoseAdaptation(formula, compartments = NULL)
}
\arguments{
\item{formula}{formula to apply, single character string, e.g. "AMT*WT"}

\item{compartments}{compartment indexes or names where the formula needs to be applied,
integer or character vector. Default is NULL (formula applied on all compartments)}
}
\value{
a fixed covariate
}
\description{
Create a dose adaptation.
}
