# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Garry Marshall.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2026, by Charlie Savage.

require_relative "source_location"

module FFI
	module Clang
		module Lib
			# FFI struct representing a source range in libclang.
			# @private
			class CXSourceRange < FFI::Struct
				layout(
					:ptr_data, [:pointer, 2],
					:begin_int_data, :uint,
					:end_int_data, :uint
				)
			end
			
			# FFI struct representing a list of source ranges.
			# @private
			class CXSourceRangeList < FFI::Struct
				layout(
					:count, :uint,
					:ranges, :pointer
				)
			end
			
			attach_function :get_null_range, :clang_getNullRange, [], CXSourceRange.by_value
			attach_function :get_range, :clang_getRange, [CXSourceLocation.by_value, CXSourceLocation.by_value], CXSourceRange.by_value
			attach_function :get_range_start, :clang_getRangeStart, [CXSourceRange.by_value], CXSourceLocation.by_value
			attach_function :get_range_end, :clang_getRangeEnd, [CXSourceRange.by_value], CXSourceLocation.by_value
			attach_function :range_is_null, :clang_Range_isNull, [CXSourceRange.by_value], :int
			attach_function :equal_range, :clang_equalRanges, [CXSourceRange.by_value, CXSourceRange.by_value], :uint
			attach_function :dispose_source_range_list, :clang_disposeSourceRangeList, [CXSourceRangeList.by_ref], :void
			attach_function :get_skipped_ranges, :clang_getSkippedRanges, [:CXTranslationUnit, :CXFile], CXSourceRangeList.by_ref
			attach_function :get_all_skipped_ranges, :clang_getAllSkippedRanges, [:CXTranslationUnit], CXSourceRangeList.by_ref
		end
	end
end
