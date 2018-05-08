%option stack

%top{

//
// Copyright (C) 2018 Alex Thiessen <alex.thiessen.de+github@gmail.com>
//
// This file is part of Compiler-Flags-Lexer.
//
// Compiler-Flags-Lexer is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Numbers is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Numbers.  If not, see <http://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: GPL-3.0-or-later
// <https://spdx.org/licenses/GPL-3.0-or-later.html>
//

#include "compiler-flags.h"
#include <limits.h>
#include <string.h>

enum mode_t
{
	mode_defines,
	mode_includes,
	mode_count
};

#define YY_DECL \
	bool yylex(enum mode_t mode, char* restrict result, size_t result_size)

#define yyterminate() return false

}

%{

// constants
const static bool g_trace = false;

// function declarations
static void begin(int start_condition);
static void pop_state();
static void print_start_condition_state(void);
static void push_state(int new_state);
static const char* start_condition_name(int start_condition);

// function definitions
static int min_int(const int a, const int b)
{
	return a < b ? a : b;
}
static bool append_to_buffer(const char* restrict const text,
	                           const int                  text_length_optional,
	                           char* restrict* restrict result,
	                           size_t* restrict const result_size)
{
	if (!(text && (text_length_optional == -1 || 0 < text_length_optional)
		    && result
		    && *result
		    && result_size
		    && 0 < *result_size
		    && *result_size <= INT_MAX))
		return false;

	const int text_length =
		  text_length_optional == -1 ? strlen(text) : text_length_optional;
	const int copy_length = min_int(text_length, (int)(*result_size - 1));
	if (!(copy_length + 1 <= *result_size))
		return false;

	strncpy(*result, text, copy_length);
	*result += copy_length;
	**result = '\0';
	*result_size -= copy_length;

	if (g_trace)
	{
		fprintf(stderr, "%s: %s\n", __func__, text);
	}
	return true;
}

%}

%x define_name
%x define_value
%x double_quoted_string
%x etc_flag
%x flag
%x include
%x input_file_
%x input_files_only
%x single_quoted_string
%x start_condition_count

%%
%{

	// almost at the beginning of the yylex function

%}

- { push_state(flag); }
<flag>{
	D { pop_state(); push_state(define_name); }
	I { pop_state(); push_state(include); }
	[[:blank:]] { /* stdin as input */ pop_state(); }
	-[[:blank:]] { pop_state(); push_state(input_files_only); }
	. { pop_state(); /* skip over other flags*/ push_state(etc_flag); }
}

<define_value,include,etc_flag,input_files_only,INITIAL>{
	['"] {
	if (YY_START == INITIAL || YY_START == input_files_only)
	{
		push_state(input_file_);
	}
		push_state(yytext[0] == '"' ? double_quoted_string : single_quoted_string);
	}
}

[^'"[:blank:]-] {
	push_state(input_file_);
	yymore();
}

<input_files_only>[^'"] {
	push_state(input_file_);
	yymore();
}

<input_file_>[^[:blank:]]+ { /* no according mode yet */ }

<define_name>{
	[[:alpha:]_][[:alnum:]_]* {
		if (mode == mode_defines)
		{
			if (!append_to_buffer(yytext, yyleng, &result, &result_size))
				yyterminate();
			if (!append_to_buffer("\n", 1, &result, &result_size))
				yyterminate();
		}
	}
	= { pop_state(); push_state(define_value); }
	[ ] { pop_state(); }
}

<include>[^[:blank:]'"]+ {
	if (mode == mode_includes)
	{
		if (!append_to_buffer(yytext, yyleng, &result, &result_size))
			yyterminate();
		if (!append_to_buffer("\n", 1, &result, &result_size))
			yyterminate();
	}
	pop_state();
}

<double_quoted_string>{
	\\\" {
		if (yy_top_state() == define_value && mode == mode_defines
		    || yy_top_state() == include && mode == mode_includes)
		{
			if (!append_to_buffer(yytext, yyleng - 2, &result, &result_size))
				yyterminate();
			if (!append_to_buffer("\"", 1, &result, &result_size))
				yyterminate();
		}
	}

	\" {
		pop_state();
		if (YY_START == define_value && mode == mode_defines
		    || YY_START == include && mode == mode_includes)
		{
			if (!append_to_buffer(yytext, yyleng - 1, &result, &result_size))
				yyterminate();
			if (!append_to_buffer("\n", 1, &result, &result_size))
				yyterminate();
		}
		else if (YY_START == etc_flag || YY_START == input_file_)
		{
			// it's ok
		}
		else
		{
			yyterminate();
		}
		pop_state();
	}

	. { yymore(); }
}

