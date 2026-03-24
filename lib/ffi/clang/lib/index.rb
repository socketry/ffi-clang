# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2024-2026, by Charlie Savage.

module FFI
	module Clang
		module Lib
			typedef :pointer, :CXIndex
			
			GlobalOptFlags = enum [
				:none, 0x0,
				:thread_background_priority_for_indexing, 0x1,
				:thread_background_priority_for_editing, 0x2,
				:thread_background_priority_for_all, 0x3
			]
			
			# Source code index:
			attach_function :create_index, :clang_createIndex, [:int, :int], :CXIndex
			attach_function :dispose_index, :clang_disposeIndex, [:CXIndex], :void
			attach_function :set_global_options, :clang_CXIndex_setGlobalOptions, [:CXIndex, :uint], :void
			attach_function :get_global_options, :clang_CXIndex_getGlobalOptions, [:CXIndex], :uint
			attach_function :set_invocation_emission_path_option, :clang_CXIndex_setInvocationEmissionPathOption, [:CXIndex, :string], :void
			
			if Clang.clang_version >= Gem::Version.new("17.0.0")
				CXChoice = enum(FFI::Type::UINT8, [
					:default, 0,
					:enabled, 1,
					:disabled, 2
				])
				
				# FFI struct for index creation options (libclang 17.0.0+).
				#
				# The C struct uses bitfields for ExcludeDeclarationsFromPCH (bit 0),
				# DisplayDiagnostics (bit 1), and StorePreamblesInMemory (bit 2).
				# FFI doesn't support bitfields, so these are packed into a single field.
				# Use the helper methods to set them.
				#
				# On Windows, libclang packs the unsigned bitfields into a 4-byte uint
				# with alignment padding, making the struct 32 bytes. On Linux/macOS,
				# they pack into 2 bytes after the uchars (24 bytes total).
				class CXIndexOptions < FFI::Struct
					if FFI::Platform.windows?
						layout(
							:size, :uint,
							:thread_background_priority_for_indexing, CXChoice,
							:thread_background_priority_for_editing, CXChoice,
							:padding1, :ushort,
							:bitfields, :uint,
							:padding2, :uint,
							:preamble_storage_path, :pointer,
							:invocation_emission_path, :pointer
						)
					else
						layout(
							:size, :uint,
							:thread_background_priority_for_indexing, CXChoice,
							:thread_background_priority_for_editing, CXChoice,
							:bitfields, :ushort,
							:preamble_storage_path, :pointer,
							:invocation_emission_path, :pointer
						)
					end
					
					# Create a new CXIndexOptions with size pre-populated.
					def initialize(*args)
						super
						self[:size] = self.class.size
						@string_fields = {}
					end
					
					# Set the indexing background thread priority policy.
					# @parameter value [Symbol] The CXChoice value.
					def thread_background_priority_for_indexing=(value)
						self[:thread_background_priority_for_indexing] = value
					end
					
					# Set the editing background thread priority policy.
					# @parameter value [Symbol] The CXChoice value.
					def thread_background_priority_for_editing=(value)
						self[:thread_background_priority_for_editing] = value
					end
					
					# Set whether to exclude declarations from PCH.
					# @parameter value [Boolean] True to exclude.
					def exclude_declarations_from_pch=(value)
						set_bitfield(0, value)
					end
					
					# Set whether to display diagnostics.
					# @parameter value [Boolean] True to display.
					def display_diagnostics=(value)
						set_bitfield(1, value)
					end
					
					# Set whether to store preambles in memory.
					# @parameter value [Boolean] True to store in memory.
					def store_preambles_in_memory=(value)
						set_bitfield(2, value)
					end
					
					# Set the preamble storage path.
					# @parameter value [String | Nil] The directory path.
					def preamble_storage_path=(value)
						store_string(:preamble_storage_path, value)
					end
					
					# Set the invocation emission path.
					# @parameter value [String | Nil] The directory path.
					def invocation_emission_path=(value)
						store_string(:invocation_emission_path, value)
					end
					
					private
					
					# Set a single bit in the bitfields.
					# @parameter bit [Integer] The bit position.
					# @parameter value [Boolean] The value to set.
					def set_bitfield(bit, value)
						if value
							self[:bitfields] |= (1 << bit)
						else
							self[:bitfields] &= ~(1 << bit)
						end
					end
					
					# Keep backing string memory alive for pointer fields.
					# @parameter field [Symbol] The struct field.
					# @parameter value [String | Nil] The string value.
					def store_string(field, value)
						if value
							@string_fields[field] = MemoryPointer.from_string(value)
							self[field] = @string_fields[field]
						else
							@string_fields.delete(field)
							self[field] = nil
						end
					end
				end
				
				attach_function :create_index_with_options, :clang_createIndexWithOptions, [CXIndexOptions.by_ref], :CXIndex
			end
		end
	end
end
