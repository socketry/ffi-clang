# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		# Linux-specific clang configuration.
		class LinuxArgs < Args
			private
			
			def find_libclang_paths
				prefix = llvm_library_dir
				
				paths = versions.flat_map do |version|
					5.downto(0).map do |minor|
						libclang_path(prefix, "libclang.so.#{version}.#{minor}")
					end
				end
				
				paths.concat(versions.map do |version|
					libclang_path(prefix, "libclang.so.#{version}")
				end)
				
				paths << libclang_path(prefix, "libclang.so")
			end
			
			def libclang_path(prefix, name)
				prefix ? ::File.join(prefix, name) : name
			end
		end
	end
end
