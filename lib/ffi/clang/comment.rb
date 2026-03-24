# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2014, by George Pimm.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2026, by Charlie Savage.

require_relative "lib/cursor"
require_relative "lib/comment"
require_relative "source_location"

module FFI
	module Clang
		# Represents a documentation comment in parsed source code.
		# This class provides access to structured documentation comments extracted from C/C++ source code.
		# Comments can have different kinds (text, inline commands, HTML tags, block commands, etc.) and can be hierarchical.
		class Comment
			include Enumerable
			
			# Build a comment instance from a low-level comment handle.
			# @parameter comment [FFI::Pointer] The low-level comment handle.
			# @returns [Comment] A comment instance of the appropriate subclass based on the comment kind.
			def self.build_from(comment)
				kind = Lib.comment_get_kind(comment)
				case kind
				when :comment_null
					Comment.new comment
				when :comment_text
					TextComment.new comment
				when :comment_inline_command
					InlineCommandComment.new comment
				when :comment_html_start_tag
					HTMLStartTagComment.new comment
				when :comment_html_end_tag
					HTMLEndTagComment.new comment
				when :comment_paragraph
					ParagraphComment.new comment
				when :comment_block_command
					BlockCommandComment.new comment
				when :comment_param_command
					ParamCommandComment.new comment
				when :comment_tparam_command
					TParamCommandComment.new comment
				when :comment_verbatim_block_command
					VerbatimBlockCommandComment.new comment
				when :comment_verbatim_block_line
					VerbatimBlockLineComment.new comment
				when :comment_verbatim_line
					VerbatimLine.new comment
				when :comment_full
					FullComment.new comment
				else
					raise NotImplementedError, kind
				end
			end
			
			# Get the text content of this comment.
			# @returns [String] The text content, empty string for base Comment class.
			def text
				return ""
			end
			
			# Create a new comment instance.
			# @parameter comment [FFI::Pointer] The low-level comment handle.
			def initialize(comment)
				@comment = comment
			end
			
			# Get the kind of this comment.
			# @returns [Symbol] The comment kind (e.g., :comment_text, :comment_paragraph).
			def kind
				Lib.comment_get_kind(@comment)
			end
			
			# Get the number of child comments.
			# @returns [Integer] The number of child comments.
			def num_children
				Lib.comment_get_num_children(@comment)
			end
			
			# Get a specific child comment by index.
			# @parameter n [Integer] The child index (defaults to 0).
			# @returns [Comment] The child comment at the specified index.
			def child(n = 0)
				Comment.build_from Lib.comment_get_child(@comment, n)
			end
			
			# Get all child comments.
			# @returns [Array<Comment>] An array of all child comments.
			def children
				num_children.times.map{|i| child(i)}
			end
			
			# Check if this comment is whitespace only.
			# @returns [Boolean] True if the comment contains only whitespace.
			def whitespace?
				Lib.comment_is_whitespace(@comment) != 0
			end
			
			# Check if this comment has a trailing newline.
			# @returns [Boolean] True if the comment has a trailing newline.
			def has_trailing_newline?
				Lib.inline_content_comment_has_trailing_newline(@comment) != 0
			end
			
			# Iterate over all child comments.
			# @yields {|comment| ...} Yields each child comment.
			# 	@parameter comment [Comment] The child comment.
			# @returns [Enumerator] If no block is given.
			def each(&block)
				return to_enum(__method__) unless block_given?
				
				num_children.times do |i|
					block.call(child(i))
				end
				
				self
			end
		end
		
		# Represents an HTML tag in a documentation comment.
		class HTMLTagComment < Comment
			# Get the name of the HTML tag.
			# @returns [String] The HTML tag name.
			def name
				Lib.extract_string Lib.html_tag_comment_get_tag_name(@comment)
			end
			alias_method :tag, :name
			
			# Get the text representation of this HTML tag.
			# @returns [String] The HTML tag as a string.
			def text
				Lib.extract_string Lib.html_tag_comment_get_as_string(@comment)
			end
		end
		
		# Represents an HTML start tag in a documentation comment.
		class HTMLStartTagComment < HTMLTagComment
			# Check if this is a self-closing tag.
			# @returns [Boolean] True if the tag is self-closing (e.g., <br/>).
			def self_closing?
				Lib.html_start_tag_comment_is_self_closing(@comment) != 0
			end
			
			# Get the number of attributes on this tag.
			# @returns [Integer] The number of attributes.
			def num_attrs
				Lib.html_start_tag_comment_get_num_attrs(@comment)
			end
			
			# Get all attributes on this tag.
			# @returns [Array<Hash>] An array of hashes with :name and :value keys.
			def attrs
				num_attrs.times.map{|i|
					{
						name: Lib.extract_string(Lib.html_start_tag_comment_get_attr_name(@comment, i)),
							value: Lib.extract_string(Lib.html_start_tag_comment_get_attr_value(@comment, i)),
					}
				}
			end
		end
		
		# Represents an HTML end tag in a documentation comment.
		class HTMLEndTagComment < HTMLTagComment
		end
		
		# Represents a paragraph comment containing text and inline content.
		class ParagraphComment < Comment
			# Get the text content by joining all child text with newlines.
			# @returns [String] The paragraph text content.
			def text
				self.map(&:text).join("\n")
			end
		end
		
		# Represents a plain text comment.
		class TextComment < Comment
			# Get the text content of this comment.
			# @returns [String] The text content.
			def text
				Lib.extract_string Lib.text_comment_get_text(@comment)
			end
		end
		
		# Represents an inline command comment (e.g., \c, \p).
		class InlineCommandComment < Comment
			# Get the command name.
			# @returns [String] The inline command name (e.g., "c", "p").
			def name
				Lib.extract_string Lib.inline_command_comment_get_command_name(@comment)
			end
			
			# Get the render kind for this inline command.
			# @returns [Symbol] The render kind.
			def render_kind
				Lib.inline_command_comment_get_render_kind(@comment)
			end
			
			# Get the number of arguments to this command.
			# @returns [Integer] The number of arguments.
			def num_args
				Lib.inline_command_comment_get_num_args(@comment)
			end
			
			# Get all arguments to this command.
			# @returns [Array<String>] An array of argument strings.
			def args
				num_args.times.map{|i|
					Lib.extract_string Lib.inline_command_comment_get_arg_text(@comment, i)
				}
			end
			
			# Get the text by joining all arguments.
			# @returns [String] The joined argument text.
			def text
				args.join
			end
		end
		
		# Represents a block command comment (e.g., \brief, \return).
		class BlockCommandComment < Comment
			# Get the command name.
			# @returns [String] The block command name (e.g., "brief", "return").
			def name
				Lib.extract_string Lib.block_command_comment_get_command_name(@comment)
			end
			
			# Get the paragraph comment associated with this block command.
			# @returns [Comment] The paragraph comment.
			def paragraph
				Comment.build_from Lib.block_command_comment_get_paragraph(@comment)
			end
			
			# Get the text content from the paragraph.
			# @returns [String] The text content.
			def text
				self.paragraph.text
			end
			alias_method :comment, :text
			
			# Get the number of arguments to this command.
			# @returns [Integer] The number of arguments.
			def num_args
				Lib.block_command_comment_get_num_args(@comment)
			end
			
			# Get all arguments to this command.
			# @returns [Array<String>] An array of argument strings.
			def args
				num_args.times.map{|i|
					Lib.extract_string Lib.block_command_comment_get_arg_text(@comment, i)
				}
			end
		end
		
		# Represents a parameter documentation command (e.g., \param, \arg).
		class ParamCommandComment < Comment
			# Get the parameter name being documented.
			# @returns [String] The parameter name.
			def name
				Lib.extract_string Lib.param_command_comment_get_param_name(@comment)
			end
			
			# Get the documentation text for this parameter.
			# @returns [String] The parameter documentation text.
			def text
				self.map(&:text).join("")
			end
			
			alias_method :comment, :text
			
			# Check if the parameter index is valid.
			# @returns [Boolean] True if the parameter index is valid.
			def valid_index?
				Lib.param_command_comment_is_param_index_valid(@comment) != 0
			end
			
			# Get the parameter index in the function signature.
			# @returns [Integer] The zero-based parameter index.
			def index
				Lib.param_command_comment_get_param_index(@comment)
			end
			
			# Check if the parameter direction is explicitly specified.
			# @returns [Boolean] True if the direction is explicit (e.g., [in], [out]).
			def direction_explicit?
				Lib.param_command_comment_is_direction_explicit(@comment) != 0
			end
			
			# Get the parameter direction.
			# @returns [Symbol] The direction (:in, :out, or :in_out).
			def direction
				Lib.param_command_comment_get_direction(@comment)
			end
		end
		
		# Represents a template parameter documentation command (e.g., \tparam).
		class TParamCommandComment < Comment
			# Get the documentation text for this template parameter.
			# @returns [String] The template parameter documentation text.
			def text
				self.child.text
			end
			alias_method :comment, :text
			
			# Get the template parameter name being documented.
			# @returns [String] The template parameter name.
			def name
				Lib.extract_string Lib.tparam_command_comment_get_param_name(@comment)
			end
			
			# Check if the parameter position is valid.
			# @returns [Boolean] True if the position is valid in the template parameter list.
			def valid_position?
				Lib.tparam_command_comment_is_param_position_valid(@comment) != 0
			end
			
			# Get the nesting depth of this template parameter.
			# @returns [Integer] The nesting depth.
			def depth
				Lib.tparam_command_comment_get_depth(@comment)
			end
			
			# Get the index of this template parameter at the specified depth.
			# @parameter depth [Integer] The nesting depth (defaults to 0).
			# @returns [Integer] The index at the specified depth.
			def index(depth = 0)
				Lib.tparam_command_comment_get_index(@comment, depth)
			end
		end
		
		# Represents a verbatim block command comment (e.g., \code, \verbatim).
		class VerbatimBlockCommandComment < Comment
			# Get the text by joining all child lines with newlines.
			# @returns [String] The verbatim block text.
			def text
				children.map(&:text).join("\n")
			end
		end
		
		# Represents a line within a verbatim block comment.
		class VerbatimBlockLineComment < Comment
			# Get the text of this line.
			# @returns [String] The line text.
			def text
				Lib.extract_string Lib.verbatim_block_line_comment_get_text(@comment)
			end
		end
		
		# Represents a verbatim line comment (e.g., \code on a single line).
		class VerbatimLine < Comment
			# Get the text of this verbatim line.
			# @returns [String] The verbatim line text.
			def text
				Lib.extract_string Lib.verbatim_line_comment_get_text(@comment)
			end
		end
		
		# Represents a complete documentation comment with all its components.
		# This is the top-level comment structure that can be converted to HTML or XML.
		class FullComment < Comment
			# Convert this documentation comment to HTML.
			# @returns [String] The HTML representation of the comment.
			def to_html
				Lib.extract_string Lib.full_comment_get_as_html(@comment)
			end
			
			# Convert this documentation comment to XML.
			# @returns [String] The XML representation of the comment.
			def to_xml
				Lib.extract_string Lib.full_comment_get_as_xml(@comment)
			end
			
			# Get the text by collecting and joining all child text.
			# @returns [String] The combined text content with newlines.
			def text
				self.children.collect{|child| child.text.strip}.join("\n")
			end
		end
	end
end
