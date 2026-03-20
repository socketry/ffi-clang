# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2026, by Charlie Savage.

require_relative "lib/cursor"

module FFI
	module Clang
		class Cursor
			# Represents the set of cursors overridden by a method.
			# Calls clang_getOverriddenCursors, copies each CXCursor into
			# Ruby-managed memory, then immediately disposes the buffer
			# via clang_disposeOverriddenCursors. This avoids GC-order
			# issues with AutoPointer where the buffer could be double-freed.
			class OverriddenCursors
				include Enumerable
				
				# @attribute [r] size
				# 	@returns [Integer] The number of overridden cursors.
				attr_reader :size
				
				# Initialize overridden cursors for a given cursor.
				# @parameter cursor [Lib::CXCursor] The cursor to query.
				# @parameter translation_unit [TranslationUnit] The parent translation unit.
				def initialize(cursor, translation_unit)
					cursor_ptr = FFI::MemoryPointer.new :pointer
					num_ptr = FFI::MemoryPointer.new :uint
					Lib.get_overridden_cursors(cursor, cursor_ptr, num_ptr)
					
					@size = num_ptr.get_uint(0)
					
					if @size > 0
						buffer = cursor_ptr.get_pointer(0)
						
						# Dup each CXCursor into Ruby-managed memory before
						# disposing the buffer. Using an AutoPointer to defer
						# disposal causes double-free crashes on Linux and MacOS
						# (not windows) for unknown reasons.
						cur_ptr = buffer
						@cursors = @size.times.map do
							cursor = Lib::CXCursor.new(cur_ptr).dup
							cur_ptr += Lib::CXCursor.size
							Cursor.new(cursor, translation_unit)
						end
						
						Lib.dispose_overridden_cursors(buffer)
					else
						@cursors = []
					end
				end
				
				# Iterate over each overridden cursor.
				# @yields {|cursor| ...} Each overridden cursor.
				# 	@parameter cursor [Cursor] The overridden cursor.
				# @returns [Enumerator] If no block is given.
				def each(&block)
					return to_enum(__method__) unless block_given?
					
					@cursors.each(&block)
					
					self
				end
			end
		end
	end
end
