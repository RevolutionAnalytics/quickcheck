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


quickcheck.env = new.env()

quickcheck.env$severity = 10
quickcheck.env$sample.size = NULL
quickcheck.env$vector.size = NULL
quickcheck.env$integer.size = NULL
quickcheck.env$double.size = NULL
quickcheck.env$char.size = NULL
quickcheck.env$nlevels = NULL
quickcheck.env$raw.max = NULL
quickcheck.env$list.size = NULL
quickcheck.env$list.height = NULL

`%||%` = 
	function(x, y) 
		if(is.null(x)) y else x


qc.options = 
	function(...){
		args = list(...)
		ll = 
			lapply(
				seq_along(args),
				function(i){
					nargi = names(args[i])
					if(is.null(nargi) || nargi == "" )
						quickcheck.env[[args[[i]]]]
					else {
						quickcheck.env[[nargi]] == args[[i]]
						args[[i]]}})
		names(ll) = {
			if(is.null(names(args)))
				args
			else
				ifelse(names(args) %in% list("", NA, NULL), args, names(args))}
		ll}

qc.option = 
	function(...) {
		stopifnot(length(list(...)) == 1)
		qc.options(...)[[1]]}


default = 
	function(x) {
		x = lazy(x)
		lazy_eval(x, as.list(quickcheck.env))}

## zipf

rzipf  = 
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

rzipf.range  =
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

rzeta  = 
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


eval.formula.or.function= 
	function(fof, args = list()) {
		if(is.function(fof))
			do.call(fof, args)
		else
			eval(tail(as.list(fof), 1)[[1]], args, environment(fof))}

eval.generator = 
	function(rng, size = NULL) {
		data = 
			eval.formula.or.function(
				rng,
				if(is.null(size)) list()
				else {
				if(is.function(rng))
					list(size)
				else 
					list(size = size)})
		stopifnot(size == length(data))
		data}

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
		set.seed(0)
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
					if(is.na(result$pass) || !result$pass)
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
		tf = tempfile(tmpdir = ".", pattern = "quickcheck")
		save(test.report, file = tf)
		if (stop && any(!test.report$pass)) {
			stop("load(\"", file.path(getwd(), tf), "\")")}
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

## basic types

rsize = 
	function(generator) {
		if(is.numeric(generator)){
			stopifnot(length(generator) <=2)
			if(length(generator) == 1) 
				generator = c(min = 0, max = generator)				
			rzipf.range(1, generator[["min"]], generator[["max"]], s = 1)}
		else
			as.integer(round(eval.generator(generator)))}

rdata = 
	function(generator, size) 
		eval.generator(generator, rsize(size))

default.vector.size = 
	function()
		default(vector.size %||% 4 * severity)

rlogical = 
	function(generator = c(p = 0.5),	size = default.vector.size()) {
		if(is.numeric(generator)) {
			p = generator
			generator = 
				function(n) 
					as.logical(rbinom(n, size = 1, prob = p))}
		as.logical(rdata(generator, size))}


rinteger =
	function(generator = c(max = default(integer.size %||% 10 * severity)), size = default.vector.size()) {
		if(is.numeric(generator)) {
			lg = length(generator) 
			if(lg == 0 || lg > 2) 
				stop("generator argument can only have length 1 or 2 when numeric")
			if(lg == 1) generator = c(min = -generator[[1]], max = generator[[1]])
			generator = 
				Curry(rzipf.range, min = generator[["min"]], max = generator[["max"]])}
		as.integer(rdata(generator, size))}

rdouble =
	function(
		generator = c(mean = 0, sd = default(double.size %||% 10 * severity)), 
		size = default.vector.size()) {
		if(is.numeric(generator)) {
			stopifnot(length(generator) <=2)
			if(length(generator) == 1) 
				generator = c(mean = 0, sd = generator)
			generator = Curry(rnorm, mean = generator[["mean"]], sd = generator[["sd"]])}
		as.double(rdata(generator, size))}

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
		nchar = default(char.size %||% severity), 
		size = default.vector.size()) {
		size = rsize(size)
		nchar = {
			if(is.numeric(nchar))
				rpois(n = size, lambda = nchar)
			else
				eval.generator(nchar, size)}
		substr(
			sapply(
				runif(size), digest), 
			1, 
			nchar)}

rfactor = 
	function(
		generator = c(nlevels = default(nlevels %||% severity)), 
		size = default.vector.size()) {
		if(is.numeric(generator))
			generator = Curry(sample, x = 1:generator, replace = TRUE)
		as.factor(rdata(generator, size))}

rraw =
	function(
		generator = default(raw.max %||% severity),
		size = default.vector.size()) {
		if(is.numeric(generator))
			generator = as.raw(0:generator)
		if(is.raw(generator))
			generator = Curry(sample, x = generator, replace = TRUE )
		as.raw(rdata(generator, size))} 

rlist = 
	function(
		element = 
			Curry(
				rany, 
				data.generators =
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
				element(), 
				simplify = FALSE)}

ratomic = 
	function(element = atomic.generators, size = default.vector.size()) {
		size = rsize(size)
		mixture(
			lapply(
				element,
				function(gg){
					hh = gg
					Curry(hh, size = constant(size))}))()}

rmatrix = 
	function(distribution = ratomic, nrow = 10, ncol = 10) {
		nrow = rsize(nrow)
		ncol = rsize(ncol)
		matrix(distribution(size = constant(nrow*ncol)), nrow = nrow, ncol = ncol)}

rDate =
	function(element = list(from = as.Date("0000/01/01"), to = Sys.Date()), size = default.vector.size()) {
		if(is.list(element)) {
			dates = as.Date(element$from):as.Date(element$to)
			as.Date(
				sample(
					dates,
					rsize(size), replace = TRUE),
				origin = as.Date("1970-01-01"))}
		else
			as.Date(rdata(generator, size))}

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
		element = ratomic,
		nrow = 10, 
		ncol = 5) {
		nrow = rsize(nrow)
		ncol = rsize(ncol)		
		columns = replicate(ncol, element(size = constant(nrow)), simplify = FALSE)
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
	function(data.generators) {
		force(data.generators)
		function(...)
			sample(data.generators, 1)[[1]](...)}

# combine everything
all.data.generators = c(atomic.generators, list(rlist, rdata.frame, rmatrix))

rany =
	function(data.generators = all.data.generators)
		mixture(data.generators)()
