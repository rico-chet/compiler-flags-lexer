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

#ifndef COMPILER_FLAGS_H
#define COMPILER_FLAGS_H

#include <stdbool.h>
#include <stddef.h>

bool compiler_flags_defines(const char* restrict text,
                            char* restrict const result,
                            const size_t         result_size);

bool compiler_flags_includes(const char* restrict text,
                             char* restrict const result,
                             const size_t         result_size);

#endif // COMPILER_FLAGS_H
