# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

require_relative "lib/cursor_set"

module FFI
	module Clang
		# Represents a libclang cursor set for fast cursor membership checks.
		class CursorSet < AutoPointer
			# Create an empty cursor set.
			def initialize
				super Lib.create_cursor_set
			end
			
			# Release the cursor set pointer.
			# @parameter pointer [FFI::Pointer] The cursor set pointer to release.
			def self.release(pointer)
				Lib.dispose_cursor_set(pointer)
			end
			
			# Check whether the set contains a cursor.
			# @parameter cursor [Cursor] The cursor to check.
			# @returns [Boolean] True if the cursor is present in the set.
			def include?(cursor)
				Lib.cursor_set_contains(self, cursor.cursor) != 0
			end
			
			# Insert a cursor into the set.
			# @parameter cursor [Cursor] The cursor to insert.
			# @returns [Boolean] True if the cursor was newly inserted.
			def insert(cursor)
				Lib.cursor_set_insert(self, cursor.cursor) != 0
			end
		end
	end
end
