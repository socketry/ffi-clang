# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

require "open3"
require "mkmf"

module FFI
	module Clang
		# Platform-specific clang configuration: finding libclang, locating the
		# resource directory, and injecting extra command-line arguments into
		# parse_translation_unit.
		#
		# All discovery is lazy — nothing runs until a method is called.
		class Args
			# Set the loaded libclang path after ffi_lib succeeds,
			# so resource dir probing can use it.
			# @parameter path [String | Nil] Path to the loaded libclang library.
			attr_writer :libclang_loaded_path
			
			# Factory: returns the platform-appropriate subclass instance.
			# @returns [Args] A platform-specific instance.
			def self.create
				case FFI::Clang.platform
				when :darwin
					DarwinArgs.new
				when :mingw
					MingwArgs.new
				when :mswin
					MswinArgs.new
				else
					LinuxArgs.new
				end
			end
			
			# Ordered list of library paths for ffi_lib.
			# @returns [Array(String)] Paths to try when loading libclang.
			def libclang_paths
				@libclang_paths ||= if ENV["LIBCLANG"]
					[ENV["LIBCLANG"]]
				else
					find_libclang_paths
				end
			end
			
			# Extra args to inject into parse_translation_unit.
			# Includes -resource-dir (unless already present) plus any
			# platform-specific flags.
			# @parameter command_line_args [Array(String)] The existing command line arguments.
			# @returns [Array(String)] Additional args to append.
			def command_line_args(command_line_args = [])
				args = []
				
				if !command_line_args.include?("-resource-dir") && resource_dir
					args.push("-resource-dir", resource_dir)
				end
				
				args.concat(extra_args(command_line_args))
				args
			end
			
			# The resolved resource directory path.
			# @returns [String | Nil] The resource directory path, or nil if not found.
			def resource_dir
				if defined?(@resource_dir)
					@resource_dir
				else
					@resource_dir = find_resource_dir
				end
			end
			
			# Called after ffi_lib successfully loads libclang.
			# Subclasses may override to perform post-load setup.
			#
			# @parameter library [FFI::DynamicLibrary] The loaded libclang library.
			def post_load(library)
			end
			
			private
			
			# Platform-specific extra args beyond -resource-dir.
			# Subclasses override as needed.
			# @parameter command_line_args [Array(String)] The existing command line arguments.
			# @returns [Array(String)] Additional platform-specific args.
			def extra_args(command_line_args)
				[]
			end
			
			# --- Shared helpers ---
			
			# Find the llvm-config binary. Checks LLVM_CONFIG env, then PATH
			# (unless LLVM_VERSION is set to pin a specific version).
			# @returns [String | Nil] Path to llvm-config, or nil.
			def llvm_config
				if defined?(@llvm_config)
					return @llvm_config
				end
				
				@llvm_config = ENV["LLVM_CONFIG"]
				
				unless @llvm_config || ENV["LLVM_VERSION"]
					@llvm_config = MakeMakefile.find_executable("llvm-config")
				end
				
				@llvm_config
			end
			
			# Query llvm-config for its library directory.
			# @returns [String | Nil] The library directory, or nil.
			def llvm_library_dir
				return nil unless llvm_config
				
				@llvm_library_dir ||= `#{llvm_config} --libdir`.chomp
			end
			
			# Query llvm-config for its binary directory.
			# @returns [String | Nil] The binary directory, or nil.
			def llvm_bin_dir
				return nil unless llvm_config
				
				@llvm_bin_dir ||= `#{llvm_config} --bindir`.chomp
			end
			
			# Ask a clang binary for its resource directory.
			# @parameter clang [String] Path to or name of the clang binary.
			# @returns [String | Nil] The resource directory path, or nil.
			def resource_dir_from_clang(clang)
				stdout, _stderr, status = Open3.capture3(clang, "-print-resource-dir")
				return nil unless status.success?
				
				dir = stdout.strip
				valid_resource_dir?(dir) ? dir : nil
			rescue Errno::ENOENT
				nil
			end
			
			# Probe for the resource directory relative to the libclang shared library.
			# @parameter libclang_path [String] Path to the libclang shared library.
			# @returns [String | Nil] The resource directory path, or nil.
			def probe_from_libclang(libclang_path)
				base = ::File.expand_path(::File.dirname(libclang_path))
				
				candidates = []
				candidates.concat Dir.glob(::File.join(base, "..", "lib", "clang", "*"))
				candidates.concat Dir.glob(::File.join(base, "..", "..", "lib", "clang", "*"))
				candidates.concat Dir.glob(::File.join(base, "clang", "*"))
				
				candidates = candidates.map{|p| ::File.expand_path(p)}.uniq
				
				candidates
					.select{|dir| valid_resource_dir?(dir)}
					.sort
					.last
			end
			
			# Check whether a directory looks like a valid clang resource directory.
			# @parameter dir [String | Nil] The directory to check.
			# @returns [Boolean] True if the directory contains expected compiler headers.
			def valid_resource_dir?(dir)
				return false unless dir && ::File.directory?(dir)
				
				inc = ::File.join(dir, "include")
				return false unless ::File.directory?(inc)
				
				::File.exist?(::File.join(inc, "stddef.h")) ||
					::File.exist?(::File.join(inc, "__stddef_size_t.h")) ||
					::File.exist?(::File.join(inc, "stdint.h"))
			end
			
			# Common resource dir search: env override, clang from llvm-config,
			# clang on PATH, probe from loaded libclang.
			# @returns [String | Nil] The resource directory path, or nil.
			def find_resource_dir
				# 1. Explicit override via environment variable.
				env = ENV["LIBCLANG_RESOURCE_DIR"]
				return env if valid_resource_dir?(env)
				
				# 2. Clang binary from llvm-config.
				if llvm_config
					clang_path = ::File.join(llvm_bin_dir, "clang")
					if (dir = resource_dir_from_clang(clang_path))
						return dir
					end
				end
				
				# 3. clang on PATH.
				if (dir = resource_dir_from_clang("clang"))
					return dir
				end
				
				# 4. Probe relative to the loaded libclang shared library.
				if @libclang_loaded_path && (dir = probe_from_libclang(@libclang_loaded_path))
					return dir
				end
				
				nil
			end
		end
	end
end
