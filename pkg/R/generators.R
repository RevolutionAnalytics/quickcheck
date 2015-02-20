# Copyright 2015 Revolution Analytics
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


#generators common

#evals a function with a list of args or a formula in an expanded env
eval.formula.or.function=
  function(fof, args = list()) {
    if(is.function(fof))
      do.call(fof, args)
    else
      eval(tail(as.list(fof), 1)[[1]], args, environment(fof))}

#takes a rng in the R sense (rnorm, rpois etc) and extracts size data
# accepts also formula
# rng function needs a single argument, rng formula contains only size free var
eval.rng =
  function(rng, size) {
    data =
      eval.formula.or.function(
        rng,
        if(is.function(rng))
          list(size)
        else
          list(size = size))
    if(size != length(data)) {
      warning('recycling random numbers')
      rep_len(data, size)}
    else
      data}

# accepts max or min, max or an rng function or formula (size spec)
# returns random nonnegative integer,  from bilateral zipf by default

rsize =
  function(rng) {
    if(is.numeric(rng)){
      stopifnot(length(rng) <= 2)
      if(length(rng) == 1)
        rng = c(min = 0, max = rng)
      rzipf.range(1, rng[["min"]], rng[["max"]], s = 1)}
    else
      as.integer(round(eval.rng(rng, 1)))}

# takes rng function or formula and size spec
# returns random data
rdata =
  function(rng, size)
    eval.rng(rng, rsize(size))

default.vector.size =
  function()
    default(vector.size %||% 10 * severity)

## basic types

rlogical =
  function(
    elements = c(p = 0.5),
    size = default.vector.size()) {
    if(is.numeric(elements)) {
      p = elements
      elements =
        function(n)
          as.logical(rbinom(n, size = 1, prob = p))}
    as.logical(rdata(elements, size))}


rinteger =
  function(
    elements = c(max = default(integer.size %||% 10 * severity)),
    size = default.vector.size()) {
    if(is.numeric(elements)) {
      lelements = length(elements)
      if(lelements == 0 || lelements > 2)
        stop("elements argument can only have length 1 or 2 when numeric")
      if(lelements == 1) elements = c(min = -elements[[1]], max = elements[[1]])
      elements =
        Curry(rzipf.range, min = elements[["min"]], max = elements[["max"]])}
    as.integer(rdata(elements, size))}

rdouble =
  function(
    elements = c(mean = 0, sd = default(double.size %||% 10 * severity)),
    size = default.vector.size()) {
    if(is.numeric(elements)) {
      stopifnot(length(elements) <=2)
      if(length(elements) == 1)
        elements = c(mean = 0, sd = elements)
      elements = Curry(rnorm, mean = elements[["mean"]], sd = elements[["sd"]])}
    as.double(rdata(elements, size))}

rnumeric =
  function(
    generators =
      list(
        integer = c(max = default(integer.size %||% 10 * severity)),
        double = 	c(mean = 0, sd = default(double.size %||% 10 * severity))),
    size = default.vector.size())
    mixture(
      list(
        Curry(rdouble, generator = generators$double, size = size),
        Curry(rinteger, generator = generators$integer, size = size)))()

##rcomplex NAY

rcharacter =
  function(
    elements =
      c(
        nchar = default(nchar.size %||% severity),
        string = default(character.max %||% severity)),
    size = default.vector.size()) {
    nchar = elements[["nchar"]]
    string = elements[["string"]]
    if(is.numeric(nchar))
      nchar = Curry(rpois, lambda = nchar)
    if(is.numeric(string))
      string = Curry(rzipf, N = string)
    size = rsize(size)
    substr(
      sapply(
        rdata(string, constant(size)), digest),
      1,
      rdata(nchar, constant(size)))}

rfactor =
  function(
    elements = c(nlevels = default(nlevels %||% severity)),
    size = default.vector.size()) {
    if(is.numeric(elements))
      elements = Curry(sample, x = 1:elements, replace = TRUE)
    as.factor(rdata(elements, size))}

rraw =
  function(
    elements = default(raw.max %||% severity),
    size = default.vector.size()) {
    if(is.numeric(elements))
      elements = as.raw(0:elements)
    if(is.raw(elements))
      elements = Curry(sample, x = elements, replace = TRUE )
    as.raw(rdata(elements, size))}

rlist =
  function(
    generator =
      Curry(
        rany,
        generators =
          list(
            rlogical,
            rinteger,
            rdouble,
            rcharacter,
            rraw,
            rDate,
            rfactor,
            Curry(rlist, size = size, height = rsize(height - 1)))),
    size = default(list.size %||% round(severity / 2)),
    height = default(list.height %||% round(severity/3))) {
    if (height == 0) NULL
    else
      replicate(
        rsize(size),
        generator(),
        simplify = FALSE)}

ratomic =
  function(
    generators = atomic.generators,
    size = default.vector.size())
    mixture(
      lapply(
        generators,
        function(gg){
          hh = gg
          Curry(hh, size = size)}))()

rmatrix =
  function(
    generator = ratomic,
    nrow = default(matrix.nrow %||% 4 * severity),
    ncol = default(matrix.ncol %||% severity)) {
    nrow = rsize(nrow)
    ncol = rsize(ncol)
    matrix(generator(size = constant(nrow*ncol)), nrow = nrow, ncol = ncol)}

rDate =
  function(
    elements = c(from = as.Date("1950/01/01"), to = as.Date("2050/01/01")),
    size = default.vector.size()) {
    if(is.character(elements))
      elements = as.Date(elements)
    if(class(elements) == "Date") {
      dates = as.Date(elements[["from"]]:elements[["to"]], origin = as.Date("1970-01-01"))
      elements = Curry(sample, x = dates, replace = TRUE)}
    as.Date(rdata(elements, size), origin = as.Date("1970-01-01"))}

atomic.generators =
  list(
    rlogical = rlogical,
    rinteger = rinteger,
    rdouble = rdouble,
    rcharacter = rcharacter,
    rraw = rraw,
    rDate = rDate,
    rfactor = rfactor)

rdata.frame =
  function(
    generator = ratomic,
    nrow = default(data.frame.nrow %||% 4 * severity),
    ncol = default(data.frame.ncol %||% severity)) {
    nrow = rsize(nrow)
    ncol = rsize(ncol)
    columns = replicate(ncol, generator(size = constant(nrow)), simplify = FALSE)
    if(length(columns) > 0)
      names(columns) = paste("col", 1:ncol)
    do.call(data.frame, columns)}

rfunction =
  function()
    sample(
      do.call(
        c,
        lapply(
          unlist(sapply(search(), ls)),
          function(x) {
            x = get(x)
            if (is.function(x)) list(x) else list()})),
      1)[[1]]

## special distributions

constant =
  function(const = NULL) {
    force(const)
    function(...)
      const	}

rsample =
  function(from, size = length(from), replace = TRUE) {
    sample(from, rsize(size), replace = replace)}

##combiners
mixture =
  function(generators) {
    force(generators)
    function(...)
      sample(generators, 1)[[1]](...)}

# combine everything
all.generators = c(atomic.generators, list(rlist, rdata.frame, rmatrix))

rany =
  function(generators = all.generators)
    mixture(generators)()
