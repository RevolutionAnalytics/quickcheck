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

#the appeasment
# define all these awful globals to appease R CMD check

quickcheck.env =
  list2env(
    list(
      severity = 10,
      sample.size = NULL,
      vector.size = NULL,
      integer.size = NULL,
      double.size = NULL,
      nchar.max = NULL,
      unique.max = NULL,
      nlevels = NULL,
      raw.max = NULL,
      list.size = NULL,
      list.height = NULL,
      matrix.ncol = NULL,
      matrix.nrow = NULL,
      data.frame.ncol = NULL,
      data.frame.nrow = NULL,
      work.dir =
        quote(
          quote(
            if(.Platform$OS.type == "windows")
              "."
            else
              "/tmp"))))

for(var in ls(quickcheck.env))
  assign(var, quickcheck.env[[var]]) #silence R CMD check warnings

`%||%` =
  function(x, y)
    if(is.null(x) || is.na(x)) y else x

opt.assign = Curry(assign, envir = quickcheck.env)

qc.options =
  function(){
    args =
      lapply(
        as.list(sys.call())[-1],
        eval,
        envir = sys.frame(sys.parent()))
    if(!is.null(names(args))) {
      nargs = args[names(args) != ""] #for named args
      unargs = args[names(args) == ""] #for unnamed args
      names(nargs) = match.arg(names(nargs), ls(quickcheck.env), several.ok = TRUE)
      stopifnot(all(names(nargs) %in% ls(quickcheck.env)))}
    else {
      unargs = args}
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
        as.list(sys.call())[-1],
        eval,
        envir = sys.frame(sys.parent()))
    stopifnot(length(args) == 1)
    do.call(qc.options, args)[[1]]}

formals(qc.option) = formals(qc.options)

qc.option(work.dir = eval(eval(qc.option("work.dir"))))

## make use of testthat expectations

as.assertion =
  function(an.exp) {
    tmp = an.exp
    function(...) {
      tryCatch({tmp(...); TRUE} , error = function(e) FALSE)}}

time.limit =
  function(expr, user = Inf, system = Inf, elapsed = Inf) {
    setTimeLimit(user, elapsed, TRUE)
    time = system.time(eval.parent(expr))[1:3]
    setTimeLimit(Inf, Inf, TRUE)
    all(time <= c(user, system, elapsed))}

library(testthat)
assert.funs =
  c(
    do.call(
      c,
      lapply(
        c("error",  "message", "output",  "warning"),
        function(n)
          structure(
            list(
              as.assertion(
                get(
                  paste0("expect_", n),
                  envir = as.environment("package:testthat")))),
            names = n))),
    list(
      success = function(...) {list(...); TRUE},
      time.limit = time.limit))


expect =
function(expr, ...) {
    what = match.arg(what)
    assert.funs[[what]](expr, ...)}

formals(expect) = c(list(what = names(assert.funs)), formals(expect))

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

