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

#the appeasment
# define all these awful globals to appease R CMD check

severity = 10
sample.size = NULL
vector.size = NULL
integer.size = NULL
double.size = NULL
nchar.size = NULL
character.max = NULL
nlevels = NULL
raw.max = NULL
list.size = NULL
list.height = NULL
matrix.ncol = NULL
matrix.nrow = NULL
data.frame.ncol = NULL
data.frame.nrow = NULL
tmpdir = {
  if(.Platform$OS.type == "windows")
    "."
  else
    "/tmp"}

quickcheck.env =
  list2env(
    do.call(
      c,
      lapply(
        ls(),
        function(x) {
          l = list(eval(as.name(x)))
          names(l) = x
          l})))

`%||%` =
  function(x, y)
    if(is.null(x)) y else x

opt.assign = Curry(assign, envir = quickcheck.env)

qc.options =
  function(...){
    args =
      lapply(
        as.list(match.call())[-1],
        eval,
        envir = sys.frame(sys.parent()))
    if(!is.null(names(args))) {
      nargs = args[names(args) != ""] #for named args
      unargs = args[names(args) == ""] #for unnamed args
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

formals(qc.options) =
  c(formals(qc.options),
    do.call(pairlist, as.list(quickcheck.env)[sort(ls(quickcheck.env))]))

qc.option =
  function() {
    args =
      lapply(
        as.list(match.call())[-1],
        eval,
        envir = sys.frame(sys.parent()))
    stopifnot(length(args) == 1)
    do.call(qc.options, args)[[1]]}

formals(qc.option) = formals(qc.options)


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

minhash =
  function(tokens)
    min(
      cksum(
        mapply(
          function(x, i, j) paste(x[i:j], collapse = " "),
          MoreArgs = list(x = tokens),
          1:max(0, (length(tokens) - 6)),
          min(7, length(tokens)):length(tokens))))%%(2^31 - 1)

test =
  function(
    assertion,
    sample.size = default(sample.size %||% severity),
    stop = !interactive()) {
    tokens = unlist(strsplit(deparse(assertion), split = "[ \t(){},]"))
    tokens = tokens[tokens != ""]
    seed = minhash(tokens)
    message("Using seed ", seed)
    set.seed(seed)
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
    tmpdir = file.path(default(tmpdir), "quickcheck", Sys.getpid())
    if(!file.exists(tmpdir))
      message("Creating ", tmpdir, ". Use qc.options(tmpdir = <alternate-path>) to change location.")
    dir.create(tmpdir, recursive = TRUE, showWarnings = FALSE)
    tf = tempfile(tmpdir = tmpdir, pattern = "tr")
    saveRDS(test.report, file = tf)
    if (stop && any(!test.report$pass)) {
      stop("repro(\"", tf, "\")")}
    invisible(test.report)}

first.false =
  function(xx)
    min(which(!xx))

repro =
  function(test.report, i = first.false(test.report$pass), debug = TRUE) {
    if(is.character(test.report))
      test.report = readRDS(test.report)
    assertion = test.report$assertion
    if(!is.finite(i))
      stop("All tests pass, nothing to repro here.")
    if(debug) debug(assertion)
    do.call(assertion, test.report$cases[[i]])}

no.coverage =
  function(path = "pkg/") {
    if(!requireNamespace("covr"))
      stop(
        "Need to install covr to use this feature
         library(devtools)
         install_github(\"jimhester/covr@b181831f0fd4299f70c330b87a73d9ec2d13433\")")
    pc = covr::package_coverage(path)
    print(pc)
    zc = covr::zero_coverage(pc)
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

