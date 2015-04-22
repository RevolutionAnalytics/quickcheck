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


#workaround for R bug
fix.as.list =
  function(as.fun) {
    force(as.fun)
    function(x, ...) {
      dd = as.fun(x)
      names(dd) = names(x)
      dd}}

as.list.Date = fix.as.list(base::as.list.Date)
as.list.factor = fix.as.list(base::as.list.factor)

is.fofun =
  function(x)
    is.function(x) || is.formula(x)

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
      ll = lapply(names(default), function(n) apply.default(n, x[[n]], default[[n]]))
      names(ll) = names(default)
      ll}}

arg.match =
  function(arg, defaults = NULL) {
    if(is.fofun(arg))
      arg
    else {
      name = as.character(substitute(arg))
      if(is.null(defaults))
        defaults =
            eval.parent(
              formals(sys.function(sys.parent()))[[name]])
      apply.default("", arg, defaults)}}

#takes a rng in the R sense (rnorm, rpois etc) and extracts size data
# accepts also formula
# rng function needs a single argument, rng formula contains only size free var
rdata =
  function(rng, size) {
    data = {
      if(is.function(rng)){
        if(is.null(size))
          rng()
        else
          do.call(rng, list(size))}
      else
        eval(tail(as.list(rng), 1)[[1]], list(size = size), environment(rng))}
    if(is.null(size) || size == length(data))
      data
    else{
      if(length(data) > 0) {
        warning('recycling random numbers')
        rep_len(data, size)}
      else stop("can't recycle no data")}}

# accepts max or min, max or an rng function or formula (size spec)
# returns random nonnegative integer,  from bilateral zipf by default
#

rsize =
  function(size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    retval = {
      if(is.fofun(size))
        as.integer(round(rdata(size, 1)))
      else {
        size = arg.match(size)
        rzipf.range(1, size$min, size$max, s = 1)}}
    stopifnot(retval >= 0)
    retval}

## basic types

rlogical =
  function(
    elements = c(p = 0.5),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(!is.fofun(elements)) {
      p = arg.match(elements)$p
      elements =
        function(n)
          as.logical(rbinom(n, size = 1, prob = p))}
    size = rsize(arg.match(size))
    as.logical(rdata(elements, size))}

rinteger =
  function(
    elements = {
      r = default(integer.size %||% 10 * severity);
      c(min = -r, max = r)},
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(!is.fofun(elements)){
      args = arg.match(elements)
      elements = function(n) floor(runif(n, args$min, args$max + 1))}
    size = rsize(arg.match(size))
    as.integer(rdata(elements, size))}

rdouble =
  function(
    elements = c(mean = 0, sd = default(double.size %||% 10 * severity)),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(!is.fofun(elements))
      elements = do.call(Curry, c(list(rnorm), arg.match(elements)))
    size = rsize(arg.match(size))
    as.double(rdata(elements, size))}

rnumeric =
  function(
    elements  =
      list(
        integer = c(max = default(integer.size %||% 10 * severity)),
        double = 	c(mean = 0, sd = default(double.size %||% 10 * severity))),
    size = c(min = 0, max = default(vector.size %||% 10 * severity)))
    mixture(
      list(
        Curry(rdouble, elements = elements$double, size = size),
        Curry(rinteger, elements = elements$integer, size = size)))()

##rcomplex NAY

rcharacter =
  function(
    elements =
      list(
        nchar = c(min = 0, max = default(nchar.size %||% severity)),
        string = c(min = 0, max = default(character.max %||% severity))),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    elements = arg.match(elements)
    nchar = elements[["nchar"]]
    string = elements[["string"]]
    size = rsize(arg.match(size))
    if(!is.fofun(nchar)) {
      nn = nchar
      nchar =
        function(n)
          rinteger(
            elements =
              arg.match(
                nn,
                c(min = 0, max = default(nchar.size %||% severity))),
            size = ~n)}
    if(!is.fofun(string)) {
      ss = string
      string =
        function(n)
          sapply(
            rinteger(
              elements =
                arg.match(
                  ss,
                  c(min = 0, max = default(character.max %||% severity))),
              size = ~n),
            digest)}
    unname(
      substr(
          rdata(string, size),
        1,
        rdata(nchar, size)))}

rfactor =
  function(
    elements = c(nlevels = default(nlevels %||% severity)),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(!is.fofun(elements))
      elements = Curry(sample, x = 1:arg.match(elements)$nlevels, replace = TRUE)
    size = rsize(arg.match(size))
    as.factor(rdata(elements, size))}

rraw =
  function(
    elements = c(min = 0, max = default(raw.max %||% severity)),
    size = c(min = 0, max = default(vector.size %||% 10 * severity))) {
    if(is.numeric(elements[[1]])) {
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
            Curry(rlist, size = size, height = height - 1))),
    size = c(min = 0, max = default(list.size %||% severity)),
    height = default(list.height %||% round(severity/2))) {
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
    if(!is.fofun(size))
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
  function(elements, size = c(min = 0, max = ceiling(length(elements)/2)), replace = TRUE) {
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

rnamed =
  function(
    x,
    names = list(
      nchar = c(min = 0, max = default(nchar.size %||% severity)),
      string = c(min = 0, max = default(character.max %||% severity)))) {
    names(x) = rcharacter(elements = names, size = ~length(x))
    x}

named =
  function(
    generator,
    names = list(
      nchar = c(min = 0, max = default(nchar.size %||% severity)),
      string = c(min = 0, max = default(character.max %||% severity)))) {
    function()
      rnamed(
        if(is.function(generator))
          generator()
        else
          eval(tail(as.list(generator), 1)[[1]], environment(generator)),
        names)}
