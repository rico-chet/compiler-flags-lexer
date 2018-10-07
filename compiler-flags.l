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
#include <assert.h>
#include <limits.h>
#include <string.h>

enum mode_t
{
	mode_defines,
	mode_includes,
	mode_count
};

/* `struct yyguts_t* yyg` is a local vatiable in yylex() and
 * it holds the entire state of the reentrant scanner.
 * Its opaque name is `yyscan_t yyscanner`.
*/
struct yyguts_t;

/* the `yyextra_r` field in `struct yyguts_t` */
struct compiler_flags_extra_t
{
	char* restrict result;
	size_t         result_size;
	enum mode_t    mode;
};

#define YY_DECL bool yylex(yyscan_t yyscanner)

#define yyterminate() return false

}

%option extra-type="struct compiler_flags_extra_t *"
%option reentrant

%{

// constants
const static bool g_trace = false;

// function declarations
static bool yylex(yyscan_t yyscanner);

static void begin(int start_condition, struct yyguts_t* yyg);
static void pop_state(struct yyguts_t* yyg);
static void print_start_condition_state(struct yyguts_t* yyg);
static void push_state(int new_state, struct yyguts_t* yyg);
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

- { push_state(flag, yyg); }
<flag>{
	D { pop_state(yyg); push_state(define_name, yyg); }
	I { pop_state(yyg); push_state(include, yyg); }
	[[:blank:]] { /* stdin as input */ pop_state(yyg); }
	-[[:blank:]] {
		pop_state(yyg);
		push_state(input_files_only, yyg);
	}
	. {
		pop_state(yyg);
		/* skip over other flags*/
		push_state(etc_flag, yyg);
	}
}

<define_value,include,etc_flag,input_files_only,INITIAL>{
	['"] {
		if (YY_START == INITIAL || YY_START == input_files_only)
		{
			push_state(input_file_, yyg);
		}
		push_state(yytext[0] == '"' ? double_quoted_string : single_quoted_string,
		           yyg);
	}
}

[^'"[:blank:]-] {
	push_state(input_file_, yyg);
	yymore();
}

<input_files_only>[^'"] {
	push_state(input_file_, yyg);
	yymore();
}

<input_file_>[^[:blank:]]+ { /* no according mode yet */ }

<define_name>{
	[[:alpha:]_][[:alnum:]_]* {
		if (yyextra->mode == mode_defines)
		{
			if (!append_to_buffer(yytext, yyleng, &yyextra->result,
			                      &yyextra->result_size))
				yyterminate();
			if (!append_to_buffer("\n", 1, &yyextra->result, &yyextra->result_size))
				yyterminate();
		}
	}
	= { pop_state(yyg); push_state(define_value, yyg); }
	[ ] { pop_state(yyg); }
}

<include>[^[:blank:]'"]+ {
	if (yyextra->mode == mode_includes)
	{
		if (!append_to_buffer(yytext, yyleng, &yyextra->result,
		                      &yyextra->result_size))
			yyterminate();
		if (!append_to_buffer("\n", 1, &yyextra->result, &yyextra->result_size))
			yyterminate();
	}
	pop_state(yyg);
}

<double_quoted_string>{
	\\\" {
		if (yy_top_state(yyg) == define_value && yyextra->mode == mode_defines
		    || yy_top_state(yyg) == include && yyextra->mode == mode_includes)
		{
			if (!append_to_buffer(yytext, yyleng - 2, &yyextra->result,
			                      &yyextra->result_size))
				yyterminate();
			if (!append_to_buffer("\"", 1, &yyextra->result, &yyextra->result_size))
				yyterminate();
		}
	}

	\" {
		pop_state(yyg);
		if (YY_START == define_value && yyextra->mode == mode_defines
		    || YY_START == include && yyextra->mode == mode_includes)
		{
			if (!append_to_buffer(yytext, yyleng - 1, &yyextra->result,
			                      &yyextra->result_size))
				yyterminate();
			if (!append_to_buffer("\n", 1, &yyextra->result, &yyextra->result_size))
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
		pop_state(yyg);
	}

	. { yymore(); }
}

