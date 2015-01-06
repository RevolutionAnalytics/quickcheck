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
sample = 
	function(x, size, ...) 
		x[base::sample(length(x), size = size, ...)]

## readable Curry
fun = 
	function(a.call) 
		do.call(
			partial, 
			lapply(as.list(match.call()$a.call), eval.parent, n = 2))

## make use of testthat expectations
as.assertion =
	function(expectation)
		function(...) {
			tryCatch({expectation(...); TRUE} , error = function(e) FALSE)}

# import.expectations =
# 	function(){
# 		library(testthat)
# 		names = grep("^expect", ls("package:testthat"), value = TRUE)
# 		funs = lapply(names, function(n) as.assertion(get(n, envir = as.environment("package:testthat"))))
# 	  mapply(Curry(assign, envir = parent.frame()), paste0("q", names), funs)
# 	NULL}

unit.test =
	function(
		assertion,
		generators = list(),
		sample.size = 10,
		stop = TRUE) {
		set.seed(0)
		try.assertion =
			function(xx)
				tryCatch(
					do.call(assertion, xx),
					error =
						function(e) FALSE)
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
							args = lapply(generators, function(a) a())
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
			n(1)}

rdata = 
	function(element, size)
		element(rsize(size))

rlogical = 
	function(element = 0.5,	size = 10) {
		if(is.logical(element))
			element = as.numeric(element)
		if(is.numeric(element)) {
			p = element
			element = 
				function(n) 
					as.logical(rbinom(n, size = 1, prob = p))}
		as.logical(rdata(element,size))}

rinteger =
	function(element = 100, size = 10) {
		if(is.numeric(element))
			element = fun(rpois(lambda = element))
		as.integer(rdata(element,size))}

rdouble =
	function(element = 0, size = 10) {
		if(is.numeric(element))
			element = fun(rnorm(mean = element))
		as.double(rdata(element,size))}

##rcomplex NAY

rcharacter = 
	function(element = 10, size = 10) {
		if(is.character(element))
			element = nchar(element)
		if(is.numeric(element))
			element = fun(rpois(lambda = element))
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
			fun(
				rany( 
					generators =
						list(
							rlogical, 
							rinteger, 
							rdouble, 
							rcharacter, 
							rraw,
							rDate,
							rfactor,
							fun(rlist(size = size, height = rsize(height - 1)))))), 
		size = 5, 
		height = 4) {	
		if (height == 0) NULL
		else 		
			replicate(rsize(size), element(), simplify = FALSE)}

ratomic = 
	function(element = list(rlogical, rinteger, rdouble, rcharacter, rraw, rfactor), size = 10) {
		size = rsize(size)
		mixture(
			lapply(
				element,
				function(gg)
					fun(gg(size = constant(size)))))()}

rmatrix = 
	function(element = ratomic, nrow = 10, ncol = 10) {
		nrow = rsize(nrow)
		ncol = rsize(ncol)
		matrix(ratomic(size = constant(nrow*ncol)), nrow = nrow, ncol = ncol)}

rdata.frame =
	function(
		element =
			list(
				rlogical,
				rinteger,
				rdouble,
				rcharacter,
				rraw,
				rDate,
				rfactor),
		nrow = 10, 
		ncol = 5) {
		nrow = rsize(nrow)
		ncol = rsize(ncol)		
		columns =
			lapply(
				sample(element, ncol, replace = TRUE),
				function(g) 
					g(size = constant(nrow)))
		if(length(columns) > 0)
			names(columns) = paste("col", 1:ncol)
		do.call(data.frame, columns)}

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
			as.Date(rdata(element,size))}

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
rany =
	function(
		generators = 
			list(
				rlogical, 
				rinteger, 
				rdouble, 
				rcharacter, 
				rraw, 
				rlist, 
				rDate, 
				rfactor, 
				rmatrix, 
				rdata.frame))
		mixture(generators)()
