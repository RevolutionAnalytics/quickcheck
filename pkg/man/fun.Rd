\name{fun}
\alias{fun}
\title{Helper function to define generators}
\description{\code{fun} is equivalent to \code{Curry} but adds a little syntactic sugar. \code{fun(f(arg1 = val1, arg2 = val2, ...))} is the same as \code{Curry(fun, arg1 = val1, arg2 = val2, ...)}} 
\usage{
fun(a.call)}
\arguments{
\item{a.call}{An R call}
}
\value{For \code{fun} a function with a smaller number of arguments than its first argument}