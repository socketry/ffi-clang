# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2014, by Masahiro Sano.

require_relative "string"
require_relative "translation_unit"

module FFI
	module Clang
		module Lib
			# FFI struct representing an unsaved file for parsing.
			# @private
			class CXUnsavedFile < FFI::Struct
				layout(
					:filename, :pointer,
					:contents, :pointer,
					:length, :ulong
				)
			end
			
			# FFI struct representing a unique file identifier.
			# @private
			class CXFileUniqueID < FFI::Struct
				layout(
					:device, :ulong_long,
					:inode, :ulong_long,
					:modification, :ulong_long
				)
			end
			
			typedef :pointer, :CXFile
			
			attach_function :get_file, :clang_getFile, [:CXTranslationUnit, :string], :CXFile
			attach_function :get_file_name, :clang_getFileName, [:CXFile], CXString.by_value
			attach_function :get_file_time, :clang_getFileTime, [:CXFile], :time_t
			attach_function :is_file_multiple_include_guarded, :clang_isFileMultipleIncludeGuarded, [:CXTranslationUnit, :CXFile], :uint
			
			attach_function :get_file_unique_id, :clang_getFileUniqueID, [:CXFile, :pointer], :int
			
			attach_function :file_is_equal, :clang_File_isEqual, [:CXFile, :CXFile], :int
			attach_function :file_try_get_real_path_name, :clang_File_tryGetRealPathName, [:CXFile], CXString.by_value
		end
	end
end
