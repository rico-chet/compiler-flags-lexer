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
        compiler-flags.h
        compiler-flags.l
        COPYING
        ${FLEX_CompilerFlagsLexer_impl_OUTPUTS}
        main.c
)

# test coverage
add_definitions(--coverage)
target_link_libraries(compiler-flags-lexer gcov)

enable_testing()

add_test(NAME "define-simple" COMMAND ./compiler-flags-lexer --defines
        "-DDEFINE")
set_tests_properties("define-simple" PROPERTIES PASS_REGULAR_EXPRESSION
	"^DEFINE\n$")

add_test(NAME "include-simple" COMMAND ./compiler-flags-lexer --includes
        "-Iinclude")
set_tests_properties("include-simple" PROPERTIES PASS_REGULAR_EXPRESSION
	"^include\n$")

add_test(NAME "define-reentrant" COMMAND ./compiler-flags-lexer --defines-r2
        "-DDEFINE")
set_tests_properties("define-reentrant" PROPERTIES PASS_REGULAR_EXPRESSION
	"^DEFINE\nDEFINE\n$")

add_test(NAME "define-multi" COMMAND ./compiler-flags-lexer --defines
        "-DDEFINE -DANOTHER_ONE")
set_tests_properties("define-multi" PROPERTIES PASS_REGULAR_EXPRESSION
        "^DEFINE\nANOTHER_ONE\n$")

add_test(NAME "include-multi" COMMAND ./compiler-flags-lexer --includes
        "-Iinclude -Ianotherone")
set_tests_properties("include-multi" PROPERTIES PASS_REGULAR_EXPRESSION
        "^include\nanotherone\n$")

add_test(NAME "include-quotes-double" COMMAND ./compiler-flags-lexer --includes
        "-I\"include this\"")
set_tests_properties("include-quotes-double" PROPERTIES PASS_REGULAR_EXPRESSION
        "^include this\n$")

add_test(NAME "include-quotes-double-with-embeds" COMMAND ./compiler-flags-lexer --includes
        "-I\"include \\\"this\"")
set_tests_properties("include-quotes-double-with-embeds" PROPERTIES PASS_REGULAR_EXPRESSION
        "^include \\\"this\n$")

add_test(NAME "include-quotes-single" COMMAND ./compiler-flags-lexer --includes
        "-I'include this'")
set_tests_properties("include-quotes-single" PROPERTIES PASS_REGULAR_EXPRESSION
        "^include this\n$")

add_test(NAME "include-quotes-single-with-embeds" COMMAND ./compiler-flags-lexer --includes
        "-I'include \\'this'")
set_tests_properties("include-quotes-single-with-embeds" PROPERTIES PASS_REGULAR_EXPRESSION
        "^include \\'this\n$")

add_test(NAME "define-simple-with-input" COMMAND ./compiler-flags-lexer --defines
        "-DDEFINE some_input_file")
set_tests_properties("define-simple-with-input" PROPERTIES PASS_REGULAR_EXPRESSION
        "^DEFINE\n$")

add_test(NAME "define-simple-with-std-input" COMMAND ./compiler-flags-lexer --defines
        "-DDEFINE - some_input_file")
set_tests_properties("define-simple-with-std-input" PROPERTIES PASS_REGULAR_EXPRESSION
        "^DEFINE\n$")

add_test(NAME "define-simple-with-input-sep" COMMAND ./compiler-flags-lexer --defines
        "-DDEFINE -- some_input_file")
set_tests_properties("define-simple-with-input-sep" PROPERTIES PASS_REGULAR_EXPRESSION
        "^DEFINE\n$")
