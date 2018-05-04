##
## Copyright (C) 2018 Alex Thiessen <alex.thiessen.de+github@gmail.com>
##
## This file is part of Compiler-Flags-Lexer.
##
## Compiler-Flags-Lexer is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Numbers is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Numbers.  If not, see <http://www.gnu.org/licenses/>.
##
## SPDX-License-Identifier: GPL-3.0-or-later
## <https://spdx.org/licenses/GPL-3.0-or-later.html>
##

cmake_minimum_required(VERSION 3.1)
project(compiler-flags-lexer)

find_package(FLEX)
flex_target(CompilerFlagsLexer_impl compiler-flags.l
	${CMAKE_CURRENT_BINARY_DIR}/compiler-flags.c)

# compiler-flags-lexer.h is here
include_directories(${CMAKE_SOURCE_DIR})

add_executable(compiler-flags-lexer
	COPYING
	${FLEX_CompilerFlagsLexer_impl_OUTPUTS}
	main.c
	compiler-flags.h
)

enable_testing()
macro(compiler_flags_lexer_test name input expected_regex)
	add_test(NAME "${name}-${input}" COMMAND ./compiler-flags-lexer
		"${input}")
	set_tests_properties("${name}-${input}" PROPERTIES
		PASS_REGULAR_EXPRESSION "^${expected_regex}\n$")
endmacro(compiler_flags_lexer_test)

# simple positive tests
compiler_flags_lexer_test(define-simple --defines -DDEFINE  "DEFINE")
compiler_flags_lexer_test(include-simple --includes -Iinclude "include")
