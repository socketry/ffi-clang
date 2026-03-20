# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.

require_relative "lib/compilation_database"

module FFI
	module Clang
		# Represents a compilation database for a project.
		class CompilationDatabase < AutoPointer
			# Represents an error loading the compilation database.
			class DatabaseLoadError < FFI::Clang::Error; end
			
			# Initialize a compilation database from a directory.
			# @parameter dirpath [String] The directory path containing the compilation database.
			# @raises [DatabaseLoadError] If the database cannot be loaded.
			def initialize(dirpath)
				uint_ptr = MemoryPointer.new :uint
				cdb_ptr = Lib.compilation_database_from_directory(dirpath, uint_ptr)
				error_code = Lib::CompilationDatabaseError[uint_ptr.read_uint]
				if error_code != :no_error
					raise DatabaseLoadError, "Cannot load database: #{error_code}"
				end
				super cdb_ptr
			end
			
			# Release the compilation database pointer.
			# @parameter pointer [FFI::Pointer] The pointer to release.
			def self.release(pointer)
				Lib.compilation_database_dispose(pointer)
			end
			
			# Get compile commands for a specific file.
			# @parameter filename [String] The filename to get commands for.
			# @returns [CompileCommands] The compile commands for the file.
			def compile_commands(filename)
				CompileCommands.new Lib.compilation_database_get_compile_commands(self, filename), self
			end
			
			# Get all compile commands in the database.
			# @returns [CompileCommands] All compile commands.
			def all_compile_commands
				CompileCommands.new Lib.compilation_database_get_all_compile_commands(self), self
			end
			
			# Represents a collection of compile commands.
			class CompileCommands < AutoPointer
				include Enumerable
				
				# Initialize compile commands.
				# @parameter pointer [FFI::Pointer] The commands pointer.
				# @parameter database [CompilationDatabase] The parent database.
				def initialize(pointer, database)
					super pointer
					@database = database
				end
				
				# Release the compile commands pointer.
				# @parameter pointer [FFI::Pointer] The pointer to release.
				def self.release(pointer)
					Lib.compile_commands_dispose(pointer)
				end
				
				# Get the number of compile commands.
				# @returns [Integer] The number of commands.
				def size
					Lib.compile_commands_get_size(self)
				end
				
				# Get a compile command by index.
				# @parameter i [Integer] The command index.
				# @returns [CompileCommand] The compile command.
				def command(i)
					CompileCommand.new Lib.compile_commands_get_command(self, i)
				end
				
				# Get all compile commands.
				# @returns [Array(CompileCommand)] Array of compile commands.
				def commands
					size.times.map {|i| command(i)}
				end
				
				# Iterate over each compile command.
				# @yields {|command| ...} Each compile command.
				# 	@parameter command [CompileCommand] The compile command.
				# @returns [Enumerator] If no block is given.
				def each(&block)
					return to_enum(__method__) unless block_given?
					
					size.times do |i|
						block.call(command(i))
					end
					
					self
				end
			end
			
			# Represents a single compile command.
			class CompileCommand
				# Initialize a compile command.
				# @parameter pointer [FFI::Pointer] The command pointer.
				def initialize(pointer)
					@pointer = pointer
				end
				
				# Get the working directory for the command.
				# @returns [String] The directory path.
				def directory
					Lib.extract_string Lib.compile_command_get_directory(@pointer)
				end
				
				# Get the filename associated with the command.
				# @returns [String] The filename.
				def filename
					Lib.extract_string Lib.compile_command_get_filename(@pointer)
				end
				
				# Get the number of arguments.
				# @returns [Integer] The number of arguments.
				def num_args
					Lib.compile_command_get_num_args(@pointer)
				end
				
				# Get an argument by index.
				# @parameter i [Integer] The argument index.
				# @returns [String] The argument.
				def arg(i)
					Lib.extract_string Lib.compile_command_get_arg(@pointer, i)
				end
				
				# Get all arguments.
				# @returns [Array(String)] Array of arguments.
				def args
					num_args.times.map {|i| arg(i)}
				end
				
				# Get the number of mapped sources.
				# @returns [Integer] The number of mapped sources.
				def num_mapped_sources
					Lib.compile_command_get_num_mapped_sources(@pointer)
				end
				
				# Get a mapped source path by index.
				# @parameter i [Integer] The source index.
				# @returns [String] The mapped source path.
				def mapped_source_path(i)
					Lib.extract_string Lib.compile_command_get_mapped_source_path(@pointer, i)
				end
				
				# Get mapped source content by index.
				# @parameter i [Integer] The source index.
				# @returns [String] The mapped source content.
				def mapped_source_content(i)
					Lib.extract_string Lib.compile_command_get_mapped_source_content(@pointer, i)
				end
				
				# Get all mapped sources.
				# @returns [Array(Hash)] Array of hashes with `:path` and `:content` keys.
				def mapped_sources
					num_mapped_sources.times.map {|i|
						{path: mapped_source_path(i), content: mapped_source_content(i)}
					}
				end
			end
		end
	end
end
