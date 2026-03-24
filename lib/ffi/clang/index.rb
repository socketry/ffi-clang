# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013, by Dave Wilkinson.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2023-2026, by Charlie Savage.

require_relative "lib/index"
require_relative "error"
require_relative "invocation_support"

module FFI
	module Clang
		# Represents a libclang index that manages translation units and provides a top-level context for parsing.
		class Index < AutoPointer
			include InvocationSupport
			
			# Initialize a new index for managing translation units.
			# @parameter exclude_declarations_from_pch [Boolean] Whether to exclude declarations from PCH.
			# @parameter display_diagnostics [Boolean] Whether to display diagnostics during parsing.
			# @parameter store_preambles_in_memory [Boolean] Whether to store preambles in memory.
			# @parameter thread_background_priority_for_indexing [Symbol] The indexing background priority choice.
			# @parameter thread_background_priority_for_editing [Symbol] The editing background priority choice.
			# @parameter preamble_storage_path [String | Nil] The directory where preambles should be stored.
			# @parameter invocation_emission_path [String | Nil] The directory where invocation files should be emitted.
			# @raises [NotImplementedError] If Clang 17.0.0+ options are requested on an older libclang.
			def initialize(
				exclude_declarations_from_pch: true,
				display_diagnostics: false,
				store_preambles_in_memory: false,
				thread_background_priority_for_indexing: :default,
				thread_background_priority_for_editing: :default,
				preamble_storage_path: nil,
				invocation_emission_path: nil
			)
				pointer = create_index_pointer(exclude_declarations_from_pch:, display_diagnostics:, store_preambles_in_memory:, thread_background_priority_for_indexing:, thread_background_priority_for_editing:, preamble_storage_path:, invocation_emission_path:)
				super pointer
			end
			
			# Release the index pointer.
			# @parameter pointer [FFI::Pointer] The index pointer to release.
			def self.release(pointer)
				Lib.dispose_index(pointer)
			end
			
			# Get the global index options.
			# @returns [Array(Symbol)] The enabled global option flags.
			def global_options
				Lib.opts_from(Lib::GlobalOptFlags, Lib.get_global_options(self))
			end
			
			# Set the global index options.
			# @parameter options [Array(Symbol)] The global option flags to enable.
			def global_options=(options)
				Lib.set_global_options(self, Lib.bitmask_from(Lib::GlobalOptFlags, options))
			end
			
			# Set the invocation emission path for this index.
			# @parameter path [String] The directory path where invocation files should be emitted.
			def invocation_emission_path=(path)
				Lib.set_invocation_emission_path_option(self, path)
			end
			
			# Parse a source file and create a translation unit.
			# @parameter source_file [String] The path to the source file to parse.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter opts [Array(Symbol)] Parsing options as an array of flags.
			# @returns [TranslationUnit] The parsed translation unit.
			# @raises [Error] If parsing fails.
			def parse_translation_unit(source_file, command_line_args = nil, unsaved = [], opts = {})
				parse_translation_unit_with(:parse_translation_unit2, source_file, command_line_args, unsaved, opts)
			end
			
			# Parse a source file using a full compiler command line including argv[0].
			# @parameter source_file [String] The path to the source file to parse.
			# @parameter command_line_args [Array(String) | String | Nil] Full compiler arguments including argv[0].
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter opts [Array(Symbol)] Parsing options as an array of flags.
			# @returns [TranslationUnit] The parsed translation unit.
			# @raises [Error] If parsing fails.
			def parse_translation_unit_with_invocation(source_file, command_line_args = nil, unsaved = [], opts = {})
				parse_translation_unit_with(:parse_translation_unit2_full_argv, source_file, command_line_args, unsaved, opts)
			end
			
			# Create a translation unit from a precompiled AST file.
			# @parameter ast_filename [String] The path to the AST file.
			# @returns [TranslationUnit] The loaded translation unit.
			# @raises [Error] If loading the AST file fails.
			def create_translation_unit(ast_filename)
				translation_unit_pointer = Lib.create_translation_unit(self, ast_filename)
				raise Error, "error parsing #{ast_filename.inspect}" if translation_unit_pointer.null?
				TranslationUnit.new translation_unit_pointer, self
			end
			
			# Create a translation unit from a precompiled AST file with detailed error reporting.
			# @parameter ast_filename [String] The path to the AST file.
			# @returns [TranslationUnit] The loaded translation unit.
			# @raises [Error] If loading the AST file fails.
			def create_translation_unit2(ast_filename)
				translation_unit_pointer_out = MemoryPointer.new(:pointer)
				error_code = Lib.create_translation_unit2(self, ast_filename, translation_unit_pointer_out)
				translation_unit_from_error_code(error_code, ast_filename, translation_unit_pointer_out)
			end
			
			# Create a translation unit directly from source and compiler arguments.
			# @parameter source_file [String] The path to the source file to parse.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @returns [TranslationUnit] The parsed translation unit.
			# @raises [Error] If parsing fails.
			def create_translation_unit_from_source_file(source_file, command_line_args = nil, unsaved = [])
				command_line_args = normalized_command_line_args(command_line_args)
				args_pointer, _strings = args_pointer_from(command_line_args)
				unsaved_files = UnsavedFile.unsaved_pointer_from(unsaved)
				
				translation_unit_pointer = Lib.create_translation_unit_from_source_file(self, source_file, command_line_args.length, args_pointer, unsaved.length, unsaved_files)
				raise Error, "error parsing #{source_file.inspect}" if translation_unit_pointer.null?
				
				TranslationUnit.new translation_unit_pointer, self
			end
			
			# Create a reusable indexing action for this index.
			# @returns [IndexAction] The created index action.
			def create_action
				IndexAction.new(self)
			end
			
			# Index a source file using a temporary index action.
			# @parameter source_file [String] The source file to index.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter index_opts [Array(Symbol)] Indexing options.
			# @parameter translation_unit_opts [Array(Symbol)] Translation unit parsing options.
			# @yields {|event, payload| ...} Each indexing event and its payload.
			# 	@parameter event [Symbol] The event type.
			# 	@parameter payload [Object] The event payload.
			# @returns [Enumerator] If no block is given.
			# @returns [TranslationUnit | Nil] The indexed translation unit, or nil if indexing was aborted.
			def index_source_file(source_file, command_line_args = nil, unsaved = [], index_opts = [], translation_unit_opts = [], &block)
				return to_enum(__method__, source_file, command_line_args, unsaved, index_opts, translation_unit_opts) unless block_given?
				
				create_action.index_source_file(source_file, command_line_args, unsaved, index_opts, translation_unit_opts, &block)
			end
			
			# Index a source file using a full compiler command line and a temporary index action.
			# @parameter source_file [String] The source file to index.
			# @parameter command_line_args [Array(String) | String | Nil] Full compiler arguments including argv[0].
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter index_opts [Array(Symbol)] Indexing options.
			# @parameter translation_unit_opts [Array(Symbol)] Translation unit parsing options.
			# @yields {|event, payload| ...} Each indexing event and its payload.
			# 	@parameter event [Symbol] The event type.
			# 	@parameter payload [Object] The event payload.
			# @returns [Enumerator] If no block is given.
			# @returns [TranslationUnit | Nil] The indexed translation unit, or nil if indexing was aborted.
			def index_source_file_with_invocation(source_file, command_line_args = nil, unsaved = [], index_opts = [], translation_unit_opts = [], &block)
				return to_enum(__method__, source_file, command_line_args, unsaved, index_opts, translation_unit_opts) unless block_given?
				
				create_action.index_source_file_with_invocation(source_file, command_line_args, unsaved, index_opts, translation_unit_opts, &block)
			end
			
			# Index an existing translation unit using a temporary index action.
			# @parameter translation_unit [TranslationUnit] The translation unit to index.
			# @parameter index_opts [Array(Symbol)] Indexing options.
			# @yields {|event, payload| ...} Each indexing event and its payload.
			# 	@parameter event [Symbol] The event type.
			# 	@parameter payload [Object] The event payload.
			# @returns [Enumerator] If no block is given.
			# @returns [TranslationUnit | Nil] The translation unit, or nil if indexing was aborted.
			def index_translation_unit(translation_unit, index_opts = [], &block)
				return to_enum(__method__, translation_unit, index_opts) unless block_given?
				
				create_action.index_translation_unit(translation_unit, index_opts, &block)
			end
			
			private
			
			# Create the native index pointer using the best available libclang API.
			# @parameter exclude_declarations_from_pch [Boolean] Whether to exclude declarations from PCH.
			# @parameter display_diagnostics [Boolean] Whether to display diagnostics during parsing.
			# @parameter store_preambles_in_memory [Boolean] Whether to store preambles in memory.
			# @parameter thread_background_priority_for_indexing [Symbol] The indexing background priority choice.
			# @parameter thread_background_priority_for_editing [Symbol] The editing background priority choice.
			# @parameter preamble_storage_path [String | Nil] The directory where preambles should be stored.
			# @parameter invocation_emission_path [String | Nil] The directory where invocation files should be emitted.
			# @returns [FFI::Pointer] The native index pointer.
			# @raises [NotImplementedError] If Clang 17.0.0+ options are requested on an older libclang.
			def create_index_pointer(
				exclude_declarations_from_pch:,
				display_diagnostics:,
				store_preambles_in_memory:,
				thread_background_priority_for_indexing:,
				thread_background_priority_for_editing:,
				preamble_storage_path:,
				invocation_emission_path:
			)
				if extended_index_options_supported?
					index_options = build_index_options(
						exclude_declarations_from_pch: exclude_declarations_from_pch,
						display_diagnostics: display_diagnostics,
						store_preambles_in_memory: store_preambles_in_memory,
						thread_background_priority_for_indexing: thread_background_priority_for_indexing,
						thread_background_priority_for_editing: thread_background_priority_for_editing,
						preamble_storage_path: preamble_storage_path,
						invocation_emission_path: invocation_emission_path
					)
					
					Lib.create_index_with_options(index_options)
				else
					raise NotImplementedError, "store_preambles_in_memory requires Clang 17.0.0+" if store_preambles_in_memory
					raise NotImplementedError, "preamble_storage_path requires Clang 17.0.0+" if preamble_storage_path
					
					pointer = Lib.create_index(exclude_declarations_from_pch ? 1 : 0, display_diagnostics ? 1 : 0)
					apply_global_option_choices(pointer, thread_background_priority_for_indexing, thread_background_priority_for_editing)
					Lib.set_invocation_emission_path_option(pointer, invocation_emission_path) if invocation_emission_path
					pointer
				end
			end
			
			# Check whether clang_createIndexWithOptions is available.
			# @returns [Boolean] True if extended index options are supported.
			def extended_index_options_supported?
				defined?(Lib::CXIndexOptions) and Lib.respond_to?(:create_index_with_options)
			end
			
			# Build a CXIndexOptions struct from keyword-style index options.
			# @parameter exclude_declarations_from_pch [Boolean] Whether to exclude declarations from PCH.
			# @parameter display_diagnostics [Boolean] Whether to display diagnostics during parsing.
			# @parameter store_preambles_in_memory [Boolean] Whether to store preambles in memory.
			# @parameter thread_background_priority_for_indexing [Symbol] The indexing background priority choice.
			# @parameter thread_background_priority_for_editing [Symbol] The editing background priority choice.
			# @parameter preamble_storage_path [String | Nil] The directory where preambles should be stored.
			# @parameter invocation_emission_path [String | Nil] The directory where invocation files should be emitted.
			# @returns [Lib::CXIndexOptions] The populated options struct.
			def build_index_options(
				exclude_declarations_from_pch:,
				display_diagnostics:,
				store_preambles_in_memory:,
				thread_background_priority_for_indexing:,
				thread_background_priority_for_editing:,
				preamble_storage_path:,
				invocation_emission_path:
			)
				index_options = Lib::CXIndexOptions.new
				index_options.exclude_declarations_from_pch = exclude_declarations_from_pch
				index_options.display_diagnostics = display_diagnostics
				index_options.store_preambles_in_memory = store_preambles_in_memory
				index_options.thread_background_priority_for_indexing = thread_background_priority_for_indexing
				index_options.thread_background_priority_for_editing = thread_background_priority_for_editing
				index_options.preamble_storage_path = preamble_storage_path
				index_options.invocation_emission_path = invocation_emission_path
				index_options
			end
			
			# Apply thread priority choices through the legacy global-options API.
			# @parameter pointer [FFI::Pointer] The native index pointer.
			# @parameter indexing [Symbol] The indexing background priority choice.
			# @parameter editing [Symbol] The editing background priority choice.
			def apply_global_option_choices(pointer, indexing, editing)
				flags = []
				flags << :thread_background_priority_for_indexing if indexing == :enabled
				flags << :thread_background_priority_for_editing if editing == :enabled
				Lib.set_global_options(pointer, Lib.bitmask_from(Lib::GlobalOptFlags, flags))
			end
			
			# Parse a translation unit through a specific libclang entry point.
			# @parameter function_name [Symbol] The low-level parse function to invoke.
			# @parameter source_file [String] The path to the source file to parse.
			# @parameter command_line_args [Array(String) | String | Nil] Compiler arguments for parsing.
			# @parameter unsaved [Array(UnsavedFile)] Unsaved file buffers.
			# @parameter opts [Array(Symbol)] Parsing options as an array of flags.
			# @returns [TranslationUnit] The parsed translation unit.
			# @raises [Error] If parsing fails.
			def parse_translation_unit_with(function_name, source_file, command_line_args, unsaved, opts)
				command_line_args = normalized_command_line_args(command_line_args)
				args_pointer, _strings = args_pointer_from(command_line_args)
				unsaved_files = UnsavedFile.unsaved_pointer_from(unsaved)
				translation_unit_pointer_out = FFI::MemoryPointer.new(:pointer)
				
				error_code = Lib.send(function_name, self, source_file, args_pointer, command_line_args.size, unsaved_files, unsaved.length, translation_unit_options_bitmask_from(opts), translation_unit_pointer_out)
				translation_unit_from_error_code(error_code, source_file, translation_unit_pointer_out)
			end
			
			# Build a translation unit from a libclang error code and output pointer.
			# @parameter error_code [Symbol] The libclang error code.
			# @parameter source_file [String] The path that was being parsed or loaded.
			# @parameter translation_unit_pointer_out [FFI::MemoryPointer] The output pointer for the translation unit.
			# @returns [TranslationUnit] The created translation unit.
			# @raises [Error] If the low-level call fails.
			def translation_unit_from_error_code(error_code, source_file, translation_unit_pointer_out)
				if error_code != :cx_error_success
					raise(Error, "Error parsing file. Code: #{error_code}. File: #{source_file.inspect}")
				end
				
				translation_unit_pointer = translation_unit_pointer_out.read_pointer
				TranslationUnit.new translation_unit_pointer, self
			end
		end
	end
end