<single_quoted_string>{
	\\\' {
		if (yy_top_state(yyg) == define_value && yyextra->mode == mode_defines
		    || yy_top_state(yyg) == include && yyextra->mode == mode_includes)
		{
			if (!append_to_buffer(yytext, yyleng - 2, &yyextra->result,
			                      &yyextra->result_size))
				yyterminate();
			if (!append_to_buffer("'", 1, &yyextra->result, &yyextra->result_size))
				yyterminate();
		}
	}

	\' {
		pop_state(yyg);
		if (YY_START == define_value && yyextra->mode == mode_defines)
		{
			if (!append_to_buffer(yytext, yyleng - 1, &yyextra->result,
			                      &yyextra->result_size))
				yyterminate();
			if (!append_to_buffer("\n", 1, &yyextra->result, &yyextra->result_size))
				yyterminate();
		}
		else if (YY_START == include && yyextra->mode == mode_includes)
		{
			if (!append_to_buffer(yytext, yyleng - 1, &yyextra->result,
			                      &yyextra->result_size))
				yyterminate();
			if (!append_to_buffer("\n", 1, &yyextra->result, &yyextra->result_size))
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
		pop_state(yyg);
	}

	. { yymore(); }
}

<input_files_only,INITIAL>[[:blank:]]+ { /* skip to next flag or input */ }
<<EOF>> { return true; }
%%

#undef yywrap
int yywrap(yyscan_t scanner)
{
	return 1;
}

bool compiler_flags_defines(const char* restrict const text,
                            char* restrict const result,
                            const size_t         result_size)
{
	if (!(text && result && 0 < result_size))
		return false;

	struct compiler_flags_extra_t extra;
	extra.mode        = mode_defines;
	extra.result      = result;
	extra.result_size = result_size;

	yyscan_t scanner;
	if (yylex_init_extra(&extra, &scanner) != 0)
		return false;

	YY_BUFFER_STATE buffer = yy_scan_string(text, scanner);
	const bool      good   = yylex(scanner);
	yy_delete_buffer(buffer, scanner);
	if (yylex_destroy(scanner) != 0)
		return false;

	return good;
}

bool compiler_flags_includes(const char* restrict const text,
                             char* restrict const result,
                             const size_t         result_size)
{
	if (!(text && result && 0 < result_size))
		return false;

	struct compiler_flags_extra_t extra;
	extra.mode        = mode_includes;
	extra.result      = result;
	extra.result_size = result_size;

	yyscan_t scanner;
	if (yylex_init_extra(&extra, &scanner) != 0)
		return false;

	YY_BUFFER_STATE buffer = yy_scan_string(text, scanner);
	const bool      good   = yylex(scanner);
	yy_delete_buffer(buffer, scanner);
	if (yylex_destroy(scanner) != 0)
		return false;

	return good;
}

static void begin(const int new_start_condition, struct yyguts_t* const yyg)
{
	if (g_trace)
	{
		fprintf(stderr,
		        "%s: %s\n",
		        __func__,
		        start_condition_name(new_start_condition));
		print_start_condition_state(yyg);
	}

	BEGIN(new_start_condition);

	if (g_trace)
	{
		print_start_condition_state(yyg);
	}
}

static void push_state(const int new_state, struct yyguts_t* const yyg)
{
	if (g_trace)
	{
		fprintf(stderr, "%s: %s\n", __func__, start_condition_name(new_state));
		print_start_condition_state(yyg);
	}
	yy_push_state(new_state, yyg);

	if (g_trace)

	{
		print_start_condition_state(yyg);
	}
}

static void pop_state(struct yyguts_t* const yyg)
{
	if (g_trace)
	{
		fprintf(stderr, "%s\n", __func__);
		print_start_condition_state(yyg);
	}

	yy_pop_state(yyg);

	if (g_trace)
	{
		print_start_condition_state(yyg);
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

static void print_start_condition_state(struct yyguts_t* const yyg)
{
	if (yyextra && yyg->yy_start_stack && yyg->yy_start_stack_ptr > 0)
	{
		fprintf(stderr, "%s\n", start_condition_name(YY_START));

		for (int i = yyg->yy_start_stack_ptr; i-- > 0;)
		{
			fprintf(stderr, "\t%s\n", start_condition_name(yyg->yy_start_stack[i]));
		}
	}
}
