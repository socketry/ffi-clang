# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2026, by Charlie Savage.

require_relative "lib/diagnostic"

module FFI
	module Clang
		# Represents a set of child diagnostics from a parent Diagnostic.
		#
		# This is not an AutoPointer because the CXDiagnosticSet pointer is
		# owned by the parent Diagnostic. Per the libclang docs:
		# "This CXDiagnosticSet does not need to be released by
		# clang_disposeDiagnosticSet."
		#
		# Individual diagnostics obtained from the set DO need disposal
		# via clang_disposeDiagnostic, which is handled by the Diagnostic
		# AutoPointer. Diagnostics are cached on construction so that
		# repeated iteration does not create duplicate AutoPointers that
		# would double-free.
		class DiagnosticSet
			include Enumerable
			
			# @attribute [r] size
			# 	@returns [Integer] The number of diagnostics in the set.
			attr_reader :size
			
			# Initialize a diagnostic set from a CXDiagnosticSet pointer.
			# @parameter pointer [FFI::Pointer] The CXDiagnosticSet pointer (owned by parent Diagnostic).
			# @parameter translation_unit [TranslationUnit] The parent translation unit.
			def initialize(pointer, translation_unit)
				@size = Lib.get_num_diagnostics_in_set(pointer)
				@diagnostics = @size.times.map do |i|
					Diagnostic.new(translation_unit, Lib.get_diagnostic_in_set(pointer, i))
				end
			end
			
			# Iterate over each diagnostic.
			# @yields {|diagnostic| ...} Each diagnostic.
			# 	@parameter diagnostic [Diagnostic] The diagnostic.
			# @returns [Enumerator] If no block is given.
			def each(&block)
				return to_enum(__method__) unless block_given?
				
				@diagnostics.each(&block)
				
				self
			end
		end
	end
end
