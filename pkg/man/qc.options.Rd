\name{qc.options}
\alias{qc.options}
\alias{qc.option}
\alias{default}
\alias{\%||\%}
\title{Set and get package options}
\description{\code{qc.options} and \code{qc.option} set and gets packag options, which allow to fine tune testing, particularly the number of runs or the parameters of most data generators. \code{default} is just a shorthand to write expression involving multiple package options and operator \code{\%||\%} a convenient way to combine multiple defaults.}
\usage{
  qc.options(..., character.max = NULL, data.frame.ncol = NULL,
                 data.frame.nrow = NULL, double.size = NULL,
                 integer.size = NULL, list.height = NULL, list.size =
                 NULL, matrix.ncol = NULL, matrix.nrow = NULL,
                 nchar.size = NULL, nlevels = NULL, raw.max = NULL,
                 sample.size = NULL, severity = 10, vector.size = NULL)
  qc.option(..., character.max = NULL, data.frame.ncol = NULL,
                 data.frame.nrow = NULL, double.size = NULL,
                 integer.size = NULL, list.height = NULL, list.size =
                 NULL, matrix.ncol = NULL, matrix.nrow = NULL,
                 nchar.size = NULL, nlevels = NULL, raw.max = NULL,
                 sample.size = NULL, severity = 10, vector.size = NULL)
  default(x)
  x \%||\% y
}
\arguments{
  \item{severity}{A parameter that is proportional to other parameters that make the tests more severe (harder to pass), including number of runs, size of data generated as arguments to assertions and size of elements in said data. Defaults to 10.}
  \item{sample.size}{The default value for the \code{sample.size} argument to \code{test}. Overrides the "severity" option, unless set to NULL, the default}
  \item{vector.size}{Default vector size for a variety of generators}
  \item{integer.size}{Max element size in \code{\link{rinteger}}}
  \item{double.size}{Standard deviation of elements in \code{\link{rdouble}}}
  \item{nchar.size}{Max string length in \code{\link{rcharacter}}}
  \item{character.max}{Max number of distinct strings in \code{\link{rcharacter}}}
  \item{nlevels}{Max number of levels in \code{\link{rfactor}}}
  \item{raw.max}{Max number of distinct elements in \code{\link{rraw}}}
  \item{list.size}{Max list size for \code{\link{rlist}}}
  \item{list.height}{Parameter increasing with list height in \code{\link{rlist}}}
  \item{matrix.ncol}{Max number of columns in \code{\link{rmatrix}}}
  \item{matrix.nrow}{Max number of rows in\code{\link{rmatrix}}}
  \item{data.frame.ncol}{Max number of columns in\code{\link{rdata.frame}}}
  \item{data.frame.nrow}{Max number of rows in\code{\link{rdata.frame}}}
  \item{...}{Name of option to get}
  \item{x,y}{Any R object}
}
\details{For each named argument, the equally named option is set to the specified value. For each unnamed argument, the current value of the option specified in the argument is returned. Multiple options can be set and gotten in one call to \code{qc.options}, but \code{qc.option} only accepts one argument. \code{default} only reads options and accepts an expression where options can be used as variable. It is just a way to write more readable expressions where \code{qc.option} would have had to be called multiple times. Operator \code{\%||\%} returns the value of its left argument unless it is \code{NULL}, in which case it is set to the right argument (even if \code{NULL} itself). Usueful to chain multiple default setting in order of priority.
}

\value{A list of the current values for all the arguments for \code{qc.options}, only one such value for \code{qc.option}, which in principle could be any R object but as of the current version is always numeric}

\examples{
  qc.options(severity = 20, "raw.max")
  qc.option(severity = 20)
  default(vector.size \%||\% 10 * severity)
}
