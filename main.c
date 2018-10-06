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

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "compiler-flags.h"

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

int main(const int argc, const char* const argv[])
{
	if (argc <= 2)
		return 1;

	const char* const compiler_line = argv[2];
	const size_t      result_size   = (size_t)strlen(compiler_line);
	char* restrict const result     = calloc(1, result_size);

	const char param_defines[]  = "--defines";
	if (strncmp(argv[1], param_defines, ARRAY_SIZE(param_defines) - 1) == 0)
	{
		if (!compiler_flags_defines(compiler_line, result, result_size))
		{
			free(result);
			puts("bad");
			return 1;
		}
		const size_t size_of_mode_param = strlen(argv[1]);
		if (ARRAY_SIZE(param_defines) - 1 + ARRAY_SIZE("-r.") - 1
		        <= size_of_mode_param
		    && strncmp(&(argv[1][ARRAY_SIZE(param_defines) - 1]),
		               "-r",
		               ARRAY_SIZE("-r") - 1)
		           == 0)
		{
			// reentrant mode
			const int in_reentrance_count = atoi(
			    &(argv[1][ARRAY_SIZE(param_defines) - 1 + ARRAY_SIZE("-r") - 1]));
			for (int i = 0; i < in_reentrance_count - 1; i++)
			{
				printf("%s", result);
				if (!compiler_flags_defines(compiler_line, result, result_size))
				{
					free(result);
					puts("bad");
					return 1;
				}
			}
		}
	}
	else if (strcmp(argv[1], "--includes") == 0)
	{
		if (!compiler_flags_includes(compiler_line, result, result_size))
		{
			free(result);
			puts("bad");
			return 1;
		}
	}
	else
	{
		free(result);
		return 1;
	}

	printf("%s", result);
	free(result);
	return 0;
}
