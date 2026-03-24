# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		module Lib
			# FFI struct representing a token in libclang.
			# @private
			class CXToken < FFI::Struct
				layout(
					:int_data, [:uint, 4],
					:ptr_data, :pointer,
				)
			end
			
			# FFI pointer wrapper for token arrays that tracks size and translation unit.
			# @private
			class TokensPointer < FFI::Pointer
				# @attribute [r] token_size
				# 	@returns [Integer] The number of tokens.
				# @attribute [r] translation_unit
				# 	@returns [TranslationUnit] The translation unit these tokens belong to.
				attr_reader :token_size
				attr_reader :translation_unit
				
				# Create a new tokens pointer.
				# @parameter ptr [FFI::Pointer] The pointer to the token array.
				# @parameter token_size [Integer] The number of tokens.
				# @parameter translation_unit [TranslationUnit] The translation unit.
				def initialize(ptr, token_size, translation_unit)
					super ptr
					@token_size = token_size
					@translation_unit = translation_unit
				end
			end
			
			enum :token_kind, [
				:punctuation,
				:keyword,
				:identifier,
				:literal,
				:comment,
			]
			
			attach_function :get_token, :clang_getToken, [:CXTranslationUnit, CXSourceLocation.by_value], :pointer
			attach_function :get_token_kind, :clang_getTokenKind, [CXToken.by_value], :token_kind
			attach_function :get_token_spelling, :clang_getTokenSpelling, [:CXTranslationUnit, CXToken.by_value], CXString.by_value
			attach_function :get_token_location, :clang_getTokenLocation, [:CXTranslationUnit, CXToken.by_value], CXSourceLocation.by_value
			attach_function :get_token_extent, :clang_getTokenExtent, [:CXTranslationUnit, CXToken.by_value], CXSourceRange.by_value
			attach_function :tokenize, :clang_tokenize, [:CXTranslationUnit, CXSourceRange.by_value, :pointer, :pointer], :void
			attach_function :annotate_tokens, :clang_annotateTokens, [:CXTranslationUnit, :pointer, :uint, :pointer], :void
			attach_function :dispose_tokens, :clang_disposeTokens, [:CXTranslationUnit, :pointer, :uint], :void
		end
	end
end
