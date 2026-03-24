# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2026, by Charlie Savage.

require_relative "lib/token"
require_relative "lib/cursor"
require_relative "source_location"

module FFI
	module Clang
		# Represents a collection of tokens from a source range.
		class Tokens < AutoPointer
			include Enumerable
			
			# @attribute [Integer] The number of tokens.
			attr_reader :size
			
			# @attribute [Array(Token)] The array of tokens.
			attr_reader :tokens
			
			# Initialize a token collection.
			# @parameter pointer [FFI::Pointer] The tokens pointer.
			# @parameter token_size [Integer] The number of tokens.
			# @parameter translation_unit [TranslationUnit] The parent translation unit.
			def initialize(pointer, token_size, translation_unit)
				super(Lib::TokensPointer.new(pointer, token_size, translation_unit))
				
				@translation_unit = translation_unit
				@size = token_size
				
				@tokens = []
				current = pointer
				token_size.times do
					@tokens << Token.new(current, translation_unit)
					current += Lib::CXToken.size
				end
			end
			
			# Release the tokens pointer.
			# @parameter pointer [Lib::TokensPointer] The tokens pointer to release.
			def self.release(pointer)
				Lib.dispose_tokens(pointer.translation_unit, pointer, pointer.token_size)
			end
			
			# Iterate over each token.
			# @yields {|token| ...} Each token in the collection.
			# 	@parameter token [Token] The token.
			# @returns [Enumerator] If no block is given.
			def each(&block)
				return to_enum(__method__) unless block_given?
				
				@tokens.each(&block)
			end
			
			# Get cursors corresponding to each token.
			# @returns [Array(Cursor)] Array of cursors for each token.
			def cursors
				ptr = MemoryPointer.new(Lib::CXCursor, @size)
				Lib.annotate_tokens(@translation_unit, self, @size, ptr)
				
				cur_ptr = ptr
				array = []
				@size.times do
					array << Cursor.new(cur_ptr, @translation_unit)
					cur_ptr += Lib::CXCursor.size
				end
				
				return array
			end
		end
		
		# Represents a single token in the source code.
		class Token
			# Owns a single libclang token buffer and disposes it when no longer referenced.
			class Owner < AutoPointer
				# Wrap the token pointer with the metadata needed by `clang_disposeTokens`.
				# @parameter pointer [FFI::Pointer] The libclang token buffer.
				# @parameter translation_unit [TranslationUnit] The translation unit that owns the token.
				def initialize(pointer, translation_unit)
					super Lib::TokensPointer.new(pointer, 1, translation_unit)
				end
				
				# Release the token buffer.
				# @parameter pointer [Lib::TokensPointer] The token pointer to release.
				def self.release(pointer)
					Lib.dispose_tokens(pointer.translation_unit, pointer, pointer.token_size)
				end
			end
			
			# Look up the token that starts at the given source location.
			# @parameter translation_unit [TranslationUnit] The translation unit to query.
			# @parameter location [SourceLocation] The source location where the token should start.
			# @returns [Token | Nil] The token at the location, or `nil` if no token starts there.
			def self.from_location(translation_unit, location)
				token_pointer = Lib.get_token(translation_unit, location.location)
				return nil if token_pointer.null?
				
				owner = Owner.new(token_pointer, translation_unit)
				Token.new(owner, translation_unit, owner)
			end
			
			# Initialize a token.
			# @parameter token [FFI::Pointer] The token pointer.
			# @parameter translation_unit [TranslationUnit] The parent translation unit.
			# @parameter owner [Object | Nil] An object that keeps the token storage alive.
			def initialize(token, translation_unit, owner = nil)
				@token = token
				@translation_unit = translation_unit
				@owner = owner
			end
			
			# Get the kind of this token.
			# @returns [Symbol] The token kind.
			def kind
				Lib.get_token_kind(@token)
			end
			
			# Get the spelling (text) of this token.
			# @returns [String] The token spelling.
			def spelling
				Lib.extract_string Lib.get_token_spelling(@translation_unit, @token)
			end
			
			# Get the location of this token.
			# @returns [ExpansionLocation] The token location.
			def location
				ExpansionLocation.new Lib.get_token_location(@translation_unit, @token)
			end
			
			# Get the extent (source range) of this token.
			# @returns [SourceRange] The token extent.
			def extent
				SourceRange.new Lib.get_token_extent(@translation_unit, @token)
			end
		end
	end
end
