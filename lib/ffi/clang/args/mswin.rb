# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		# MSVC-specific clang configuration. Discovers libclang and system
		# include paths from the Visual Studio installation:
		#
		# 1. Find the VS installation path via vswhere.exe
		# 2. Call vcvarsall.bat to set up the MSVC developer environment
		# 3. Run clang-cl -v -E -x c++ NUL in that environment
		# 4. Parse the "#include <...> search starts here:" block from the output
		# 5. Inject each discovered path as -I into parse_translation_unit
		class MswinArgs < Args
			VSWHERE = "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
			
			# Pin libclang in memory so Windows will not unload it at exit.
			#
			# LLVM's rpmalloc allocator registers Fiber Local Storage (FLS)
			# callbacks via FlsAlloc but does not call FlsFree on
			# DLL_PROCESS_DETACH (LLVM bug #154361, fixed in LLVM 22.1.0 by
			# https://github.com/llvm/llvm-project/pull/171465).
			# Pinning with GET_MODULE_HANDLE_EX_FLAG_PIN prevents the unload
			# so the FLS callbacks remain valid through process shutdown.
			#
			# @parameter library [FFI::DynamicLibrary] The loaded libclang library.
			def post_load(library)
				symbol = library.find_symbol("clang_getClangVersion")
				return unless symbol
				
				kernel32 = FFI::DynamicLibrary.open("kernel32", 0)
				get_module_handle_ex_w = kernel32.find_function("GetModuleHandleExW")
				return unless get_module_handle_ex_w
				
				get_module_handle_ex_flag_from_address = 0x4
				get_module_handle_ex_flag_pin = 0x1
				flags = get_module_handle_ex_flag_from_address | get_module_handle_ex_flag_pin
				handle_out = FFI::MemoryPointer.new(:pointer)
				pin = FFI::Function.new(:bool, [:uint, :pointer, :pointer], get_module_handle_ex_w)
				pin.call(flags, symbol, handle_out)
			end
			
			private
			
			
			def find_libclang_paths
				if llvm_bin_dir
					return [::File.join(llvm_bin_dir, "libclang.dll")]
				end
				
				if (vs_llvm = vs_llvm_dir)
					return [::File.join(vs_llvm, "bin", "libclang.dll")]
				end
				
				["libclang.dll"]
			end
			
			# Mswin skips "clang on PATH" — uses clang-cl probe instead.
			def find_resource_dir
				# 1. Explicit override via environment variable.
				env = ENV["LIBCLANG_RESOURCE_DIR"]
				return env if valid_resource_dir?(env)
				
				# 2. clang-cl next to the loaded libclang.
				if @libclang_loaded_path
					clang_cl = ::File.join(::File.dirname(@libclang_loaded_path), "clang-cl.exe")
					if ::File.exist?(clang_cl) && (dir = resource_dir_from_clang(clang_cl))
						return dir
					end
				end
				
				# 3. Probe relative to the loaded libclang shared library.
				if @libclang_loaded_path && (dir = probe_from_libclang(@libclang_loaded_path))
					return dir
				end
				
				nil
			end
			
			def extra_args(command_line_args)
				args = []
				
				system_includes.each do |path|
					unless command_line_args.include?(path)
						args.push("-isystem", path)
					end
				end
				
				args
			end
			
			# Parse system include paths from clang-cl running in a VS developer environment.
			# @returns [Array(String)] System include directories.
			def system_includes
				@system_includes ||= find_system_includes
			end
			
			def find_system_includes
				vs_path = vs_installation_path
				return [] unless vs_path
				
				vcvarsall = ::File.join(vs_path, "VC", "Auxiliary", "Build", "vcvarsall.bat")
				return [] unless ::File.exist?(vcvarsall)
				
				clang_cl = find_clang_cl
				return [] unless clang_cl
				
				arch = RbConfig::CONFIG["target_cpu"] == "x64" ? "x64" : "arm64"
				cmd = "cmd /c \"call \"#{vcvarsall}\" #{arch} >nul 2>&1 && \"#{clang_cl}\" -v -E -x c++ NUL 2>&1\""
				
				stdout, _status = Open3.capture2(cmd)
				parse_include_paths(stdout)
			rescue Errno::ENOENT
				[]
			end
			
			# Find clang-cl.exe — next to loaded libclang, or in VS LLVM dir.
			# @returns [String | Nil] Path to clang-cl.exe, or nil.
			def find_clang_cl
				if @libclang_loaded_path
					path = ::File.join(::File.dirname(@libclang_loaded_path), "clang-cl.exe")
					return path if ::File.exist?(path)
				end
				
				if (vs_llvm = vs_llvm_dir)
					path = ::File.join(vs_llvm, "bin", "clang-cl.exe")
					return path if ::File.exist?(path)
				end
				
				nil
			end
			
			# Parse the #include <...> search paths from clang -v output.
			# @parameter output [String] The combined stdout/stderr from clang-cl -v.
			# @returns [Array(String)] The include directories.
			def parse_include_paths(output)
				paths = []
				in_search_list = false
				
				output.each_line do |line|
					line = line.strip
					
					if line == "#include <...> search starts here:"
						in_search_list = true
					elsif line == "End of search list."
						break
					elsif in_search_list && !line.empty?
						paths << line
					end
				end
				
				paths
			end
			
			# Find the VS installation path using vswhere.
			# @returns [String | Nil] Path like "C:/Program Files/Microsoft Visual Studio/18/Insiders", or nil.
			def vs_installation_path
				if defined?(@vs_installation_path)
					return @vs_installation_path
				end
				
				@vs_installation_path = find_vs_installation_path
			end
			
			def find_vs_installation_path
				return nil unless ::File.exist?(VSWHERE)
				
				stdout, _stderr, status = Open3.capture3(
					VSWHERE, "-latest", "-products", "*", "-prerelease",
					"-requires", "Microsoft.VisualStudio.Component.VC.Llvm.Clang",
					"-property", "installationPath"
				)
				return nil unless status.success?
				
				path = stdout.strip
				path.empty? ? nil : path
			rescue Errno::ENOENT
				nil
			end
			
			# Find the VS-bundled LLVM directory.
			# @returns [String | Nil] Path like ".../VC/Tools/Llvm/x64", or nil.
			def vs_llvm_dir
				vs_path = vs_installation_path
				return nil unless vs_path
				
				arch = RbConfig::CONFIG["target_cpu"] == "x64" ? "x64" : "ARM64"
				llvm_dir = ::File.join(vs_path, "VC", "Tools", "Llvm", arch)
				::File.directory?(llvm_dir) ? llvm_dir : nil
			end
		end
	end
end
