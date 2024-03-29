% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/solver_settings.R
\name{Solver}
\alias{Solver}
\title{Create solver settings.}
\usage{
Solver(
  atol = 1e-08,
  rtol = 1e-08,
  hmax = NA,
  maxsteps = 70000L,
  method = "liblsoda"
)
}
\arguments{
\item{atol}{absolute solver tolerance, default is 1e-08}

\item{rtol}{relative solver tolerance, default is 1e-08}

\item{hmax}{limit how big a solver step can be, default is NA}

\item{maxsteps}{max steps between 2 integration times (e.g. when observations records are far apart), default is 70000}

\item{method}{solver method, for RxODE/rxode2 only: 'liblsoda' (default), 'lsoda', 'dop853', 'indLin'. Mrgsolve's method is always 'lsoda'.}
}
\value{
solver settings
}
\description{
Create solver settings.
}
