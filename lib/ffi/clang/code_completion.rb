# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2023-2026, by Charlie Savage.

require_relative "lib/code_completion"

module FFI
	module Clang
		# @namespace
		class CodeCompletion
			# Get the default code completion options.
			# @returns [Array(Symbol)] The default options.
			def self.default_code_completion_options
				Lib.opts_from(Lib::CodeCompleteFlags, Lib.default_code_completion_options)
			end
			
			# Represents code completion results.
			class Results < FFI::AutoPointer
				include Enumerable
				
				# @attribute [r] size
				# 	@returns [Integer] The number of completion results.
				attr_reader :size
				
				# @attribute [r] results
				# 	@returns [Array(Result)] The array of completion results.
				attr_reader :results
				
				# @attribute [r] code_complete_results
				# 	@returns [Lib::CXCodeCompleteResults] The underlying results structure.
				# @private
				attr_reader :code_complete_results
				
				# Initialize code completion results.
				# @parameter code_complete_results [Lib::CXCodeCompleteResults] The completion results structure.
				# @parameter translation_unit [TranslationUnit] The parent translation unit.
				def initialize(code_complete_results, translation_unit)
					super code_complete_results.pointer
					@translation_unit = translation_unit
					@code_complete_results = code_complete_results
					initialize_results
				end
				
				# Release the completion results pointer.
				# @parameter pointer [FFI::Pointer] The pointer to release.
				def self.release(pointer)
					results = Lib::CXCodeCompleteResults.new(pointer)
					Lib.dispose_code_complete_results(results)
				end
				
				# Iterate over each completion result.
				# @yields {|result| ...} Each completion result.
				# 	@parameter result [Result] The completion result.
				# @returns [Enumerator] If no block is given.
				def each(&block)
					return to_enum(__method__) unless block_given?
					
					@results.each(&block)
				end
				
				# Get the number of diagnostics.
				# @returns [Integer] The number of diagnostics.
				def num_diagnostics
					Lib.get_code_complete_get_num_diagnostics(@code_complete_results)
				end
				
				# Get a diagnostic by index.
				# @parameter i [Integer] The diagnostic index.
				# @returns [Diagnostic] The diagnostic.
				def diagnostic(i)
					Diagnostic.new(@translation_unit, Lib.get_code_complete_get_diagnostic(@code_complete_results, i))
				end
				
				# Get all diagnostics.
				# @returns [Array(Diagnostic)] Array of diagnostics.
				def diagnostics
					num_diagnostics.times.map do |i|
						Diagnostic.new(@translation_unit, Lib.get_code_complete_get_diagnostic(@code_complete_results, i))
					end
				end
				
				# Get the completion contexts.
				# @returns [Array(Symbol)] The completion contexts.
				def contexts
					Lib.opts_from Lib::CompletionContext, Lib.get_code_complete_get_contexts(@code_complete_results)
				end
				
				# Get the USR of the container.
				# @returns [String] The container USR.
				def container_usr
					Lib.extract_string Lib.get_code_complete_get_container_usr(@code_complete_results)
				end
				
				# Get the kind of the container.
				# @returns [Symbol] The container kind.
				def container_kind
					is_incomplete = MemoryPointer.new :uint
					Lib.get_code_complete_get_container_kind(@code_complete_results, is_incomplete)
				end
				
				# Check if the results are incomplete.
				# @returns [Boolean] True if results are incomplete.
				def incomplete?
					is_incomplete = MemoryPointer.new :uint
					Lib.get_code_complete_get_container_kind(@code_complete_results, is_incomplete)
					is_incomplete.read_uint != 0
				end
				
				# Get the Objective-C selector.
				# @returns [String] The Objective-C selector.
				def objc_selector
					Lib.extract_string Lib.get_code_complete_get_objc_selector(@code_complete_results)
				end
				
				# Sort the completion results in place.
				def sort!
					Lib.sort_code_completion_results(@code_complete_results[:results], @code_complete_results[:num])
					initialize_results
				end
				
				# Get a string representation of the results.
				# @returns [String] The results as a string.
				def inspect
					@results.inspect
				end
				
				private
				
				# @private
				def initialize_results
					@size = @code_complete_results[:num]
					cur_ptr = @code_complete_results[:results]
					@results = []
					@size.times do |i|
						completion_result = Lib::CXCompletionResult.new(cur_ptr)
						@results << Result.new(completion_result, self, i)
						cur_ptr += Lib::CXCompletionResult.size
					end
				end
			end
			
			# Represents a single code completion result.
			class Result
				# Initialize a completion result.
				# @parameter result [Lib::CXCompletionResult] The completion result structure.
				# @parameter owner [Results | Nil] The owning Results object (prevents GC of the parent allocation).
				# @parameter index [Integer | Nil] The index of this result in the parent.
				def initialize(result, owner = nil, index = nil)
					@result = result
					@owner = owner
					@index = index
				end
				
				# Get the kind of completion.
				# @returns [Symbol] The completion kind.
				def kind
					@result[:kind]
				end
				
				# Get the completion string.
				# @returns [CodeCompletion::String] The completion string.
				def string
					CodeCompletion::String.new @result[:string]
				end
				
				# Get the number of fix-its required before this completion can be applied.
				# @returns [Integer] The number of fix-its.
				def num_fix_its
					return 0 unless @owner
					
					Lib.get_completion_num_fix_its(@owner.code_complete_results, @index)
				end
				
				# Get all fix-its for this completion result.
				# @returns [Array(FixIt)] The fix-its.
				def fix_its
					num_fix_its.times.map do |i|
						range_ptr = MemoryPointer.new(Lib::CXSourceRange, 1)
						text = Lib.extract_string(Lib.get_completion_fix_it(@owner.code_complete_results, @index, i, range_ptr))
						range = SourceRange.new(Lib::CXSourceRange.new(range_ptr))
						FixIt.new(text, range)
					end
				end
				
				# Get a string representation of this result.
				# @returns [String] The result as a string.
				def inspect
					"<#{kind.inspect} = #{string.inspect}>"
				end
			end
			
			# Represents a fix-it that must be applied before a completion can be inserted.
			class FixIt
				# @attribute [r] text
				# 	@returns [String] The replacement text.
				# @attribute [r] range
				# 	@returns [SourceRange] The source range to replace.
				attr_reader :text, :range
				
				# Initialize a fix-it.
				# @parameter text [String] The replacement text.
				# @parameter range [SourceRange] The source range to replace.
				def initialize(text, range)
					@text = text
					@range = range
				end
			end
			
			# Represents a code completion string with chunks.
			class String
				# Initialize a completion string.
				# @parameter ptr [FFI::Pointer] The completion string pointer.
				def initialize(ptr)
					@pointer = ptr
				end
				
				# Get the kind of a chunk.
				# @parameter i [Integer] The chunk index.
				# @returns [Symbol] The chunk kind.
				def chunk_kind(i)
					Lib.get_completion_chunk_kind(@pointer, i)
				end
				
				# Get the text of a chunk.
				# @parameter i [Integer] The chunk index.
				# @returns [String] The chunk text.
				def chunk_text(i)
					Lib.extract_string Lib.get_completion_text(@pointer, i)
				end
				
				# Get the completion string of a chunk.
				# @parameter i [Integer] The chunk index.
				# @returns [CodeCompletion::String] The chunk's completion string.
				def chunk_completion(i)
					CodeCompletion::String.new Lib.get_completion_chunk_completion_string(@pointer, i)
				end
				
				# Get the number of chunks.
				# @returns [Integer] The number of chunks.
				def num_chunks
					Lib.get_num_completion_chunks(@pointer)
				end
				
				# Get all chunks as an array of hashes.
				# @returns [Array(Hash)] Array of chunk hashes with `:kind`, `:text`, and `:completion` keys.
				def chunks
					num_chunks.times.map{|i|
						{ kind: chunk_kind(i), text: chunk_text(i), completion: chunk_completion(i) }
					}
				end
				
				# Get the priority of this completion.
				# @returns [Integer] The completion priority.
				def priority
					Lib.get_completion_priority(@pointer)
				end
				
				# Get the availability of this completion.
				# @returns [Symbol] The completion availability.
				def availability
					Lib.get_completion_availability(@pointer)
				end
				
				# Get the number of annotations.
				# @returns [Integer] The number of annotations.
				def num_annotations
					Lib.get_completion_num_annotations(@pointer)
				end
				
				# Get an annotation by index.
				# @parameter i [Integer] The annotation index.
				# @returns [String] The annotation text.
				def annotation(i)
					Lib.extract_string Lib.get_completion_annotation(@pointer, i)
				end
				
				# Get all annotations.
				# @returns [Array(String)] Array of annotation strings.
				def annotations
					num_annotations.times.map{|i|
						Lib.extract_string Lib.get_completion_annotation(@pointer, i)
					}
				end
				
				# Get the parent context.
				# @returns [String] The parent context.
				def parent
					Lib.extract_string Lib.get_completion_parent(@pointer, nil)
				end
				
				# Get the brief comment.
				# @returns [String] The brief comment.
				def comment
					Lib.extract_string Lib.get_completion_brief_comment(@pointer)
				end
				
				# Get a string representation of this completion string.
				# @returns [String] The chunks as a string.
				def inspect
					chunks.inspect
				end
			end
		end
	end
end
