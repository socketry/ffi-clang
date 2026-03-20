# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.

require_relative "lib/file"
require_relative "lib/inclusions"
require_relative "cursor"
require_relative "source_range"
require_relative "error"

module FFI
	module Clang
		# Represents a file in a translation unit.
		class File < Pointer
			# @attribute [TranslationUnit] The translation unit this file belongs to.
			attr_reader :translation_unit
			
			# Initialize a file with a pointer and translation unit.
			# @parameter pointer [FFI::Pointer] The file pointer.
			# @parameter translation_unit [TranslationUnit] The parent translation unit.
			def initialize(pointer, translation_unit)
				super pointer
				@translation_unit = translation_unit
				
				pointer = MemoryPointer.new(Lib::CXFileUniqueID)
				Lib.get_file_unique_id(self, pointer)
				@unique_id = Lib::CXFileUniqueID.new(pointer)
			end
			
			# Get the file name as a string.
			# @returns [String] The file name.
			def to_s
				name
			end
			
			# Get the file name.
			# @returns [String] The file name.
			def name
				Lib.extract_string Lib.get_file_name(self)
			end
			
			# Get the loaded contents of this file from libclang.
			# @returns [String | Nil] The file contents, or `nil` if the file is not loaded.
			def contents
				size_pointer = MemoryPointer.new(:size_t)
				contents_pointer = Lib.get_file_contents(@translation_unit, self, size_pointer)
				return nil if contents_pointer.null?
				
				contents_pointer.read_string_length(size_pointer.read(:size_t))
			end
			
			# Get the file modification time.
			# @returns [Time] The file modification time.
			def time
				Time.at(Lib.get_file_time(self))
			end
			
			# Check if the file has include guards.
			# @returns [Boolean] True if the file is include guarded.
			def include_guarded?
				Lib.is_file_multiple_include_guarded(@translation_unit, self) != 0
			end
			
			# Get the device ID of the file.
			# @returns [Integer] The device ID.
			def device
				@unique_id[:device]
			end
			
			# Get the inode number of the file.
			# @returns [Integer] The inode number.
			def inode
				@unique_id[:inode]
			end
			
			# Get the modification time from the unique ID.
			# @returns [Time] The modification time.
			def modification
				Time.at(@unique_id[:modification])
			end
			
			# Get the real (resolved) path name of this file.
			# @returns [String] The real path name.
			def real_path_name
				Lib.extract_string Lib.file_try_get_real_path_name(self)
			end
			
			# Check if this file is equal to another file.
			# @parameter other [File] The other file to compare.
			# @returns [Boolean] True if the files are equal.
			def ==(other)
				Lib.file_is_equal(self, other) != 0
			end
			
			# Iterate over include directives in this file.
			# The translation unit must have been parsed with `:detailed_preprocessing_record`.
			# @yields {|cursor, range| ...} Each include directive cursor and its source range.
			# 	@parameter cursor [Cursor] The include directive cursor.
			# 	@parameter range [SourceRange] The source range of the include directive.
			# @returns [Enumerator] If no block is given.
			# @raises [Error] If libclang cannot query includes for this file.
			def find_includes(&block)
				return to_enum(__method__) unless block_given?
				
				visit_adapter = Proc.new do |unused, cxcursor, cxsource_range|
					cursor = Cursor.new(cxcursor, @translation_unit)
					result = block.call(cursor, SourceRange.new(cxsource_range))
					result == :break ? :break : :continue
				end
				
				visitor = FFI::Clang::Lib::CXCursorAndRangeVisitor.new
				visitor[:visit] = visit_adapter
				
				result = Lib.find_includes_in_file(@translation_unit, self, visitor)
				raise Error, "error finding includes in file: #{name.inspect}" if result == :invalid
				
				self
			end
		end
	end
end
