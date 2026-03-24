# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2014, by George Pimm.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2026, by Charlie Savage.

module FFI
	module Clang
		module Lib
			# FFI struct representing a comment in the libclang AST.
			# @private
			class CXComment < FFI::Struct
				layout(
					:ast_node, :pointer,
					:translation_unit, :pointer
				)
			end
			
			enum :kind, [
				:comment_null, 0,
				:comment_text, 1,
				:comment_inline_command, 2,
				:comment_html_start_tag, 3,
				:comment_html_end_tag, 4,
				:comment_paragraph, 5,
				:comment_block_command, 6,
				:comment_param_command, 7,
				:comment_tparam_command, 8,
				:comment_verbatim_block_command, 9,
				:comment_verbatim_block_line, 10,
				:comment_verbatim_line, 11,
				:comment_full, 12,
			]
			
			enum :render_kind, [
				:normal,
				:bold,
				:monospaced,
				:emphasized,
				:anchor
			]
			
			enum :pass_direction, [
				:pass_direction_in, 0,
				:pass_direction_out, 1,
				:pass_direction_inout, 2
			]
			
			# common functions
			attach_function :comment_get_kind, :clang_Comment_getKind, [CXComment.by_value], :kind
			attach_function :comment_get_num_children, :clang_Comment_getNumChildren, [CXComment.by_value], :uint
			attach_function :comment_get_child, :clang_Comment_getChild, [CXComment.by_value, :uint], CXComment.by_value
			attach_function :comment_is_whitespace, :clang_Comment_isWhitespace, [CXComment.by_value], :uint
			
			# TextComment functions
			attach_function :text_comment_get_text, :clang_TextComment_getText, [CXComment.by_value], CXString.by_value
			
			# InlineCommandComment functions
			attach_function :inline_command_comment_get_command_name, :clang_InlineCommandComment_getCommandName, [CXComment.by_value], CXString.by_value
			attach_function :inline_command_comment_get_num_args, :clang_InlineCommandComment_getNumArgs, [CXComment.by_value], :uint
			attach_function :inline_content_comment_has_trailing_newline, :clang_InlineContentComment_hasTrailingNewline, [CXComment.by_value], :uint
			attach_function :inline_command_comment_get_render_kind, :clang_InlineCommandComment_getRenderKind, [CXComment.by_value], :render_kind
			attach_function :inline_command_comment_get_arg_text, :clang_InlineCommandComment_getArgText, [CXComment.by_value, :uint], CXString.by_value
			
			# HTMLTagComment functions
			attach_function :html_tag_comment_get_as_string, :clang_HTMLTagComment_getAsString, [CXComment.by_value], CXString.by_value
			attach_function :html_tag_comment_get_tag_name, :clang_HTMLTagComment_getTagName, [CXComment.by_value], CXString.by_value
			attach_function :html_start_tag_comment_is_self_closing, :clang_HTMLStartTagComment_isSelfClosing, [CXComment.by_value], :uint
			attach_function :html_start_tag_comment_get_num_attrs, :clang_HTMLStartTag_getNumAttrs, [CXComment.by_value], :uint
			attach_function :html_start_tag_comment_get_attr_name, :clang_HTMLStartTag_getAttrName, [CXComment.by_value, :uint], CXString.by_value
			attach_function :html_start_tag_comment_get_attr_value, :clang_HTMLStartTag_getAttrValue,[CXComment.by_value, :uint], CXString.by_value
			
			# ParamCommandComment functions
			attach_function :param_command_comment_is_direction_explicit, :clang_ParamCommandComment_isDirectionExplicit, [CXComment.by_value], :uint
			attach_function :param_command_comment_get_direction, :clang_ParamCommandComment_getDirection, [CXComment.by_value], :pass_direction
			attach_function :param_command_comment_get_param_name, :clang_ParamCommandComment_getParamName, [CXComment.by_value], CXString.by_value
			attach_function :param_command_comment_is_param_index_valid, :clang_ParamCommandComment_isParamIndexValid, [CXComment.by_value], :uint
			attach_function :param_command_comment_get_param_index, :clang_ParamCommandComment_getParamIndex, [CXComment.by_value], :uint
			
			# TParamCommandComment functions
			attach_function :tparam_command_comment_get_param_name, :clang_TParamCommandComment_getParamName, [CXComment.by_value], CXString.by_value
			attach_function :tparam_command_comment_is_param_position_valid, :clang_TParamCommandComment_isParamPositionValid, [CXComment.by_value], :uint
			attach_function :tparam_command_comment_get_depth, :clang_TParamCommandComment_getDepth, [CXComment.by_value], :uint
			attach_function :tparam_command_comment_get_index, :clang_TParamCommandComment_getIndex, [CXComment.by_value, :uint], :uint
			
			# BlockCommandComment functions
			attach_function :block_command_comment_get_paragraph, :clang_BlockCommandComment_getParagraph, [CXComment.by_value], CXComment.by_value
			attach_function :block_command_comment_get_command_name, :clang_BlockCommandComment_getCommandName, [CXComment.by_value], CXString.by_value
			attach_function :block_command_comment_get_num_args, :clang_BlockCommandComment_getNumArgs, [CXComment.by_value], :uint
			attach_function :block_command_comment_get_arg_text, :clang_BlockCommandComment_getArgText, [CXComment.by_value, :uint], CXString.by_value
			
			# VerbatimBlockLineComment functions
			attach_function :verbatim_block_line_comment_get_text, :clang_VerbatimBlockLineComment_getText, [CXComment.by_value], CXString.by_value
			
			# VerbatimLineComment functions
			attach_function :verbatim_line_comment_get_text, :clang_VerbatimLineComment_getText, [CXComment.by_value], CXString.by_value
			
			# FullComment functions
			attach_function :full_comment_get_as_html, :clang_FullComment_getAsHTML, [CXComment.by_value], CXString.by_value
			attach_function :full_comment_get_as_xml, :clang_FullComment_getAsXML, [CXComment.by_value], CXString.by_value
		end
	end
end
