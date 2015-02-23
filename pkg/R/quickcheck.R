# Copyright 2011 Revolution Analytics
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


quickcheck.env =
  list2env(
    list(
      severity = 10,
      sample.size = NULL,
      vector.size = NULL,
      integer.size = NULL,
      double.size = NULL,
      nchar.size = NULL,
      character.max = NULL,
      nlevels = NULL,
      raw.max = NULL,
      list.size = NULL,
      list.height = NULL,
      matrix.ncol = NULL,
      matrix.nrow = NULL,
      data.frame.ncol = NULL,
      data.frame.nrow = NULL))

`%||%` =
  function(x, y)
    if(is.null(x)) y else x

opt.assign = Curry(assign, envir = quickcheck.env)

qc.options =
  function(...){
    args = as.list(match.call())[-1]
    if(!is.null(names(args))) {
      nargs = args[names(args) != ""]
      unargs = args[names(args) == ""]
      names(nargs) = match.arg(names(nargs), ls(quickcheck.env), several.ok = TRUE)
      stopifnot(all(names(nargs) %in% ls(quickcheck.env)))}
    else {
      unargs = args
    }
    if(length(unargs) > 0)
      unargs = match.arg(unlist(unargs),  ls(quickcheck.env), several.ok = TRUE)
    stopifnot(all(unargs %in% ls(quickcheck.env)))
    nargs =
      do.call(
        c,
        lapply(
          names(nargs),
          function(nargi){
            opt.assign(nargi, nargs[[nargi]])
            nargs[nargi]}))
    unargs = as.list(quickcheck.env)[unlist(unargs)]
    c(nargs, unargs)}

formals(qc.options) = c(formals(qc.options), do.call(pairlist, as.list(quickcheck.env)))

qc.option =
  function(...) {
    stopifnot(length(list(...)) == 1)
    qc.options(...)[[1]]}


default =
  function(x) {
    x = lazy(x)
    lazy_eval(x, as.list(quickcheck.env))}

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
      stopifnot(max >= min)
      if(0 %in% (min + 1):(max - 1)) {
        negative = - rzipf(n, - min + 1, s ) + 1
        positive = rzipf(n, max + 1, s) - 1
        ifelse(
          sample(c(TRUE,FALSE), n, replace = TRUE),
          positive,
          negative)}
      else
        min - 1 + rzipf(n , max - min + 1, s)}}

rzeta =
  function(n, s) {
    u = runif(n)
    N = 2
    repeat {
      bins = cumsum(dzeta(1:N, s - 1))
      if(max(u) < max(bins)) break
      N = 2 * N }
    sample(
      cumsum(
        !arrange(
          rbind(
            data.frame(sample = TRUE, data = u),
            data.frame(sample = FALSE, data = bins)),
          data)$sample)) + 1}

## quirkless sample

sample =
  function(x, size, ...)
    x[base::sample(length(x), size = size, ...)]


## make use of testthat expectations

as.assertion =
  function(an.exp) {
    tmp = an.exp
    function(...) {
      tryCatch({tmp(...); TRUE} , error = function(e) FALSE)}}

library(testthat)
expect.names = grep("^expect_", ls("package:testthat"), value = TRUE)
assert.funs = lapply(expect.names, function(n) as.assertion(get(n, envir = as.environment("package:testthat"))))
names(assert.funs) = gsub("expect_", "", expect.names)

expect =
  function(what, ...)
    assert.funs[[what]](...)

is.formula =
  function(x)
    class(x) == "formula"

eval.args =
  function(args, envir) {
    args[[1]] = eval(args[[1]], envir)
    lapply(
      1 + seq_along(args[-1]),
      function(i)
        args[[i]] <<- eval(args[[i]], args[1:(i-1)], envir))
    as.list(args)}

test =
  function(
    assertion,
    sample.size = qc.option("sample.size") %||% qc.option("severity"),
    stop = !interactive()) {
    set.seed(cksum(digest(match.call()))%%(2^31 - 1))
    stopifnot(is.function(assertion))
    envir = environment(assertion)

    try.assertion =
      function(xx) {
        start = get_nanotime()
        assertion.return.value =
          tryCatch(
            do.call(assertion, xx),
            error =
              function(e) {message(e); FALSE})
        list(
          pass = all(as.logical(assertion.return.value)),
          elapsed.time = get_nanotime() - start)}
    project =
      function(xx, name)
        lapply(xx, function(x) x[[name]])
    runs =
      lapply(
        1:sample.size,
        function(i) {
          args = eval.args(formals(assertion), envir)
          result = try.assertion(args)
          if(!isTRUE(result$pass))
            message(
              paste(
                "FAIL: assertion:",
                paste(deparse(assertion),
                      collapse = "\n"),
                sep = "\n"))
          list(args = args, pass = result$pass, elapsed = result$elapsed)})


    test.report =
      list(
        assertion = assertion,
        env =
          do.call(
            c,
            lapply(
              all.vars(body(assertion)),
              function(name)
                tryCatch({
                  val =
                    list(
                      eval(
                        as.name(name),
                        envir = environment(assertion)))
                  names(val) = name
                  val},
                  error = function(e) NULL))),
        cases = project(runs, "args"),
        pass = unlist(project(runs, "pass")),
        elapsed = summary(unlist(project(runs, "elapsed"))))
    if(all(test.report$pass)){
      message(
        paste(
          "Pass ",
          "\n",
          paste(
            deparse(assertion),
            "\n",
            collapse = " ")))
      print(test.report$elapsed)}
    tmpdir = file.path("/tmp", Sys.getpid())
    dir.create(tmpdir, showWarnings = FALSE)
    tf = tempfile(tmpdir = tmpdir, pattern = "quickcheck")
    save(test.report, file = tf)
    if (stop && any(!test.report$pass)) {
      stop("load(\"", tf, "\")")}
    invisible(test.report)}

first.false =
  function(xx)
    min(which(!xx))

repro =
  function(test.report, i = first.false(test.report$pass), debug = TRUE) {
    assertion = test.report$assertion
    if(!is.finite(i))
      stop("All tests pass, nothing to repro here.")
    if(debug) debug(assertion)
    do.call(assertion, test.report$cases[[i]])}

no.coverage =
  function(path = "pkg/") {
    pc = package_coverage(path)
    zc = zero_coverage(pc)
    temp = tempfile(fileext = ".html")
    writeLines(
      unlist(
        lapply(
          unique(zc$filename),
          function(fname) {
            ffname = file.path(path, fname)
            src = readLines(ffname)
            zc = zc[zc$filename == fname, , drop = FALSE]
            mapply(
              function(sta, sto){
                src[sta] <<- paste("<strong>", src[sta])
                src[sto] <<- paste(src[sto], "</strong>")},
              zc$first_line,
              zc$last_line)
            c(
              paste("<h2>", ffname , "</h2>\n<pre>"),
              src,
              "</pre>")})),
      con = temp)
    browseURL(paste0("file://", temp))}

