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
default =
  function(x) {
    x = substitute(x)
    eval(x, quickcheck.env, parent.frame())}

## zipf

rzipf =
  function(n, N, s = 1) {
    if(n == 0) integer()
    else {
      bins = cumsum(c(0, 1/(1:N)^s))
      bins = bins/max(bins)
      u = runif(n)
      df =
        arrange(
          rbind(
            data.frame(sample = TRUE, data = u),
            data.frame(sample = FALSE, data = bins)),
          data)
      x = cumsum(!df$sample)[df$sample]
      x[sample.int(length(x))]}}

rzipf.range =
  function(n, min, max, s = 1) {
    if(n == 0) integer()
    else {
      stopifnot(max >= min || min < 0)
      min - 1 + rzipf(n , max - min + 1, s)}}

## quirkless sample

sample =
  function(x, size, ...)
    x[base::sample(length(x), size = size, ...)]

#perform function argument like matching for vectors
#macro-like, call only one level deep

apply.default =
  function(name, x, default) {
    if(is.null(names(default)) || is.null(x))
      x %||% default
    else {
      length(x) = length(default)
      nmask = {
        if(is.null(names(x)))
          rep(T, length(x))
        else names(x) == ""}
      names(x)[nmask]= setdiff(names(default), names(x))
      structure(
        lapply(names(default), function(n) apply.default(n, x[[n]], default[[n]])),
        names = names(default))}}

is.ffR = function(x) inherits(x, c("formula", "function", "RDG"))

arg.match =
  function(arg, defaults = NULL) {
    if(is.ffR(arg))
      arg
    else {
      name = as.character(substitute(arg))
      if(is.null(defaults))
        defaults =
          eval.parent(
            formals(sys.function(sys.parent()))[[name]])
      apply.default("", arg, defaults)}}

rdata_ =
  function(x, size, ...) UseMethod("rdata_")

rdata =
  function(x, size) {
    data = rdata_(x, size)
    if(is.null(size) || size == length(data))
      data
    else{
      if(length(data) > 0) {
        warning('recycling random numbers')
        rep_len(data, size)}
      else stop("can't recycle no data")}}

rdata_.function =
  function(x, size, ...){
    if(is.null(size))
      x()
    else
      do.call(x, list(size))}

rdata_.RDG =
  function(x, size, ...){
    if(is.null(size))
      x()
    else
      do.call(x, list(size = ~size))}

rdata_.formula =
  function(x, size)
    eval(
      tail(as.list(x), 1)[[1]],
      if(!is.null(size)) list(size = size),
      environment(x))


# accepts max or min, max or an rng function or formula (size spec)
# returns random nonnegative integer,  from bilateral zipf by default
#

rsize =
  function() {
    retval = {
      if(is.ffR(size))
        as.integer(round(rdata(size, if(is.function(size)) 1)))
      else {
        size = arg.match(size)
        rzipf.range(1, size[["min"]], size[["max"]], s = 1)}}
    stopifnot(retval >= 0)
    retval}

default.vector.size = quote(c(min = 0, max = default(vector.size %||% 10 * severity)))
formals(rsize) = list(size = default.vector.size)

## basic types

as.RDG = function(x, ...) UseMethod("as.RDG")
as.RDG.RDG = identity
as.RDG.function =
  function(x, ...)
    structure(x, class = "RDG")


as.RNG = function(x, ...) UseMethod("as.RNG")

as.RNG.list =
  function(x, class)
    switch(
      class,
      logical = function(n)  as.logical(rbinom(n, size = 1, prob = x$p)),
      integer = function(n) floor(runif(n, x$min, x$max + 1)),
      double =  function(n) rnorm(n,mean = x$mean, sd = x$sd),
      character =
        function(n){
          #generate n.unique
          n.unique = rsize(unname(x[c("unique.min", "unique.max")]))
          #generate n.unique str lenghts according to n.char
          n.char = rinteger(unname(x[c("nchar.min", "nchar.max")]), ~n.unique)
          # create the strings
          strings =
            sapply(
              split(
                sample(
                  x = x$alphabet,
                  size = sum(n.char),
                  replace = TRUE),
                rep(1:length(n.char), n.char)),
              paste,
              collapse = "")
          if(min(n.char) == 0)
            strings = c(strings, "")
          # resample n time
          sample(strings, n, replace = TRUE)
        },
      factor = Curry(sample, x = 1:x$nlevels, replace = TRUE),
      raw = Curry(sample, x = as.raw(x$min:x$max), replace = TRUE ),
      Date =
        Curry(sample, x = as.Date(x$from:x$to, origin = as.Date("1970-01-01")), replace = TRUE)
    )

is.RDG = function(x) class(x) == "RDG"

vector.defaults =
  function(elements)
    list(elements = elements, size = default.vector.size)

