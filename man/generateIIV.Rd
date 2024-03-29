% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dataset.R
\name{generateIIV}
\alias{generateIIV}
\title{Generate IIV matrix for the given Campsis model.}
\usage{
generateIIV(model, n, offset = 0)
}
\arguments{
\item{model}{Campsis model}

\item{n}{number of subjects}

\item{offset}{if specified, resulting ID will be ID + offset}
}
\value{
IIV data frame with ID column
}
\description{
Generate IIV matrix for the given Campsis model.
}
