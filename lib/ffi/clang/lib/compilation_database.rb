# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		module Lib
			typedef :pointer, :CXCompilationDatabase
			typedef :pointer, :CXCompileCommands
			typedef :pointer, :CXCompileCommand
			
			CompilationDatabaseError = enum [
				:no_error, 0,
				:can_not_load_database, 1,
			]
			
			# CompilationDatabase
			attach_function :compilation_database_from_directory, :clang_CompilationDatabase_fromDirectory, [:string, :pointer], :CXCompilationDatabase
			attach_function :compilation_database_dispose, :clang_CompilationDatabase_dispose, [:CXCompilationDatabase], :void
			attach_function :compilation_database_get_compile_commands, :clang_CompilationDatabase_getCompileCommands, [:CXCompilationDatabase, :string], :CXCompileCommands
			attach_function :compilation_database_get_all_compile_commands, :clang_CompilationDatabase_getAllCompileCommands, [:CXCompilationDatabase], :CXCompileCommands
			
			# CompilationDatabase::CompileCommands
			attach_function :compile_commands_dispose, :clang_CompileCommands_dispose, [:CXCompileCommands], :void
			attach_function :compile_commands_get_size, :clang_CompileCommands_getSize, [:CXCompileCommands], :uint
			attach_function :compile_commands_get_command, :clang_CompileCommands_getCommand, [:CXCompileCommands, :uint], :CXCompileCommand
			
			# CompilationDatabase::CompileCommand
			attach_function :compile_command_get_directory, :clang_CompileCommand_getDirectory, [:CXCompileCommand], CXString.by_value
			attach_function :compile_command_get_filename, :clang_CompileCommand_getFilename, [:CXCompileCommand], CXString.by_value
			attach_function :compile_command_get_num_args, :clang_CompileCommand_getNumArgs, [:CXCompileCommand], :uint
			attach_function :compile_command_get_arg, :clang_CompileCommand_getArg, [:CXCompileCommand, :uint], CXString.by_value
			attach_function :compile_command_get_num_mapped_sources, :clang_CompileCommand_getNumMappedSources, [:CXCompileCommand], :uint
			attach_function :compile_command_get_mapped_source_path, :clang_CompileCommand_getMappedSourcePath, [:CXCompileCommand, :uint], CXString.by_value
			attach_function :compile_command_get_mapped_source_content, :clang_CompileCommand_getMappedSourceContent, [:CXCompileCommand, :uint], CXString.by_value
		end
	end
end
