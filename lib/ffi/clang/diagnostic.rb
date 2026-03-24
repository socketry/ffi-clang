# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Garry Marshall.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2023-2026, by Charlie Savage.

require_relative "lib/diagnostic"
require_relative "source_range"

module FFI
	module Clang
		# Represents a diagnostic message from the compiler.
		class Diagnostic < AutoPointer
			# Get the default diagnostic display options.
			# @returns [Array(Symbol)] The default display options.
			def self.default_display_opts
				Lib.opts_from(Lib::DiagnosticDisplayOptions, Lib.default_diagnostic_display_options)
			end
			
			# Initialize a diagnostic.
			# @parameter translation_unit [TranslationUnit] The parent translation unit.
			# @parameter pointer [FFI::Pointer] The diagnostic pointer.
			def initialize(translation_unit, pointer)
				super pointer
				
				@translation_unit = translation_unit
			end
			
			# Release the diagnostic pointer.
			# @parameter pointer [FFI::Pointer] The pointer to release.
			def self.release(pointer)
				Lib.dispose_diagnostic(pointer)
			end
			
			# Format the diagnostic as a string.
			# @parameter opts [Hash] Display options.
			# @returns [String] The formatted diagnostic.
			def format(opts = {})
				cxstring = Lib.format_diagnostic(self, display_opts(opts))
				Lib.extract_string cxstring
			end
			
			# Get the severity of the diagnostic.
			# @returns [Symbol] The severity level.
			def severity
				Lib.get_diagnostic_severity self
			end
			
			# Get the diagnostic message text.
			# @returns [String] The diagnostic spelling.
			def spelling
				Lib.extract_string Lib.get_diagnostic_spelling(self)
			end
			
			# Get the source location of the diagnostic.
			# @returns [ExpansionLocation] The diagnostic location.
			def location
				sl = Lib.get_diagnostic_location(self)
				ExpansionLocation.new sl
			end
			
			# Get fix-it hints for the diagnostic.
			# @returns [Array(Hash)] Array of fix-its with `:text` and `:range` keys.
			def fixits
				n = Lib.get_diagnostic_num_fix_its(self)
				n.times.map do |i|
					ptr = MemoryPointer.new Lib::CXSourceRange
					replace_text = Lib.extract_string(Lib.get_diagnostic_fix_it(self, i, ptr))
					{text: replace_text, range: SourceRange.new(ptr)}
				end
			end
			
			# Get the source ranges associated with the diagnostic.
			# @returns [Array(SourceRange)] Array of source ranges.
			def ranges
				n = Lib.get_diagnostic_num_ranges(self)
				
				n.times.map{|i| SourceRange.new Lib.get_diagnostic_range(self, i)}
			end
			
			# Get child diagnostics.
			# @returns [DiagnosticSet] The child diagnostics.
			def children
				@children ||= DiagnosticSet.new(Lib.get_child_diagnostics(self), @translation_unit)
			end
			
			# Get the compiler option that enables this diagnostic.
			# @returns [String] The enable option.
			def enable_option
				Lib.extract_string Lib.get_diagnostic_option(self, nil)
			end
			
			# Get the compiler option that disables this diagnostic.
			# @returns [String] The disable option.
			def disable_option
				ptr = MemoryPointer.new Lib::CXString
				Lib.get_diagnostic_option(self, ptr)
				Lib.extract_string ptr
			end
			
			# Get the category text for the diagnostic.
			# @returns [String] The category text.
			def category
				Lib.extract_string Lib.get_diagnostic_category_text(self)
			end
			
			# Get the category ID for the diagnostic.
			# @returns [Integer] The category ID.
			def category_id
				Lib.get_diagnostic_category(self)
			end
			
			# Get a string representation of the diagnostic.
			# @returns [String] The diagnostic string.
			def inspect
				"#{self.location}: #{self.format}"
			end
			
			private
			
			# @private
			def display_opts(opts)
				if opts.empty?
					Lib.default_diagnostic_display_options
				else
					Lib.bitmask_from(Lib::DiagnosticDisplayOptions, opts)
				end
			end
		end
	end
end