check.covr =
  function()
    if(!requireNamespace("covr"))
      stop(
        "Need to install covr to use this feature
         library(devtools)
         install_github(\"jimhester/covr@c70153f80461ca054771055309b02fd2a810750d\")")

tested.functions =
  function(assertion) {
    funs =
      unique(
        names(
          do.call(
            c,
            mget(
              all.names(body(assertion)),
              envir = environment(assertion),
              ifnotfound = list(list()),
              inherits = TRUE,
              mode = "function"))))
    mask =
      funs %in%
      c(
        ls(environment(assertion)),
        ls(parent.env(environment(assertion))))
    funs[mask]}

test =
  function(
    assertion,
    sample.size = default(sample.size %||% severity),
    stop = !interactive(),
    about = tested.functions(assertion),
    cover = FALSE) {
    about = as.character(about)
    if(length(about) == 0)
      warning("Can't guess what this test is about, please specify about argument")
    else {
      if(grepl("^package:", about)[1])
        about = intersect(ls(about), all.names(body(assertion)))
      message(paste("Testing", paste(about, collapse = " ")))}
    seed =
      cksum(
        digest(
          c(
            list(assertion),
            lapply(
              about,
              function(x)
                tryCatch(deparse(match.fun(x)), error = function(e) NULL)))))%%(2^31 - 1)
    message("Using seed ", seed)
    set.seed(seed)
    stopifnot(is.function(assertion))
    envir = parent.frame()
    if(is.logical(cover))
      cover = {
        if(cover)
          about[1]
        else
          NULL}
    assertion.text = deparse(assertion)
    try.assertion =
      function(xx) {
        assertion.return.value =
          tryCatch(
            do.call(assertion, xx),
            error =
              function(e) {message(e); FALSE})
        list(pass = all(as.logical(assertion.return.value)))}
    project =
      function(xx, name)
        lapply(xx, function(x) x[[name]])
    runs = NULL
    run =
      function() {
        runs <<-
          lapply(
            1:sample.size,
            function(i) {
              args = eval.args(formals(assertion), envir)
              result = try.assertion(args)
              if(!isTRUE(result$pass))
                message(
                  paste(
                    "FAIL: assertion:",
                    paste(assertion.text,
                          collapse = "\n"),
                    sep = "\n"))
              list(args = args, pass = result$pass, elapsed = result$elapsed)})}
    if(!is.null(cover)) {
      check.covr()
      cov = covr::function_coverage(cover, run(), env = envir)
      cover.fun = get(cover, envir = envir)
      cover.srcfile =
        as.list.environment(
          attributes(body(cover.fun))$srcfile %||%
            attributes(attributes(cover.fun)$srcref)$srcfile)
      if(cover.srcfile$filename == "") {
        srctemp = tempfile()
        writeLines(get.source(cover.fun), srctemp)
        names(cov) = paste0(srctemp, names(cov))}}
    else{
      cov = NULL
      run()}
    test.report =
      list(
        assertion = assertion,
        about = about,
        env =
          do.call(
            c,
            lapply(
              all.vars(body(assertion)),
              function(name)
                tryCatch(
                  structure(
                    list(
                      eval(
                        as.name(name),
                        envir = environment(assertion))),
                    names = name),
                  error = function(e) NULL))),
        cases = project(runs, "args"),
        pass = unlist(project(runs, "pass")),
        coverage = cov,
        elapsed = summary(unlist(project(runs, "elapsed"))))
    if(all(test.report$pass)){
      message(
        paste(
          "Pass ",
          "\n",
          paste(
            assertion.text,
            "\n",
            collapse = " ")))
      if(!is.null(cover)) {
        message(capture.output(print(test.report$coverage)))
        coverage(test.report$coverage)}}
    work.dir = file.path(default(work.dir), "quickcheck", Sys.getpid())
    if(!file.exists(work.dir))
      message("Creating ", work.dir, ".\n Use qc.options(work.dir = <alternate-path>) to change location.")
    dir.create(work.dir, recursive = TRUE, showWarnings = FALSE)
    tf = tempfile(tmpdir = work.dir, pattern = "tr")
    saveRDS(test.report, file = tf)
    if (stop && any(!test.report$pass)) {
      stop("\nto reproduce enter repro(\"", tf, "\")")}
    invisible(test.report)}

test.set = function(...) {
  test.results =
    list(...)
  if(length(test.results) == 1)
    test.results = list(test.results)
  retval = list()
  lapply(
    test.results,
    function(x)
      lapply(
        x$about,
        function(name){
          retval[[name]] <<- append(retval[[name]], x$assertion)
          retval}))
  structure(retval[sort(names(retval))], class = "TestSet")}

get.source =
  function(f) {
    src = capture.output(f)
    if(grepl("^<environment: ", tail(src, 1)) == 1)
      src[-length(src)]
    else
      src}

print.TestSet =
  function(x, ...){
    cat("----test set------\n")
    ll = lapply(x, function(y) paste(get.source(y), collapse = "\n"))
    cat(
      paste(
        "Function: ",
        names(ll),
        "\nAssertions:\n",
        ll,
        sep = " ",
        collapse = "\n"))}

smallest.failed =
  function(test.report)
    tail(
      arrange(
        filter(
          data.frame(
            pass = test.report$pass,
            size = sapply(test.report$cases, object.size),
            case.index = 1:length(test.report$cases)),
          !test.report$pass)),
      1)$case.index

repro =
  function(
    test.report,
    which = smallest.failed(test.report),
    assertion = test.report$assertion,
    debug = TRUE) {
    if(is.character(test.report))
      test.report = readRDS(test.report)
    if(length(which) == 0)
      stop("All tests pass, nothing to repro here.")
    if(debug) debug(assertion)
    do.call(assertion, test.report$cases[[which]])}

forall =
  function(..., .env = parent.frame()) {
    if(is.null(names(dots(...))) ||
       !all(head(names(dots(...)) != "", n = -1)))
      stop("Missing default value for some of the arguments")
    as.function(dots(...), envir = .env)}

coverage =
  function(x = "pkg/", ...) {
    check.covr()
    UseMethod(generic = "coverage", object = x)}

coverage.character =
  function(x = "pkg/", ... ) {
    path = x
    if(!file.exists(x))
      stop(x, " does not exist.")
    pc = covr::package_coverage(path)
    message(pc)
    covr::shine(pc)}

coverage.coverage =
  function(x, ...) {
    covr::shine(x) }