make.RDG =
  function(class){
    force(class)
    RDG.defaults =
      list(
        logical = vector.defaults(quote(c(p = 0.5))),
        integer =
          vector.defaults(
            quote({
              r = default(integer.size %||% 10 * severity);
              c(min = -r, max = r)})),
        double =
          vector.defaults(
            quote(c(mean = 0, sd = default(double.size %||% 10 * severity)))),
        character =
          vector.defaults(
            quote(
              list(
                alphabet = c(letters, LETTERS, 0:9),
                nchar.min = 0,
                nchar.max = default(nchar.max %||% severity),
                unique.min = 1,
                unique.max = default(unique.max %||% severity)))),
        factor =
          vector.defaults(quote(c(nlevels = default(nlevels %||% severity)))),
        raw =
          vector.defaults(quote(c(min = 0, max = default(raw.max %||% severity)))),
        Date =
          vector.defaults(quote(c(from = as.Date("1950/01/01"), to = as.Date("2050/01/01")))))
    as.RDG({
      f =
        function() {
          if(!is.ffR(elements))
            elements = as.RNG(arg.match(elements), class)
          size = rsize(arg.match(size))
          data = rdata(elements, size)
          if(class == "factor")
            as.factor(data)
          else
            as(data, class)}
      formals(f) =
        list(
          elements = RDG.defaults[[class]]$elements,
          size = RDG.defaults[[class]]$size)
      f})}

for(class in c("logical", "integer", "double", "character", "factor", "raw", "Date"))
  assign(paste0("r", class), make.RDG(class))

rnumeric =
    function()
      mixture(
        list(
          Curry(
            rdouble,
            elements = unname(elements[c("double.mean", "double.sd")]),
            size = size),
          Curry(
            rinteger,
            elements = unname(elements[c("integer.min", "integer.max")]),
            size = size)))()

formals(rnumeric) =
  list(
    elements  =
      quote({
        r = default(integer.size %||% 10 * severity);
        c(integer.min = -r, integer.max = r,
          double.mean = 0, double.sd = default(double.size %||% 10 * severity))}),
    size = default.vector.size)

rnumeric = as.RDG(rnumeric)

##rcomplex NAY

rlist =
  as.RDG(
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
              Curry(rlist, size = size, height = height - 1))),
      size = c(min = 0, max = default(list.size %||% severity)),
      height = default(list.height %||% round(severity/2))) {
      if (height == 0) NULL
      else
        replicate(
          rsize(arg.match(size)),
          generator(),
          simplify = FALSE)})

ratomic =
    function(){
      size = arg.match(size)
      mixture(
        lapply(
          generators,
          function(gg){
            hh = gg
            Curry(hh, size = size)}))()}

atomic.generators =
  list(
    rlogical = rlogical,
    rinteger = rinteger,
    rdouble = rdouble,
    rcharacter = rcharacter,
    rraw = rraw,
    rDate = rDate,
    rfactor = rfactor)

formals(ratomic) =
  list(
    generators = quote(atomic.generators),
    size = default.vector.size)

ratomic = as.RDG(ratomic)

rmatrix =
  as.RDG(
    function(
      elements = ratomic,
      nrow = c(min = 0, max = default(matrix.nrow %||% 4 * severity)),
      ncol = c(min = 0, max = default(matrix.ncol %||% severity))) {
      nrow = rsize(arg.match(nrow))
      ncol = rsize(arg.match(ncol))
      matrix(rdata(elements, size = nrow*ncol), nrow = nrow, ncol = ncol)})

rdata.frame =
  as.RDG(
    function(
      elements = ratomic,
      nrow = c(min = 0, max = default(data.frame.nrow %||% 4 * severity)),
      ncol = c(min = 0, max = default(data.frame.ncol %||% severity))) {
      nrow = rsize(arg.match(nrow))
      ncol = rsize(arg.match(ncol))
      columns = replicate(ncol, rdata(elements, size = nrow), simplify = FALSE)
      if(length(columns) > 0)
        names(columns) = paste("col", 1:ncol)
      do.call(data.frame, columns)})

rfunction =
  as.RDG(
    function()
      sample(
        do.call(
          c,
          lapply(
            unlist(sapply(search(), ls)),
            function(x) {
              x = get(x)
              if (is.function(x)) list(x) else list()})),
        1)[[1]])

## special distributions

constant =
  function(const = NULL) {
    force(const)
    as.RDG(
      function(...)
        const)	}

rsample =
  as.RDG(
    function(elements, size = c(min = 0, max = ceiling(length(elements)/2)), replace = TRUE) {
      sample(elements, rsize(arg.match(size)), replace = replace)})

##combiners
mixture =
  function(generators, weights = 1) {
    force(generators)
    as.RDG(
      function(...)
        sample(generators, 1, prob = rep_len(weights, length(generators)))[[1]](...))}

# combine everything
all.generators =
  c(atomic.generators,
    list(rlist = rlist, rdata.frame = rdata.frame, rmatrix = rmatrix))

rany =
  as.RDG(
    function(generators = all.generators)
      mixture(generators)())

#names
rnamed =
  as.RDG(
    function(
      x,
      names = rcharacter(size = ~length(x)))
      structure(x, names = names))

named =
  function(
    generator,
    rnames = rnamed)
    as.RDG(
      function() {
        rnames(rdata(generator, NULL))})

