# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010-2011, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Garry Marshall.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2024, by Charlie Savage.

# Load the shared object:
require_relative "clang/lib"

# Wrappers around C functionality:
require_relative "clang/version"
require_relative "clang/clang_version"
require_relative "clang/index"
require_relative "clang/translation_unit"
require_relative "clang/diagnostic"
require_relative "clang/diagnostic_set"
require_relative "clang/cursor"
require_relative "clang/evaluation"
require_relative "clang/source_location"
require_relative "clang/source_range"
require_relative "clang/unsaved_file"
require_relative "clang/token"
require_relative "clang/code_completion"
require_relative "clang/compilation_database"

require_relative "clang/types/type"
require_relative "clang/types/array"
require_relative "clang/types/elaborated"
require_relative "clang/types/function"
require_relative "clang/types/pointer"
require_relative "clang/types/record"
require_relative "clang/types/type_def"
require_relative "clang/types/vector"
