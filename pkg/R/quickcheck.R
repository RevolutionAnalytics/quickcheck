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
	function(acall) 
		do.call(partial, as.list(match.call()$acall))
#		do.call(Curry, as.list(match.call()$acall))

## make use of testthat expectations
as.predicate =
	function(expect)
		function(...) {
			tryCatch({expect(...); TRUE} , error = function(e) FALSE)}

# import.expectations =
# 	function(){
# 		library(testthat)
# 		names = grep("^expect", ls("package:testthat"), value = TRUE)
# 		funs = lapply(names, function(n) as.predicate(get(n, envir = as.environment("package:testthat"))))
# 	  mapply(Curry(assign, envir = parent.frame()), paste0("q", names), funs)
# 	NULL}

unit.test =
	function(
		predicate,
		generators = list(),
		sample.size = 10,
		precondition = function(...) TRUE,
		stop = TRUE) {
		set.seed(0)
		tryPredicate =
			function(xx)
				tryCatch(
					do.call(predicate, xx),
					error =
						function(e) FALSE)
		test.cases =
			list(
				predicate = predicate,
				env =
					do.call(
						c,
						lapply(
							all.vars(body(predicate)),
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
							if(do.call(precondition, args) &&	!tryPredicate(args)){
								print(paste("FAIL: predicate:", paste(deparse(predicate), collapse = " ")))
								args}}))
		if(all(sapply(test.cases$cases, is.null))){
			print(paste ("Pass ", paste(deparse(predicate), "\n", collapse = " ")))
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

rlogical = 
	function(element = 0.5,	size = 10) {
		if(is.logical(element))
			element = as.numeric(element)
		if(is.numeric(element)) {
			p = element
			element = 
				function(n) 
					as.logical(rbinom(n, size = 1, prob = p))}
		element(rsize(size))}

rinteger =
	function(element = 100, size = 10) {
		if(is.numeric(element))
			element = Curry(rpois, lambda = element)
		element(rsize(size))}

rdouble =
	function(element = 0, size = 10) {
		if(is.numeric(element))
			element = Curry(rnorm, mean = element)
		element(rsize(size))}

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
				function(x) substr(digest(x), 1, element(1))))}

rraw =
	function(element = as.raw(0:255), size = 10) {
		if(is.raw(element))
			element_ = select(element)
		element_(rsize(size))} 

rlist = 
	function(element = NULL, size = 5, height = 4) {	
		if (height == 0) NULL
		else 
			if(is.null(element)) {
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
								Curry(rlist, size = size, height = rsize(height - 1))))
				replicate(rsize(size), element(), simplify = FALSE)}}

rdata.frame =
	function(
		nrow = 10, 
		ncol = 5, 
		col.generators =
			list(
				rlogical,
				rinteger,
				rdouble,
				rcharacter)) {
		nrow = rsize(nrow)
		ncol = rsize(ncol)		
		columns =
			lapply(
				sample(col.generators, ncol, replace = TRUE),
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
			element(rsize(size))}

## special distributions

constant =
	function(const = NULL)
		function(...)
			const

select = 
	function(from)
		function(size = 1)
			sample(from, size, replace = TRUE)

##combiners
mixture =
	function(...)
		function()
			sample(list(...), 1)[[1]]()

# combine everything
rany =
	function(generators = list(rlogical, rinteger, rdouble, rcharacter, rraw, rlist))
		do.call(mixture, generators)()
