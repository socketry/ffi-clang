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
			# Wraps the array allocated by clang_getOverriddenCursors and
			# disposes it via clang_disposeOverriddenCursors on release.
			class OverriddenCursors < AutoPointer
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
					@translation_unit = translation_unit

					super(cursor_ptr.get_pointer(0))
				end

				# Release the overridden cursors buffer.
				# @parameter pointer [FFI::Pointer] The pointer to release.
				def self.release(pointer)
					Lib.dispose_overridden_cursors(pointer) unless pointer.null?
				end

				# Iterate over each overridden cursor.
				# @yields {|cursor| ...} Each overridden cursor.
				# 	@parameter cursor [Cursor] The overridden cursor.
				# @returns [Enumerator] If no block is given.
				def each(&block)
					return to_enum(__method__) unless block_given?

					cur_ptr = FFI::Pointer.new(self)
					@size.times do
						block.call(Cursor.new(Lib::CXCursor.new(cur_ptr), @translation_unit))
						cur_ptr += Lib::CXCursor.size
					end

					self
				end
			end
		end
	end
end
