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

## quirkless sample

quickcheck.env = new.env()

quickcheck.env$nested = FALSE

sample = 
	function(x, size, ...) 
		x[base::sample(length(x), size = size, ...)]

## 

## argument is called assertion for user facing API, but used also on generators internally
repro = 
eval.formula.or.function = 
	function(assertion, args = list()) {
		if(is.function(assertion))
			do.call(assertion, args)
		else
			eval(tail(as.list(assertion), 1)[[1]], args, environment(assertion))}
		
## make use of testthat expectations

as.assertion =
	function(an.exp) {
		tmp = an.exp
		function(...) {
			tryCatch({tmp(...); TRUE} , error = function(e) FALSE)}}

library(testthat)
assert.names = grep("^expect_", ls("package:testthat"), value = TRUE)
assert.funs = lapply(assert.names, function(n) as.assertion(get(n, envir = as.environment("package:testthat"))))
names(assert.funs) = gsub("expect_", "", assert.names)
	
assert = 
	function(what, ...)
			assert.funs[[what]](...)

is.formula = 
	function(x)
		class(x) == "formula"

test =
	function(
		assertion,
		generators = list(),
		sample.size = 10,
		stop = TRUE) {
		if(!quickcheck.env$nested) {
			set.seed(0)
			quickcheck.env$nested = TRUE
			on.exit({quickcheck.env$nested = FALSE})}
		stopifnot(is.function(assertion) || is.formula(assertion))
		if(!is.list(generators))
			generators = list(generators)
		try.assertion =
			function(xx)
				tryCatch(
					eval.formula.or.function(assertion, xx),
					error =
						function(e) {message(e); FALSE})
		test.cases =
			list(
				assertion = assertion,
				env =
					do.call(
						c,
						lapply(
							all.vars(body(assertion)),
							function(name)
								tryCatch({
									val = list(eval(as.name(name)))
									names(val) = name
									val},
									error = function(e) NULL))),
				cases =
					lapply(
						1:sample.size,
						function(i) {
							args = lapply(generators, eval.formula.or.function, args = list())
							args2 = lapply(formals(assertion), function(x) if(is.symbol(x)) NULL else  eval(x))
							if(is.null(names(args2))) names(args2) = replicate(length(args2), "")
							args[names(args2)] = args2
							if(!try.assertion(args)){
								print(paste("FAIL: assertion:", paste(deparse(assertion), collapse = " ")))
								args}}))
		if(all(sapply(test.cases$cases, is.null))){
			print(paste ("Pass ", paste(deparse(assertion), "\n", collapse = " ")))
			TRUE}
		else {
			if (stop) {
				tf = tempfile(tmpdir=".", pattern = "quickcheck")
				save(test.cases, file = tf)
				stop("load(\"", file.path(getwd(), tf), "\")")}
			else test.cases}}


## basic types


rsize = 
	function(n) {
		if(is.numeric(n))
			rpois(1, lambda = n)
		else
			eval.formula.or.function(n)[[1]]}

rdata = 
	function(element, size) {
		size = rsize(size)
		eval.formula.or.function(
			element, 
			if(is.function(element))
				list(size)
			else 
				list(size = rsize(size)))}

rlogical = 
	function(element = 0.5,	size = 10) {
		if(is.logical(element))
			element = as.numeric(element)
		if(is.numeric(element)) {
			p = element
			element = 
				function(n) 
					as.logical(rbinom(n, size = 1, prob = p))}
		as.logical(rdata(element, size))}

rinteger =
	function(element = 100, size = 10) {
		if(is.numeric(element))
			element = Curry(rpois, lambda = element)
		as.integer(rdata(element, size))}

rdouble =
	function(element = 0, size = 10) {
		if(is.numeric(element))
			element = Curry(rnorm, mean = element)
		as.double(rdata(element, size))}

rnumeric = 
	function(element = 100, size = 10)
		mixture(
			list(
				Curry(rdouble, element = element, size = size), 
				Curry(rinteger, element = element, size = size)))()

##rcomplex NAY

rcharacter = 
	function(element = 10, size = 10) {
		if(is.character(element))
			element = nchar(element)
		if(is.numeric(element))
			element = Curry(rpois, lambda = element)
		unlist(
			sapply(
				runif(rsize(size)),
				function(x) substr(digest(x), 1, as.character(element(1)))))}

rfactor = function(element = 10, size = 10)
	as.factor(rcharacter(element, size))

rraw =
	function(element = as.raw(0:255), size = 10) {
		if(is.raw(element))
			element_ = select(element)
		as.raw(element_(rsize(size)))} 

rlist = 
	function(
		element = 
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
		size = 5, 
		height = 4) {	
		if (height == 0) NULL
		else 		
			replicate(rsize(size), eval.formula.or.function(element), simplify = FALSE)}

ratomic = 
	function(element = atomic.generators, size = 10) {
		size = rsize(size)
		mixture(
			lapply(
				element,
				function(gg)
					Curry(gg, size = constant(size))))()}

rmatrix = 
	function(element = ratomic, nrow = 10, ncol = 10) {
		nrow = rsize(nrow)
		ncol = rsize(ncol)
		matrix(ratomic(size = constant(nrow*ncol)), nrow = nrow, ncol = ncol)}

rDate =
	function(element = list(from = as.Date("0000/01/01"), to = Sys.Date()), size = 10) {
		if(is.list(element)) {
			dates = as.Date(element$from):as.Date(element$to)
			as.Date(
				sample(
					dates,
					rsize(size), replace = TRUE),
				origin = as.Date("1970-01-01"))}
		else
			as.Date(rdata(element, size))}

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
		columns = replicate(ncol, ratomic(size = constant(nrow)), simplify = FALSE)
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
	function(const = NULL)
		function(...)
			const

select = 
	function(from, replace = TRUE)
		function(size = 1)
			sample(from, size, replace = replace)

##combiners
mixture =
	function(generators)
		function()
			sample(generators, 1)[[1]]()

# combine everything
all.generators = c(atomic.generators, list(rlist, rdata.frame, rmatrix))

rany =
	function(generators = all.generators)
		mixture(generators)()
