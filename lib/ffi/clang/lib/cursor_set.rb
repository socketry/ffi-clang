# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

require_relative "cursor"

module FFI
	module Clang
		module Lib
			typedef :pointer, :CXCursorSet
			
			attach_function :create_cursor_set, :clang_createCXCursorSet, [], :CXCursorSet
			attach_function :dispose_cursor_set, :clang_disposeCXCursorSet, [:CXCursorSet], :void
			attach_function :cursor_set_contains, :clang_CXCursorSet_contains, [:CXCursorSet, CXCursor.by_value], :uint
			attach_function :cursor_set_insert, :clang_CXCursorSet_insert, [:CXCursorSet, CXCursor.by_value], :uint
		end
	end
end
