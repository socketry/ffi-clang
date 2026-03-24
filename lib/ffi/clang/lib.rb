# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010-2012, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013-2014, by Carlos Martín Nieto.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014, by Greg Hazel.
# Copyright, 2014, by Niklas Therning.
# Copyright, 2016, by Mike Dalessio.
# Copyright, 2019, by Hayden Purdy.
# Copyright, 2019, by Dominic Sisnero.
# Copyright, 2020, by Zete Lui.
# Copyright, 2023-2026, by Charlie Savage.
# Copyright, 2024, by msepga.

require "ffi"

require_relative "error"
require_relative "platform"
require_relative "args/args"
require_relative "args/linux"
require_relative "args/darwin"
require_relative "args/mingw"
require_relative "args/mswin"

module FFI
	module Clang
		# @namespace
		module Lib
			extend FFI::Library
			
			@args = Args.create
			
			ffi_lib @args.libclang_paths
			
			@args.libclang_loaded_path = ffi_libraries.first&.name
			
			@args.post_load(ffi_libraries.first)
			
			# The platform-specific clang configuration.
			# @returns [Args] The args instance.
			def self.args
				@args
			end
			
			# Convert an options hash to a bitmask for libclang enums.
			# @parameter enum [FFI::Enum] The enum type.
			# @parameter opts [Array(Symbol)] The array of option symbols.
			# @returns [Integer] The bitmask representing the options.
			# @raises [Error] If an unknown option is provided.
			def self.bitmask_from(enum, opts)
				bitmask = 0
				
				opts.each do |symbol|
					if int = enum[symbol]
						bitmask |= int
					else
						raise Error, "unknown option: #{symbol}, expected one of #{enum.symbols}"
					end
				end
				
				bitmask
			end
			
			# Convert a bitmask to an array of option symbols.
			# @parameter enum [FFI::Enum] The enum type.
			# @parameter bitmask [Integer] The bitmask to convert.
			# @returns [Array(Symbol)] The array of option symbols.
			# @raises [Error] If unknown bits are set in the bitmask.
			def self.opts_from(enum, bitmask)
				bit = 1
				result = []
				while bitmask != 0
					if bitmask & 1
						if symbol = enum[bit]
							result << symbol
						else
							raise(Error, "unknown values: #{bit}, expected one of #{enum.symbols}")
						end
					end
					bitmask >>= 1
					bit <<= 1
				end
				result
			end
		end
	end
end
