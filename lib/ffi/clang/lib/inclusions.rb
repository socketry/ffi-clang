# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Greg Hazel.
# Copyright, 2014-2025, by Samuel Williams.

require_relative "file"
require_relative "source_location"
require_relative "cursor"

module FFI
	module Clang
		module Lib
			# Source code inclusions:
			callback :visit_inclusion_function, [:CXFile, :pointer, :uint, :pointer], :void
			attach_function :get_inclusions, :clang_getInclusions, [:CXTranslationUnit, :visit_inclusion_function, :pointer], :void
			attach_function :find_includes_in_file, :clang_findIncludesInFile, [:CXTranslationUnit, :CXFile, CXCursorAndRangeVisitor.by_value], :result
		end
	end
end
