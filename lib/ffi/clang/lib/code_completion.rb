# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2024-2026, by Charlie Savage.

require_relative "cursor"
require_relative "diagnostic"

module FFI
	module Clang
		module Lib
			typedef :pointer, :CXCompletionString
			
			# FFI struct representing a single code completion result from libclang.
			# @private
			class CXCompletionResult < FFI::Struct
				layout(
					:kind, :cursor_kind,
					:string, :CXCompletionString,
				)
			end
			
			# FFI struct representing the results of code completion from libclang.
			# @private
			class CXCodeCompleteResults < FFI::Struct
				layout(
					:results, :pointer,
					:num, :uint,
				)
			end
			
			enum :completion_chunk_kind, [
				:optional,
				:typed_text,
				:text,
				:placeholder,
				:informative,
				:current_parameter,
				:left_paren,
				:right_paren,
				:left_bracket,
				:right_bracket,
				:left_brace,
				:right_brace,
				:left_angle,
				:right_angle,
				:comma,
				:result_type,
				:colon,
				:semi_colon,
				:equal,
				:horizontal_space,
				:vertical_space
			]
			
			CodeCompleteFlags = enum :code_complete_flags, [
				:include_macros, 0x01,
				:include_code_patterns, 0x02,
				:include_brief_comments, 0x04,
				:skip_preamble, 0x08,
				:include_completions_with_fix_its, 0x10
			]
			
			CompletionContext = enum :completion_context, [
				:unexposed, 0,
				:any_type, 1 << 0,
				:any_value, 1 << 1,
				:objc_object_value, 1 << 2,
				:objc_selector_value, 1 << 3,
				:cxx_class_type_value, 1 << 4,
				:dot_member_access, 1 << 5,
				:arrow_member_access, 1 << 6,
				:objc_property_access, 1 << 7,
				:enum_tag, 1 << 8,
				:union_tag, 1 << 9,
				:struct_tag, 1 << 10,
				:class_tag, 1 << 11,
				:namespace, 1 << 12,
				:nested_name_specifier, 1 << 13,
				:objc_interface, 1 << 14,
				:objc_protocol, 1 << 15,
				:objc_category, 1 << 16,
				:objc_instance_message, 1 << 17,
				:objc_class_message, 1 << 18,
				:objc_selector_name, 1 << 19,
				:macro_name, 1 << 20,
				:natural_language, 1 << 21,
				:included_file, 1 << 22,
				:unknown, ((1 << 23) - 1),
			]
			
			# CXCompletionString functions
			attach_function :get_completion_chunk_kind, :clang_getCompletionChunkKind, [:CXCompletionString, :uint], :completion_chunk_kind
			attach_function :get_completion_text, :clang_getCompletionChunkText, [:CXCompletionString, :uint], CXString.by_value
			attach_function :get_completion_chunk_completion_string, :clang_getCompletionChunkCompletionString, [:CXCompletionString, :uint], :CXCompletionString
			attach_function :get_num_completion_chunks, :clang_getNumCompletionChunks, [:CXCompletionString], :uint
			attach_function :get_completion_priority, :clang_getCompletionPriority, [:CXCompletionString], :uint
			attach_function :get_completion_availability, :clang_getCompletionAvailability, [:CXCompletionString], :availability
			attach_function :get_completion_num_annotations, :clang_getCompletionNumAnnotations, [:CXCompletionString], :uint
			attach_function :get_completion_annotation, :clang_getCompletionAnnotation, [:CXCompletionString, :uint], CXString.by_value
			attach_function :get_completion_parent, :clang_getCompletionParent, [:CXCompletionString, :pointer], CXString.by_value
			attach_function :get_completion_brief_comment, :clang_getCompletionBriefComment, [:CXCompletionString], CXString.by_value
			
			# CXCodeCompleteResults functions
			attach_function :get_code_complete_get_num_diagnostics, :clang_codeCompleteGetNumDiagnostics, [CXCodeCompleteResults.by_ref], :uint
			attach_function :get_code_complete_get_diagnostic, :clang_codeCompleteGetDiagnostic, [CXCodeCompleteResults.by_ref, :uint], :CXDiagnostic
			attach_function :get_code_complete_get_contexts, :clang_codeCompleteGetContexts, [CXCodeCompleteResults.by_ref], :ulong_long
			attach_function :get_code_complete_get_container_kind, :clang_codeCompleteGetContainerKind, [CXCodeCompleteResults.by_ref, :pointer], :cursor_kind
			attach_function :get_code_complete_get_container_usr, :clang_codeCompleteGetContainerUSR, [CXCodeCompleteResults.by_ref], CXString.by_value
			attach_function :get_code_complete_get_objc_selector, :clang_codeCompleteGetObjCSelector, [CXCodeCompleteResults.by_ref], CXString.by_value
			
			# Fix-it functions
			attach_function :get_completion_num_fix_its, :clang_getCompletionNumFixIts, [CXCodeCompleteResults.by_ref, :uint], :uint
			attach_function :get_completion_fix_it, :clang_getCompletionFixIt, [CXCodeCompleteResults.by_ref, :uint, :uint, :pointer], CXString.by_value
			
			# Other functions
			attach_function :code_complete_at, :clang_codeCompleteAt, [:CXTranslationUnit, :string, :uint, :uint, :pointer, :uint, :uint], CXCodeCompleteResults.by_ref
			attach_function :dispose_code_complete_results, :clang_disposeCodeCompleteResults, [CXCodeCompleteResults.by_ref], :void
			attach_function :get_cursor_completion_string, :clang_getCursorCompletionString, [CXCursor.by_value], :CXCompletionString
			attach_function :default_code_completion_options, :clang_defaultCodeCompleteOptions, [], :uint
			attach_function :sort_code_completion_results, :clang_sortCodeCompletionResults, [:pointer, :uint], :void
		end
	end
end
