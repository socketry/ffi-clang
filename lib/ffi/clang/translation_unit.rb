# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Garry Marshall.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014, by Greg Hazel.
# Copyright, 2019, by Michael Metivier.
# Copyright, 2022, by Motonori Iwamuro.

require_relative "lib/translation_unit"
require_relative "lib/inclusions"
require_relative "cursor"
require_relative "file"
require_relative "token"
require_relative "error"

module FFI
	module Clang
		# Represents a single translation unit (a compiled source file with its dependencies).
		class TranslationUnit < AutoPointer
			# Initialize a translation unit with a pointer and parent index.
			# @parameter pointer [FFI::Pointer] The translation unit pointer.
			# @parameter index [Index] The parent index that created this translation unit.
			def initialize(pointer, index)
				super pointer
				@index = index
			end
			
			# Release the translation unit pointer.
			# @parameter pointer [FFI::Pointer] The translation unit pointer to release.
			def self.release(pointer)
				Lib.dispose_translation_unit(pointer)
			end
			
			# Get the default editing translation unit options.
			# @returns [Array(Symbol)] The default editing options.
			def self.default_editing_translation_unit_options
				bitmask = Lib.default_editing_translation_unit_options
				Lib.opts_from Lib::TranslationUnitFlags, bitmask
			end
			
			# Get the default save options for this translation unit.
			# @returns [Array(Symbol)] The default save options.
			def default_save_options
				bitmask = Lib.default_save_options(self)
				Lib.opts_from Lib::SaveTranslationUnitFlags, bitmask
			end
			
			# Save the translation unit to a file.
			# @parameter filename [String] The path where the translation unit should be saved.
			# @parameter opts [Array(Symbol) | Nil] Save options, or `nil` for libclang defaults.
			# @raises [Error] If saving fails.
			def save(filename, opts = nil)
				option_bitmask =
					if opts.nil?
						Lib.default_save_options(self)
					else
						Lib.bitmask_from(Lib::SaveTranslationUnitFlags, opts)
					end
				
				ret = Lib.save_translation_unit(self, filename, option_bitmask)
				sym = Lib::SaveError[ret]
				raise Error, "unknown return values: #{ret} #{sym.inspect}" unless sym
				raise Error, "save error: #{sym.inspect}, filename: #{filename}" if sym != :none
			end
			
			# Get the default reparse options for this translation unit.
			# @returns [Array(Symbol)] The default reparse options.
			def default_reparse_options
				bitmask = Lib.default_reparse_options(self)
				Lib.opts_from Lib::ReparseFlags, bitmask
			end
			
			# Reparse the translation unit with updated file contents.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter opts [Hash] Reparse options.
			# @raises [Error] If reparsing fails.
			def reparse(unsaved = [], opts = {})
				unsaved_files = UnsavedFile.unsaved_pointer_from(unsaved)
				if Lib.reparse_translation_unit(self, unsaved.size, unsaved_files, 0) != 0
					raise Error, "reparse error"
				end
			end
			
			# Get all diagnostics for this translation unit.
			# @returns [Array(Diagnostic)] Array of diagnostics.
			def diagnostics
				n = Lib.get_num_diagnostics(self)
				
				n.times.map do |i|
					Diagnostic.new(self, Lib.get_diagnostic(self, i))
				end
			end
			
			# Get a cursor for the translation unit or at a specific location.
			# @parameter location [SourceLocation | Nil] The location for the cursor, or `nil` for the root cursor.
			# @returns [Cursor] The cursor at the specified location or the root cursor.
			def cursor(location = nil)
				if location.nil?
					Cursor.new Lib.get_translation_unit_cursor(self), self
				else
					Cursor.new Lib.get_cursor(self, location.location), self
				end
			end
			
			# Get a source location by file, line, and column.
			# @parameter file [File] The file object.
			# @parameter line [Integer] The line number (1-indexed).
			# @parameter column [Integer] The column number (1-indexed).
			# @returns [ExpansionLocation] The source location.
			def location(file, line, column)
				ExpansionLocation.new Lib.get_location(self, file, line, column)
			end
			
			# Get a source location by file and byte offset.
			# @parameter file [File] The file object.
			# @parameter offset [Integer] The byte offset from the start of the file.
			# @returns [ExpansionLocation] The source location.
			def location_offset(file, offset)
				ExpansionLocation.new Lib.get_location_offset(self, file, offset)
			end
			
			# Get a file object from this translation unit.
			# @parameter file_name [String | Nil] The file name, or `nil` to get the main file.
			# @returns [File] The file object.
			def file(file_name = nil)
				if file_name.nil?
					File.new(Lib.get_file(self, spelling), self)
				else
					File.new(Lib.get_file(self, file_name), self)
				end
			end
			
			# Get the spelling (filename) of this translation unit.
			# @returns [String] The filename of the translation unit.
			def spelling
				Lib.extract_string Lib.get_translation_unit_spelling(self)
			end
			
			# Get resource usage information for this translation unit.
			# @returns [ResourceUsage] Resource usage statistics.
			def resource_usage
				FFI::Clang::TranslationUnit::ResourceUsage.new Lib.resource_usage(self)
			end
			
			# Tokenize a source range.
			# @parameter range [SourceRange] The source range to tokenize.
			# @returns [Tokens] Collection of tokens in the range.
			def tokenize(range)
				token_ptr = MemoryPointer.new :pointer
				uint_ptr = MemoryPointer.new :uint
				Lib.tokenize(self, range.range, token_ptr, uint_ptr)
				Tokens.new(token_ptr.get_pointer(0), uint_ptr.get_uint(0), self)
			end
			
			# Perform code completion at a specific location.
			# @parameter source_file [String] The path to the source file.
			# @parameter line [Integer] The line number for code completion.
			# @parameter column [Integer] The column number for code completion.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter opts [Array(Symbol) | Nil] Code completion options, or `nil` for defaults.
			# @returns [CodeCompletion::Results] The code completion results.
			def code_complete(source_file, line, column, unsaved = [], opts = nil)
				opts = CodeCompletion.default_code_completion_options if opts.nil?
				unsaved_files = UnsavedFile.unsaved_pointer_from(unsaved)
				option_bitmask = Lib.bitmask_from(Lib::CodeCompleteFlags, opts)
				ptr = Lib.code_complete_at(self, source_file, line, column, unsaved_files, unsaved.length, option_bitmask)
				CodeCompletion::Results.new ptr, self
			end
			
			# Iterate over all file inclusions in this translation unit.
			# @yields {|file, locations| ...} Each inclusion with its file path and stack.
			# 	@parameter file [String] The included file path.
			# 	@parameter locations [Array(SourceLocation)] The inclusion stack.
			def inclusions(&block)
				adapter = Proc.new do |included_file, inclusion_stack, include_len, unused|
					file = Lib.extract_string Lib.get_file_name(included_file)
					cur_ptr = inclusion_stack
					inclusions = []
					include_len.times {inclusions << SourceLocation.new(Lib::CXSourceLocation.new(cur_ptr))
																								cur_ptr += Lib::CXSourceLocation.size
					}
					block.call file, inclusions
				end
				
				Lib.get_inclusions(self, adapter, nil)
			end
			
			# Get the target triple for this translation unit.
			# @returns [String] The target triple string.
			def target_triple
				target_info = Lib.get_translation_unit_target_info(self)
				triple = Lib.extract_string Lib.target_info_get_triple(target_info)
				Lib.target_info_dispose(target_info)
				triple
			end
			
			# Get the pointer width for the target of this translation unit.
			# @returns [Integer] The pointer width in bits.
			def target_pointer_width
				target_info = Lib.get_translation_unit_target_info(self)
				width = Lib.target_info_get_pointer_width(target_info)
				Lib.target_info_dispose(target_info)
				width
			end
			
			# Suspend this translation unit to free memory.
			# @returns [Boolean] True if the translation unit was successfully suspended.
			def suspend
				Lib.suspend_translation_unit(self) != 0
			end
			
			# Represents resource usage statistics for a translation unit.
			class ResourceUsage < AutoPointer
				# Initialize resource usage from a CXTUResourceUsage structure.
				# @parameter resource_usage [Lib::CXTUResourceUsage] The resource usage structure.
				def initialize(resource_usage)
					# CXResourceUsage is returned by value and should be freed explicitly.
					# Get FFI::pointer of the data so that the data is handled by AutoPointer.
					pointer = FFI::Pointer.new(resource_usage.to_ptr)
					super(pointer)
					@resource_usage = resource_usage
				end
				
				# Release the resource usage pointer.
				# @parameter pointer [FFI::Pointer] The resource usage pointer to release.
				def self.release(pointer)
					# clang_disposeCXTUResourceUsage requires value type, so create it by pointer
					Lib.dispose_resource_usage(Lib::CXTUResourceUsage.new(pointer))
				end
				
				# Get the name of a resource usage kind.
				# @parameter kind [Symbol] The resource usage kind.
				# @returns [String] The name of the resource kind.
				def self.name(kind)
					Lib.resource_usage_name(kind)
				end
				
				# Get all resource usage entries.
				# @returns [Array(Lib::CXTUResourceUsageEntry)] The resource usage entries.
				def entries
					ary = []
					ptr = @resource_usage[:entries]
					@resource_usage[:numEntries].times {ary << Lib::CXTUResourceUsageEntry.new(ptr)
																																									ptr += Lib::CXTUResourceUsageEntry.size
					}
					ary
				end
			end
		end
	end
end
