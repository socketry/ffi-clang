# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		module Lib
			typedef :pointer, :CXEvalResult
			
			enum :eval_result_kind, [
				:int, 1,
				:float, 2,
				:obj_c_str_literal, 3,
				:str_literal, 4,
				:c_f_str, 5,
				:other, 6,
				:unexposed, 0
			]
			
			attach_function :cursor_evaluate, :clang_Cursor_Evaluate, [CXCursor.by_value], :CXEvalResult
			attach_function :eval_result_get_kind, :clang_EvalResult_getKind, [:CXEvalResult], :eval_result_kind
			attach_function :eval_result_get_as_int, :clang_EvalResult_getAsInt, [:CXEvalResult], :int
			attach_function :eval_result_get_as_long_long, :clang_EvalResult_getAsLongLong, [:CXEvalResult], :long_long
			attach_function :eval_result_is_unsigned_int, :clang_EvalResult_isUnsignedInt, [:CXEvalResult], :uint
			attach_function :eval_result_get_as_unsigned, :clang_EvalResult_getAsUnsigned, [:CXEvalResult], :ulong_long
			attach_function :eval_result_get_as_double, :clang_EvalResult_getAsDouble, [:CXEvalResult], :double
			attach_function :eval_result_get_as_str, :clang_EvalResult_getAsStr, [:CXEvalResult], :string
			attach_function :eval_result_dispose, :clang_EvalResult_dispose, [:CXEvalResult], :void
		end
	end
end
