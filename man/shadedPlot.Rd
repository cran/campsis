% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/default_plot.R
\name{shadedPlot}
\alias{shadedPlot}
\title{Shaded plot (or prediction interval plot).}
\usage{
shadedPlot(
  x,
  output,
  colour = NULL,
  strat_extra = NULL,
  level = 0.9,
  alpha = 0.25
)
}
\arguments{
\item{x}{data frame}

\item{output}{variable to show}

\item{colour}{variable(s) to colour}

\item{strat_extra}{variable(s) to stratify, but not to colour (useful for use with facet_wrap)}

\item{level}{PI level, default is 0.9 (90\% PI)}

\item{alpha}{alpha parameter (transparency) given to geom_ribbon}
}
\value{
a ggplot object
}
\description{
Shaded plot (or prediction interval plot).
}
