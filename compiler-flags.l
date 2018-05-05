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

static int min_int(const int a, const int b)
{
    return a < b ? a : b;
}

// function definitions
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

    return true;
}

%}

%x flag
%x define
%x include
%x double_quoted_string
%x single_quoted_string

%%
%{

// first lines of the yylex function

%}

- { BEGIN(flag); }
-D { BEGIN(define); }
-I { BEGIN(include); }
\" { BEGIN(double_quoted_string); }
\' { BEGIN(single_quoted_string); }

<flag>[[:blank:]]           { BEGIN(INITIAL); }
<define>[a-zA-Z0-9]*        {
    if (mode == mode_defines)
    {
        if (!append_to_buffer(yytext, yyleng, &result, &result_size))
            yyterminate();
        if (!append_to_buffer("\n", 1, &result, &result_size))
            yyterminate();
    }
    BEGIN(INITIAL);
}
<include>[a-zA-Z0-9]*       {
    if (mode == mode_includes)
    {
        if (!append_to_buffer(yytext, yyleng, &result, &result_size))
            yyterminate();
        if (!append_to_buffer("\n", 1, &result, &result_size))
            yyterminate();
    }
    BEGIN(INITIAL);
}
<double_quoted_string>\"    { BEGIN(INITIAL); }
<single_quoted_string>\'    { BEGIN(INITIAL); }

[[:blank:]]* { /* skip to next flag */ }
<flag,double_quoted_string,single_quoted_string><<EOF>> { yyterminate(); }
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
