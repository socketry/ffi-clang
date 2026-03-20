# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Garry Marshall.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2014, by Masahiro Sano.

require_relative "file"

module FFI
	module Clang
		module Lib
			# FFI struct representing a source location in libclang.
			# @private
			class CXSourceLocation < FFI::Struct
				layout(
					:ptr_data, [:pointer, 2],
					:int_data, :uint
				)
			end
			
			attach_function :get_null_location, :clang_getNullLocation, [], CXSourceLocation.by_value
			attach_function :equal_locations, :clang_equalLocations,  [CXSourceLocation.by_value, CXSourceLocation.by_value], :uint
			
			attach_function :get_location, :clang_getLocation, [:CXTranslationUnit, :CXFile, :uint, :uint], CXSourceLocation.by_value
			attach_function :get_location_offset, :clang_getLocationForOffset, [:CXTranslationUnit, :CXFile, :uint], CXSourceLocation.by_value
			attach_function :get_expansion_location, :clang_getExpansionLocation, [CXSourceLocation.by_value, :pointer, :pointer, :pointer, :pointer], :void
			attach_function :get_presumed_location, :clang_getPresumedLocation, [CXSourceLocation.by_value, :pointer, :pointer, :pointer], :void
			
			attach_function :get_file_location, :clang_getFileLocation, [CXSourceLocation.by_value, :pointer, :pointer, :pointer, :pointer], :void
			
			attach_function :get_spelling_location, :clang_getSpellingLocation, [CXSourceLocation.by_value, :pointer, :pointer, :pointer, :pointer], :void
			
			attach_function :location_in_system_header, :clang_Location_isInSystemHeader, [CXSourceLocation.by_value], :int
			attach_function :location_is_from_main_file, :clang_Location_isFromMainFile, [CXSourceLocation.by_value], :int
		end
	end
end
