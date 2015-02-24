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

#workaround for R bug
as.list.Date =
  function(x, ...) {
    dd = base::as.list.Date(x)
    names(dd) = names(x)
    dd}

#perform function argument like matching for vectors
#macro-like, call only one level deep

arg.match =
  function(arg) {
    if(is.function(arg) || is.formula(arg))
      arg
    else {
      name = as.character(substitute(arg))
      defaults =
        as.list(
          eval.parent(
            formals(sys.function(sys.parent()))[[name]]))
      default.names = names(defaults)
      default.length = length(defaults)
      ff = function() mget(names(formals()), sys.frame(sys.nframe()))
      formals(ff) = do.call(pairlist, defaults)
      defaults = do.call(ff, as.list(arg))
      if(length(defaults) > default.length)
        stop("Argument can have elements ", default.names, " only")
      defaults}}

#takes a rng in the R sense (rnorm, rpois etc) and extracts size data
# accepts also formula
# rng function needs a single argument, rng formula contains only size free var
eval.rng =
  function(rng, size) {
    data = {
      if(is.function(rng))
        do.call(rng, list(size))
      else
        eval(tail(as.list(rng), 1)[[1]], list(size = size), environment(rng))}
    if(size != length(data)) {
      warning('recycling random numbers')
      rep_len(data, size)}
    else
      data}

# accepts max or min, max or an rng function or formula (size spec)
# returns random nonnegative integer,  from bilateral zipf by default
#

rsize =
  function(size) {
    if(is.formula(size) || is.function(size))
      as.integer(round(eval.rng(size, 1)))
    else
      rzipf.range(1, size$min, size$max, s = 1)}

# takes rng function or formula and size spec
# returns random data

rdata =
  function(rng, size)
    eval.rng(rng, size)

## basic types

rlogical =
  function(
    elements = c(p = 0.5),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(is.numeric(elements)) {
      p = arg.match(elements)$p
      elements =
        function(n)
          as.logical(rbinom(n, size = 1, prob = p))}
    size = rsize(arg.match(size))
    as.logical(rdata(elements, size))}

rinteger =
  function(
    elements = c(min = 0, max = default(integer.size %||% 10 * severity)),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(is.numeric(elements))
      elements = do.call(Curry, c(list(rzipf.range), arg.match(elements)))
    size = rsize(arg.match(size))
    as.integer(rdata(elements, size))}

rdouble =
  function(
    elements = c(mean = 0, sd = default(double.size %||% 10 * severity)),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(is.numeric(elements))
      elements = do.call(Curry, c(list(rnorm), arg.match(elements)))
    size = rsize(arg.match(size))
    as.double(rdata(elements, size))}

rnumeric =
  function(
    generators =
      list(
        integer = c(max = default(integer.size %||% 10 * severity)),
        double = 	c(mean = 0, sd = default(double.size %||% 10 * severity))),
    size = c(min = 0, max = default(vector.size %||% 10 * severity)))
    mixture(
      list(
        Curry(rdouble, generator = generators$double, size = size),
        Curry(rinteger, generator = generators$integer, size = size)))()

##rcomplex NAY

rcharacter =
  function(
    elements =
      list(
        nchar = default(nchar.size %||% severity),
        string = default(character.max %||% severity)),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    elements = arg.match(elements)
    nchar = elements[["nchar"]]
    string = elements[["string"]]
    if(is.numeric(nchar))
      nchar = Curry(rpois, lambda = nchar)
    if(is.numeric(string))
      string = Curry(rzipf, N = string)
    size = rsize(arg.match(size))
    substr(
      sapply(
        rdata(string, size), digest),
      1,
      rdata(nchar, size))}

rfactor =
  function(
    elements = c(nlevels = default(nlevels %||% severity)),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(is.numeric(elements))
      elements = Curry(sample, x = 1:arg.match(elements)$nlevels, replace = TRUE)
    size = rsize(arg.match(size))
    as.factor(rdata(elements, size))}

rraw =
  function(
    elements = c(min = 0, max = default(raw.max %||% severity)),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(is.numeric(elements)) {
      elements = arg.match(elements)
      elements = as.raw(elements$min:elements$max)}
    if(is.raw(elements))
      elements = Curry(sample, x = elements, replace = TRUE )
    size = rsize(arg.match(size))
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
            Curry(rlist, size = size, height = max(0, height - 1)))),
    size = c(min = 0, max = default(list.size %||% round(severity / 2))),
    height = default(list.height %||% round(severity/3))) {
    if (height == 0) NULL
    else
      replicate(
        rsize(arg.match(size)),
        generator(),
        simplify = FALSE)}

ratomic =
  function(
    generators = atomic.generators,
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(is.numeric(size))
      size = arg.match(size)
    mixture(
      lapply(
        generators,
        function(gg){
          hh = gg
          Curry(hh, size = size)}))()}

rmatrix =
  function(
    generator = ratomic,
    nrow = c(min = 0, max = default(matrix.nrow %||% 4 * severity)),
    ncol = c(min = 0, max = default(matrix.ncol %||% severity))) {
    nrow = rsize(arg.match(nrow))
    ncol = rsize(arg.match(ncol))
    matrix(generator(size = constant(nrow*ncol)), nrow = nrow, ncol = ncol)}

rDate =
  function(
    elements = c(from = as.Date("1950/01/01"), to = as.Date("2050/01/01")),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(is.character(elements))
      elements = as.Date(elements)
    if(class(elements) == "Date") {
      elements = arg.match(elements)
      dates = as.Date(elements[["from"]]:elements[["to"]], origin = as.Date("1970-01-01"))
      elements = Curry(sample, x = dates, replace = TRUE)}
    size = rsize(arg.match(size))
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
    nrow = c(min = 0, max = default(data.frame.nrow %||% 4 * severity)),
    ncol = c(min = 0, max = default(data.frame.ncol %||% severity))) {
    nrow = rsize(arg.match(nrow))
    ncol = rsize(arg.match(ncol))
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
  function(elements, size = c(min = 0, max = round(length(elements)/2)), replace = TRUE) {
    sample(elements, rsize(arg.match(size)), replace = replace)}

##combiners

mixture =
  function(generators) {
    force(generators)
    function(...)
      sample(generators, 1)[[1]](...)}

# combine everything
all.generators =
  c(atomic.generators,
    list(rlist = rlist, rdata.frame = rdata.frame, rmatrix = rmatrix))

rany =
  function(generators = all.generators)
    mixture(generators)()