<single_quoted_string>{
	\\\' {
		if (yy_top_state() == define_value && mode == mode_defines
		    || yy_top_state() == include && mode == mode_includes)
		{
			if (!append_to_buffer(yytext, yyleng - 2, &result, &result_size))
				yyterminate();
			if (!append_to_buffer("'", 1, &result, &result_size))
				yyterminate();
		}
	}

	\' {
		pop_state();
		if (YY_START == define_value && mode == mode_defines)
		{
			if (!append_to_buffer(yytext, yyleng - 1, &result, &result_size))
				yyterminate();
			if (!append_to_buffer("\n", 1, &result, &result_size))
				yyterminate();
		}
		else if (YY_START == include && mode == mode_includes)
		{
			if (!append_to_buffer(yytext, yyleng - 1, &result, &result_size))
				yyterminate();
			if (!append_to_buffer("\n", 1, &result, &result_size))
				yyterminate();
		}
		else if (YY_START == etc_flag || YY_START == input_file_)
		{
			// it's ok
		}
		else
		{
			yyterminate();
		}
		pop_state();
	}

	. { yymore(); }
}

<input_files_only,INITIAL>[[:blank:]]+ { /* skip to next flag or input */ }
<<EOF>> { return true; }
%%

#undef yywrap
int yywrap()
{
	return 1;
}

bool compiler_flags_defines(const char* restrict const text,
                            char* restrict const result,
                            const size_t         result_size)
{
	if (!(text && result && 0 < result_size))
		return false;

	YY_BUFFER_STATE buffer = yy_scan_string(text);
	const bool      good   = yylex(mode_defines, result, result_size);
	yy_delete_buffer(buffer);

	return good;
}

bool compiler_flags_includes(const char* restrict const text,
                             char* restrict const result,
                             const size_t         result_size)
{
	if (!(text && result && 0 < result_size))
		return false;

	YY_BUFFER_STATE buffer = yy_scan_string(text);
	const bool      good   = yylex(mode_includes, result, result_size);
	yy_delete_buffer(buffer);

	return good;
}

static void begin(const int new_start_condition)
{
	if (g_trace)
	{
		fprintf(stderr,
		        "%s: %s\n",
		        __func__,
		        start_condition_name(new_start_condition));
		print_start_condition_state();
	}

	BEGIN(new_start_condition);

	if (g_trace)
	{
		print_start_condition_state();
	}
}

static void push_state(const int new_state)
{
	if (g_trace)
	{
		fprintf(stderr, "%s: %s\n", __func__, start_condition_name(new_state));
		print_start_condition_state();
	}
	yy_push_state(new_state);

	if (g_trace)

	{
		print_start_condition_state();
	}
}

static void pop_state()
{
	if (g_trace)
	{
		fprintf(stderr, "%s\n", __func__);
		print_start_condition_state();
	}

	yy_pop_state();

	if (g_trace)
	{
		print_start_condition_state();
	}
}

static const char* start_condition_name(const int start_condition)
{
	if (!(0 <= start_condition && start_condition < start_condition_count))
		return "unknown";

	switch (start_condition)
	{
#define HANDLE_SC(sc)                                                          \
	case sc:                                                                     \
		return #sc

		HANDLE_SC(INITIAL);
		HANDLE_SC(define_name);
		HANDLE_SC(define_value);
		HANDLE_SC(double_quoted_string);
		HANDLE_SC(etc_flag);
		HANDLE_SC(flag);
		HANDLE_SC(include);
		HANDLE_SC(input_file_);
		HANDLE_SC(input_files_only);
		HANDLE_SC(single_quoted_string);
		HANDLE_SC(start_condition_count);
#undef HANDLE_SC
	}
}

static void print_start_condition_state(void)
{
	fprintf(stderr, "%s\n", start_condition_name(YY_START));
	if (yy_start_stack && yy_start_stack_ptr > 0)
	{
		for (int i = yy_start_stack_ptr; i --> 0;)
		{
			fprintf(stderr, "\t%s\n", start_condition_name(yy_start_stack[i]));
		}
	}
}
