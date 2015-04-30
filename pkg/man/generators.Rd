\name{generators}
\alias{rany}
\alias{rcharacter}
\alias{rfactor}
\alias{constant}
\alias{rdata.frame}
\alias{rmatrix}
\alias{ratomic}
\alias{rdouble}
\alias{rinteger}
\alias{rnumeric}
\alias{rlist}
\alias{rlogical}
\alias{mixture}
\alias{rraw}
\alias{rsize}
\alias{rDate}
\alias{rsample}
\alias{named}
\alias{rnamed}
\title{
Generators and generator constructors for random data of many types
}
\description{
These functions are divided into two groups, random data generators, and constructors for such functions. Random data generators, prefixed with "r",  are functions with no mandatory arguments that generate random data of the type indicated in their names. Their use is typically as default values for the arguments of the \code{assertion} function, which itself is the main argument to \code{test}. That is, these data generators are called for each test run and fed into the assertion. All arguments are given a default but can also be modified, thus defining customized data generators. In cases when no reasonable defaults could be defined, instead of a random data generator, a constructor is available that returns a random data generator.
}
\usage{
rany(generators = all.generators)
ratomic(
  generators = atomic.generators,
  size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
rcharacter(
  elements =
    list(
      alphabet = c(letters, LETTERS, 0:9),
      nchar.min = 0, nchar.max = default(nchar.max \%||\% severity),
      unique.min = 1, unique.max = default(unique.max \%||\% severity)),
  size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
rdata.frame(
  generator = ratomic,
  nrow = c(min = 0, max = default(data.frame.nrow \%||\% 4 * severity)),
  ncol = c(min = 0, max = default(data.frame.ncol \%||\% severity)))
rDate(
  elements = c(from = as.Date("1950/01/01"), to = as.Date("2050/01/01")),
  size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
rdouble(
  elements = c(mean = 0, sd = default(double.size \%||\% 10 * severity)),
  size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
rfactor(
  elements = c(nlevels = default(nlevels \%||\% severity)),
  size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
rinteger(
  elements = {
    r = default(integer.size \%||\% 10 * severity)
    c(min = -r, max = r)},
  size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
rlist(
  generator =
    Curry(
      rany, generators = list(rlogical, rinteger, rdouble, rcharacter, rraw, rDate, rfactor,
      Curry(rlist, size = size, height = height - 1))),
  size = c(min = 0, max = default(list.size \%||\% severity)),
  height = default(list.height \%||\% round(severity/2)))
rlogical(
  elements = c(p = 0.5),
  size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
rmatrix(
  generator = ratomic,
  nrow = c(min = 0, max = default(matrix.nrow \%||\% 4 * severity)),
  ncol = c(min = 0, max = default(matrix.ncol \%||\% severity)))
rnumeric(
  elements = { r = default(integer.size \%||\% 10 * severity)
              c(integer.min = -r, integer.max = r,
                 double.mean = 0, double.sd = default(double.size \%||\% 10 * severity))},
 size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
rraw(
  elements = c(min = 0, max = default(raw.max \%||\% severity)),
  size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
rsample(
  elements,
  size = c(min = 0, max = ceiling(length(elements)/2)),
  replace = TRUE)
rsize(size = c(min = 0, max = default(vector.size \%||\% 10 * severity)))
mixture(generators)
constant(const = NULL)
named(generator, rnames = rnamed)
rnamed( x, names = rcharacter(size = ~length(x)))}
\arguments{
 \item{elements}{Specify the distribution of elements of the returned data structure, either as a vector of distribution parameters or as a random number generator function or a formula that will be used as a random number generator. Different generators accept different parameters. Using names in the vectors is optional when no ambiguity arises.
 \describe{
  \item{rcharacter}{\code{alphabet}, the alphabet the generated strings are built on; \code{nchar.min}, \code{nchar.max},  the range of lengths of each string; and \code{unique.min}, \code{unique.max}, the range of distinct strings generated. Each can also be a random number generator function or formula, see below}
  \item{rDate}{\code{from}, \code{to}, the earliest and latest possible dates, as class Date objects or strings amenable to conversion}
  \item{rdouble}{\code{mean} and \code{sd} are the mean and standard deviation}
 \item{rfactor}{\code{nlevels} is the maximum number of levels}
 \item{rinteger}{\code{min} and \code{max} values; when \code{min} is omitted, \code{-max} is assumed, that is a symmetric distribution centered at 0}
 \item{rnumeric}{a combination of parameters for \code{rinteger} and \code{rdouble}, renamed to avoid any confusion as to which part of the mixture they affect}
 \item{rlogical}{\code{p} is the probability of \code{TRUE}}
 \item{rraw}{\code{max} is the maximum value for an element, as an integer. Alternately, one can specify a raw vector whose elements will be sampled}
 \item{rsample}{A vector or list of elements to sample from.}
 \item{rsize}{\code{min} and \code{max} values; when \code{min} is omitted,  0 is assumed}
 }
 A random number generator can be also passed, such as \code{rnorm} or \code{runif}.  Also, this argument accepts formulas that contain the \code{size} variable and whose right side evaluates to exactly \code{size} elements, as is \code{~10*runif(size)}. If the formula or function evaluates to the wrong class, a conversion will be attempted; if it evaluate to the wrong size, a warning will be issued and recycling will be attempted.}
 \item{size}{The maximum size of the returned data structure. Alternatively, a random number generator taking a single argument and returning exactly one integer or a formula whose right side evaluates to the same (see also the \code{elements} argument)}
 \item{nrow}{The maximum number of rows for the returned data frame. Alternatively, a function or a formula (see \code{size})}
 \item{ncol}{The maximum number of columns for the returned data frame. Alternatively, a function specifying its distribution (see \code{size})}
 \item{height}{A parameter monotonically increasing with the average height (amount of nesting) of the returned list, for a fixed \code{size} argument. We plan to make the interpretation of this parameter more direct in a future release.}
 \item{replace}{Whether to sample with replacement}
 \item{generator}{A random data generator or a formula that evaluates to random data (only right side is used)}
 \item{generators}{List of random data generators}
 \item{const}{Any R object}
 \item{x}{An R object for which it is possible to assign names}
 \item{names}{Random names to assign to the first argument}
 \item{rnames}{Function that that takes a vector as argument and returnes a randomly named version thereof}
}
\details{
The defaults for the \code{elements} and \code{size} refer to variables that are defined only as package options, such as \code{nchar.size} and \code{severity}. See \code{\link{qc.options}}.
}
\value{
\code{rcharacter}, \code{rfactor}, \code{rdata.frame}, \code{rDate}, \code{rdouble}, \code{rinteger}, \code{rnumeric}, \code{rraw}, \code{rlogical} and \code{rlist} follow a naming convention with an "r" prefix followed by a class name and generate random data of the type specified by the name. \code{rsize} generates a positive integer between min and max and is meant to be used to pick a random size for data structures. \code{rany} generates an R object of any type. In practice, it's a mixture of the available generators, but may be enriched with more generators in the future. \code{constant} is a constructor for a degenerate random data generator that always returns the same object. It's useful for testing, say, corner cases that a developer needs to make sure they are going to be hit, not just with a certain probability. It's a bridge to deterministic testing. \code{rsample} returns a generator that picks among a list of possible values. \code{mixture} creates a random generator that follows a mixture distribution of the generators provided as arguments (equally weighted). \code{rnamed} applied to a vector returns a named vector with random names. \code{named} creates a generator from its argument that shares the same properties but returns named vectors.
}

\examples{
#generate random integer vectors of size 4 or more
rinteger(size = 4)
#generate random integer vectors at least 4 long and with elements greater than 5.
rinteger(element = 5, size = 4)
#pick from a given vector (not unlike sample)
rsample(1:5, c(max = 3))
#generate random numeric vector
mixture(list(rinteger, rdouble))()
#always return 1
constant(1)()
# generate random integer vector of size exactly 4
rinteger(size = constant(4))
#same with formulas
rinteger(size = ~4)}

