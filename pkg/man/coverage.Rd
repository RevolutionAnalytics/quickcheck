\name{coverage}
\alias{coverage}
\title{Visualize test coverage}
\description{
 Produces a report about the coverage attained by all the tests in a package}
\usage{coverage(x = "pkg/", ...)}
\arguments{
  \item{x}{Path to package to analyze}
  \item{...}{Arguments for specific methods, unused at this time}
}
\details{The report will open in a new browser window or in the Rstudio Viewer and is a Shiny app. You may need to stop it to get the prompt again in RStudio}
\value{\code{NULL}.}

\examples{
#coverage(".")
}
