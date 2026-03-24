# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Garry Marshall.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2024-2026, by Charlie Savage.

require_relative "lib/source_location"
require_relative "lib/file"

module FFI
	module Clang
		# Represents a location in source code.
		# This base class provides common functionality for source locations,
		# with specific subclasses for different types of location information.
		class SourceLocation
			include Comparable
			
			# Get a null source location.
			# @returns [ExpansionLocation] A null location that can be used for comparisons.
			def self.null_location
				ExpansionLocation.new Lib.get_null_location
			end
			
			# @attribute [r] location
			# 	@returns [FFI::Pointer] The underlying location pointer.
			attr_reader :location
			
			# Create a new source location.
			# @parameter location [FFI::Pointer] The low-level location handle.
			def initialize(location)
				@location = location
			end
			
			# Check if this location is in a system header.
			# @returns [Boolean] True if the location is in a system header file.
			def in_system_header?
				Lib.location_in_system_header(@location) != 0
			end
			
			# Check if this location is from the main file.
			# @returns [Boolean] True if the location is from the main translation unit file.
			def from_main_file?
				Lib.location_is_from_main_file(@location) != 0
			end
			
			# Check if this location is null.
			# @returns [Boolean] True if this is a null location.
			def null?
				Lib.equal_locations(@location, Lib.get_null_location) != 0
			end
			
			# Compare this location with another for equality.
			# @parameter other [SourceLocation] The other location to compare.
			# @returns [Boolean] True if the locations are equal.
			def ==(other)
				Lib.equal_locations(@location, other.location) != 0
			end
			
			# Compare this location with another for ordering.
			# Returns nil for null locations or locations from different translation units,
			# which causes Comparable operators (<, >, etc.) to raise ArgumentError.
			# @parameter other [SourceLocation] The other location to compare.
			# @returns [Integer | Nil] -1, 0, or 1 for ordering, or nil if not comparable.
			def <=>(other)
				return nil unless other.is_a?(SourceLocation)
				return 0 if Lib.equal_locations(@location, other.location) != 0
				return nil if null? || other.null?
				return -1 if Lib.is_before_in_translation_unit(@location, other.location) != 0
				return 1 if Lib.is_before_in_translation_unit(other.location, @location) != 0
				
				nil
			end
		end
		
		# Represents the expansion location of a macro.
		# This provides the location where a macro was expanded, including file, line, column, and byte offset.
		class ExpansionLocation < SourceLocation
			# @attribute [r] file
			# 	@returns [String] The file path.
			# @attribute [r] line
			# 	@returns [Integer] The line number.
			# @attribute [r] column
			# 	@returns [Integer] The column number.
			# @attribute [r] offset
			# 	@returns [Integer] The byte offset in the file.
			attr_reader :file, :line, :column, :offset
			
			# Create a new expansion location and extract its components.
			# @parameter location [FFI::Pointer] The low-level location handle.
			def initialize(location)
				super(location)
				
				cxfile = MemoryPointer.new :pointer
				line   = MemoryPointer.new :uint
				column = MemoryPointer.new :uint
				offset = MemoryPointer.new :uint
				
				Lib::get_expansion_location(@location, cxfile, line, column, offset)
				
				@file = Lib.extract_string Lib.get_file_name(cxfile.read_pointer)
				@line = line.get_uint(0)
				@column = column.get_uint(0)
				@offset = offset.get_uint(0)
			end
			
			# Get a string representation of this location.
			# @returns [String] The location in format "file:line:column:offset".
			def as_string
				"#{@file}:#{@line}:#{@column}:#{@offset}"
			end
			
			# Get a detailed string representation.
			# @returns [String] A string describing this expansion location.
			def to_s
				"ExpansionLocation <#{self.as_string}>"
			end
		end
		
		# Represents a presumed location in source code.
		# This is the location that appears to the user after macro expansion and #line directives.
		class PresumedLocation < SourceLocation
			# @attribute [r] filename
			# 	@returns [String] The presumed filename.
			# @attribute [r] line
			# 	@returns [Integer] The presumed line number.
			# @attribute [r] column
			# 	@returns [Integer] The presumed column number.
			attr_reader :filename, :line, :column
			
			# Create a new presumed location and extract its components.
			# @parameter location [FFI::Pointer] The low-level location handle.
			def initialize(location)
				super(location)
				
				cxstring = MemoryPointer.new Lib::CXString
				line = MemoryPointer.new :uint
				column = MemoryPointer.new :uint
				
				Lib::get_presumed_location(@location, cxstring, line, column)
				
				@filename = Lib.extract_string cxstring
				@line = line.get_uint(0)
				@column = column.get_uint(0)
			end
			
			# Get a string representation of this location.
			# @returns [String] The location in format "filename:line:column".
			def as_string
				"#{@filename}:#{@line}:#{@column}"
			end
			
			# Get a detailed string representation.
			# @returns [String] A string describing this presumed location.
			def to_s
				"PresumedLocation <#{self.as_string}>"
			end
		end
		
		# Represents the spelling location of a token in source code.
		# This is the actual location where the token was written in the source file.
		class SpellingLocation < SourceLocation
			# @attribute [r] file
			# 	@returns [String] The file path.
			# @attribute [r] line
			# 	@returns [Integer] The line number.
			# @attribute [r] column
			# 	@returns [Integer] The column number.
			# @attribute [r] offset
			# 	@returns [Integer] The byte offset in the file.
			attr_reader :file, :line, :column, :offset
			
			# Create a new spelling location and extract its components.
			# @parameter location [FFI::Pointer] The low-level location handle.
			def initialize(location)
				super(location)
				
				cxfile = MemoryPointer.new :pointer
				line   = MemoryPointer.new :uint
				column = MemoryPointer.new :uint
				offset = MemoryPointer.new :uint
				
				Lib::get_spelling_location(@location, cxfile, line, column, offset)
				
				@file = Lib.extract_string Lib.get_file_name(cxfile.read_pointer)
				@line = line.get_uint(0)
				@column = column.get_uint(0)
				@offset = offset.get_uint(0)
			end
			
			# Get a string representation of this location.
			# @returns [String] The location in format "file:line:column:offset".
			def as_string
				"#{@file}:#{@line}:#{@column}:#{@offset}"
			end
			
			# Get a detailed string representation.
			# @returns [String] A string describing this spelling location.
			def to_s
				"SpellingLocation <#{self.as_string}>"
			end
		end
		
		# Represents a file location in source code.
		# This provides the physical location in the file system where code appears.
		class FileLocation < SourceLocation
			# @attribute [r] file
			# 	@returns [String] The file path.
			# @attribute [r] line
			# 	@returns [Integer] The line number.
			# @attribute [r] column
			# 	@returns [Integer] The column number.
			# @attribute [r] offset
			# 	@returns [Integer] The byte offset in the file.
			attr_reader :file, :line, :column, :offset
			
			# Create a new file location and extract its components.
			# @parameter location [FFI::Pointer] The low-level location handle.
			def initialize(location)
				super(location)
				
				cxfile = MemoryPointer.new :pointer
				line   = MemoryPointer.new :uint
				column = MemoryPointer.new :uint
				offset = MemoryPointer.new :uint
				
				Lib::get_file_location(@location, cxfile, line, column, offset)
				
				@file = Lib.extract_string Lib.get_file_name(cxfile.read_pointer)
				@line = line.get_uint(0)
				@column = column.get_uint(0)
				@offset = offset.get_uint(0)
			end
			
			# Get a string representation of this location.
			# @returns [String] The location in format "file:line:column:offset".
			def as_string
				"#{@file}:#{@line}:#{@column}:#{@offset}"
			end
			
			# Get a detailed string representation.
			# @returns [String] A string describing this file location.
			def to_s
				"FileLocation <#{self.as_string}>"
			end
		end
	end
end
