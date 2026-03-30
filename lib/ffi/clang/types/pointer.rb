# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Charlie Savage.
# Copyright, 2025, by Samuel Williams.

module FFI
	module Clang
		module Types
			# Represents a pointer type.
			# This includes regular pointers, block pointers, Objective-C object pointers, and member pointers.
			class Pointer < Type
				# Get the type that this pointer points to.
				# @returns [Type] The pointee type.
				def pointee
					Type.create Lib.get_pointee_type(@type), @translation_unit
				end
				
				# Check if this is a function pointer.
				# @returns [Boolean] True if this pointer points to a function.
				def function?
					self.pointee.is_a?(Types::Function)
				end
				
				# Get the class type for member pointers.
				# @returns [Type, nil] The class type if this is a member pointer, nil otherwise.
				def class_type
					if self.kind == :type_member_pointer
						Type.create Lib.type_get_class_type(@type), @translation_unit
					else
						nil
					end
				end
				
				# Check if this pointer references a forward declaration.
				# @returns [Boolean] True if this pointer points to a forward-declared type.
				def forward_declaration?
					pointee = self.pointee
					return nil if self.function?
					
					# Resolve to a Record type, handling both elaborated and direct record types.
					# Newer clang versions (22+) may return :type_record directly instead of
					# wrapping in :type_elaborated.
					record_type = if pointee.is_a?(Types::Elaborated) && pointee.canonical.is_a?(Types::Record)
						pointee.canonical
					elsif pointee.is_a?(Types::Record)
						pointee
					end
					
					return nil unless record_type
					
					# Get the universal symbol reference
					usr = record_type.declaration.usr
					
					# Now does that same usr occur earlier in the file?
					first_declaration, _ = self.translation_unit.cursor.find do |child, parent|
						child.usr == usr
					end
					# NOTE - Maybe should also check that the line number of
					# is less than the line number of the declaration this type references
					first_declaration.forward_declaration?
				end
			end
		end
	end
end
