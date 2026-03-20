# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

require_relative "lib/evaluation"

module FFI
	module Clang
		# Represents the result of evaluating a cursor as a compile-time constant.
		class EvalResult < AutoPointer
			# Get the kind of this evaluation result.
			# @returns [Symbol] The result kind (:int, :float, :str_literal, :obj_c_str_literal, :c_f_str, :other, :unexposed).
			def kind
				Lib.eval_result_get_kind(self)
			end
			
			# Get the result as an integer.
			# @returns [Integer] The integer value.
			def as_int
				Lib.eval_result_get_as_int(self)
			end
			
			# Get the result as a long long integer.
			# @returns [Integer] The long long value.
			def as_long_long
				Lib.eval_result_get_as_long_long(self)
			end
			
			# Check if the result is an unsigned integer.
			# @returns [Boolean] True if the result is unsigned.
			def unsigned_int?
				Lib.eval_result_is_unsigned_int(self) != 0
			end
			
			# Get the result as an unsigned integer.
			# @returns [Integer] The unsigned value.
			def as_unsigned
				Lib.eval_result_get_as_unsigned(self)
			end
			
			# Get the result as a double.
			# @returns [Float] The double value.
			def as_double
				Lib.eval_result_get_as_double(self)
			end
			
			# Get the result as a string.
			# @returns [String] The string value.
			def as_str
				Lib.eval_result_get_as_str(self)
			end
			
			# Release the evaluation result.
			# @parameter pointer [FFI::Pointer] The pointer to release.
			def self.release(pointer)
				Lib.eval_result_dispose(pointer)
			end
		end
	end
end
