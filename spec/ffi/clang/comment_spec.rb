# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2024, by Charlie Savage.

describe Comment do
	let(:cursor) {Index.new.parse_translation_unit(fixture_path("docs.cc")).cursor}
	let (:comment) {find_by_kind(cursor, :cursor_function).comment}
	
	it "can be obtained from a cursor" do
		expect(comment).to be_kind_of(Comment)
		expect(comment).to be_kind_of(FullComment)
		expect(comment.kind).to equal(:comment_full)
	end
	
	it "can parse the brief description" do
		para = comment.child
		expect(para.kind).to equal(:comment_paragraph)
		expect(para).to be_kind_of(ParagraphComment)
		text = para.child
		expect(text.kind).to equal(:comment_text)
		expect(text).to be_kind_of(TextComment)
		expect(text.text.strip).to eq("Short explanation")
	end
	
	it "can parse the longer description" do
		para = comment.child(1)
		expect(para.kind).to equal(:comment_paragraph)
		expect(para.num_children).to equal(2)
		
		lines = (0..para.num_children-1).map do |i|
			para.child(i).text
		end
		
		expect(lines).to eq([
			" This is a longer explanation",
			" that spans multiple lines"
		])
	end
	
	it "has working helpers" do
		expect(comment.num_children).to equal(8)
		
		para = comment.child(1)
		expect(para.text).to eq(" This is a longer explanation\n that spans multiple lines")
	end
	
	it "#each returns an Enumerator if no block is given" do
		enumerator = comment.each
		expect(enumerator).to be_kind_of(Enumerator)
		expect(enumerator.to_a.map(&:kind)).to eq(comment.children.map(&:kind))
	end
	
	it "understands params" do
		[["input", " some input\n "], ["flags", " some flags\n "]].each_with_index do |v, child_idx|
			param = comment.child(3 + child_idx)
			expect(param).to be_kind_of(ParamCommandComment)
			
			expect(param.valid_index?).to be_truthy
			expect(param.index).to be == child_idx
			expect(param.name).to be == v[0]
			expect(param.child.text).to be == v[1]
			expect(param.comment).to be == v[1]
		end
	end
	
	describe "#whitespace?" do
		it "checks the comment is whitespace" do
			expect(comment.child.whitespace?).to be false
		end
	end
	
	describe "#has_trailing_newline?" do
		it "checks the content has a traling newline" do
			expect(comment.child.has_trailing_newline?).to be false
		end
	end
	
	context "comment_null" do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "no_comment_function"
			end
		end
		
		let(:comment) {comment_cursor.comment}
		
		it "is null comment" do
			expect(comment).to be_kind_of(Comment)
			expect(comment.kind).to eq(:comment_null)
			expect(comment.text).to eq("")
		end
	end
	
	context "unknown comment type" do
		let(:comment) {"foobar"}
		
		it "raises NotImplementedError" do
			expect(Lib).to receive(:comment_get_kind).with(comment).and_return(:xxx_yyy_zzzz)
			expect{Comment.build_from(comment)}.to raise_error(NotImplementedError)
		end
	end
	
	describe HTMLStartTagComment do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "b_function"
			end
		end
		
		let(:comment) {comment_cursor.comment}
		let(:paragraph) {comment_cursor.comment.child}
		let(:html_start_tag_comments) {paragraph.children.select{|c| c.kind == :comment_html_start_tag}}
		
		it "can be obtained from cursor" do
			expect(comment).to be_kind_of(FullComment)
			expect(comment.kind).to equal(:comment_full)
			expect(paragraph).to be_kind_of(ParagraphComment)
			expect(html_start_tag_comments.first).to be_kind_of(HTMLStartTagComment)
			expect(html_start_tag_comments.size).to eq(2)
		end
		
		describe "#tag" do
			it "returns HTML tag name" do
				expect(html_start_tag_comments[0].tag).to eq("br")
				expect(html_start_tag_comments[1].tag).to eq("a")
			end
			
			it "is alias method of #name" do
				expect(html_start_tag_comments[0].name).to eq("br")
				expect(html_start_tag_comments[1].name).to eq("a")
			end
		end
		
		describe "#text" do
			it "returns HTML tag as string" do
				expect(html_start_tag_comments[0].text.strip).to eq("<br/>")
				expect(html_start_tag_comments[1].text.strip).to eq('<a href="http://example.org/">')
			end
		end
		
		describe "#self_closing?" do
			it "checks the tag is self-closing" do
				expect(html_start_tag_comments[0].self_closing?).to be true
				expect(html_start_tag_comments[1].self_closing?).to be false
			end
		end
		
		describe "#num_attrs" do
			it "returns the number of attributes" do
				expect(html_start_tag_comments[0].num_attrs).to eq(0)
				expect(html_start_tag_comments[1].num_attrs).to eq(1)
			end
		end
		
		describe "#attrs" do
			it "returns attributes as Array of Hash" do
				expect(html_start_tag_comments[0].attrs).to eq([])
				expect(html_start_tag_comments[1].attrs).to eq([{name: "href", value: "http://example.org/"}])
			end
		end
	end
	
	describe HTMLEndTagComment do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "b_function"
			end
		end
		
		let(:comment) {comment_cursor.comment}
		let(:paragraph) {comment_cursor.comment.child}
		let(:html_end_tag_comment) {paragraph.children.select{|c| c.kind == :comment_html_end_tag}.first}
		
		it "can be obtained from cursor" do
			expect(comment).to be_kind_of(FullComment)
			expect(comment.kind).to equal(:comment_full)
			expect(paragraph).to be_kind_of(ParagraphComment)
			expect(html_end_tag_comment).to be_kind_of(HTMLEndTagComment)
		end
		
		describe "#tag" do
			it "returns HTML tag name" do
				expect(html_end_tag_comment.tag).to eq("a")
			end
			
			it "is alias method of #name" do
				expect(html_end_tag_comment.name).to eq("a")
			end
		end
		
		describe "#text" do
			it "returns HTML tag as string" do
				expect(html_end_tag_comment.text.strip).to eq("</a>")
			end
		end
	end
	
	describe FullComment do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_function"
			end
		end
		let(:comment) {comment_cursor.comment}
		
		it "can be obtained from cursor" do
			expect(comment).to be_kind_of(FullComment)
			expect(comment.kind).to equal(:comment_full)
		end
		
		describe "#to_html" do
			it "converts a given full parsed comment to an HTML fragment" do
				expect(comment.to_html).to be_kind_of(String)
				expect(comment.to_html).to eq('<p class="para-brief"> this is a function.</p>')
			end
		end
		
		describe "#to_xml" do
			it "converts a given full parsed comment to an XML document" do
				expect(comment.to_xml).to be_kind_of(String)
			end
		end
		
		describe "#text" do
			it "returns combined text from children" do
				text = comment.text
				expect(text).to be_kind_of(String)
				expect(text).to include("this is a function")
			end
		end
	end
	
	describe BlockCommandComment do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_function"
			end
		end
		let(:comment) {comment_cursor.comment}
		let(:block_cmd_comment) {comment.children.select{|c| c.kind == :comment_block_command}.first}
		
		it "can be obtained from cursor" do
			expect(comment).to be_kind_of(FullComment)
			expect(comment.kind).to equal(:comment_full)
			expect(block_cmd_comment).to be_kind_of(BlockCommandComment)
			expect(block_cmd_comment.child).to be_kind_of(ParagraphComment)
		end
		
		describe "#name" do
			it "returns the name of the block command" do
				expect(block_cmd_comment.name).to eq("brief")
			end
		end
		
		describe "#paragraph" do
			it "returns the paragraph" do
				expect(block_cmd_comment.paragraph).to be_kind_of(ParagraphComment)
			end
		end
		
		describe "#num_args" do
			it "returns the number of word-like arguments" do
				expect(block_cmd_comment.num_args).to eq(0)
			end
		end
		
		describe "#args" do
			it "returns word-like arguments" do
				expect(block_cmd_comment.args).to be_kind_of(Array)
				expect(block_cmd_comment.args).to eq([])
			end
			
			#TODO: needs tests with comments which have arguments
		end
		
		describe "#text" do
			it "returns readble text that includes children's comments" do
				expect(block_cmd_comment.text).to be_kind_of(String)
				expect(block_cmd_comment.text.strip).to eq("this is a function.")
			end
			
			it "is a alias method of #comment" do
				expect(block_cmd_comment.comment).to eq(block_cmd_comment.text)
			end
		end
	end
	
	describe InlineCommandComment do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "d_function"
			end
		end
		let(:comment) {comment_cursor.comment}
		let(:inline_command_comments) {comment.child.children.select{|c| c.kind == :comment_inline_command}}
		
		it "can be obtained from cursor" do
			expect(comment).to be_kind_of(FullComment)
			expect(comment.kind).to equal(:comment_full)
			expect(comment.child).to be_kind_of(ParagraphComment)
			expect(inline_command_comments.size).to eq(2)
		end
		
		describe "#name" do
			it "returns the name of the inline command" do
				expect(inline_command_comments[0].name).to eq("em")
				expect(inline_command_comments[1].name).to eq("b")
			end
		end
		
		describe "#render_kind" do
			it "returns the most appropriate rendering mode" do
				expect(inline_command_comments[0].render_kind).to eq(:emphasized)
				expect(inline_command_comments[1].render_kind).to eq(:bold)
			end
		end
		
		describe "#num_args" do
			it "returns number of command arguments" do
				expect(inline_command_comments[0].num_args).to eq(1)
				expect(inline_command_comments[1].num_args).to eq(1)
			end
		end
		
		describe "#args" do
			it "returns arguments as Array" do
				expect(inline_command_comments[0].args).to eq(["foo"])
				expect(inline_command_comments[1].args).to eq(["bar"])
			end
		end
		
		describe "#text" do
			it "returns readble text" do
				expect(inline_command_comments[0].text.strip).to eq("foo")
				expect(inline_command_comments[1].text.strip).to eq("bar")
			end
		end
	end
	
	describe VerbatimBlockCommandComment do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "e_function"
			end
		end
		let(:comment) {comment_cursor.comment}
		let(:verb_block_cmd_comment) {comment.children.select{|c| c.kind == :comment_verbatim_block_command}.first}
		
		it "can be obtained from cursor" do
			expect(comment).to be_kind_of(FullComment)
			expect(comment.kind).to equal(:comment_full)
			expect(verb_block_cmd_comment).to be_kind_of(VerbatimBlockCommandComment)
		end
		
		describe "#text" do
			it "returns readble text" do
				expect(verb_block_cmd_comment.text).to eq("  foo bar\n  baz")
			end
		end
	end
	
	describe VerbatimBlockLineComment do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "e_function"
			end
		end
		let(:comment) {comment_cursor.comment}
		let(:verb_block_cmd_comment) {comment.children.select{|c| c.kind == :comment_verbatim_block_command}.first}
		let(:verb_block_line_comments) {verb_block_cmd_comment.children}
		
		it "can be obtained from cursor" do
			expect(comment).to be_kind_of(FullComment)
			expect(comment.kind).to equal(:comment_full)
			expect(verb_block_cmd_comment).to be_kind_of(VerbatimBlockCommandComment)
			expect(verb_block_line_comments.first).to be_kind_of(VerbatimBlockLineComment)
			expect(verb_block_line_comments.size).to eq(2)
		end
		
		describe "#text" do
			it "returns readble text" do
				expect(verb_block_line_comments[0].text.strip).to eq("foo bar")
				expect(verb_block_line_comments[1].text.strip).to eq("baz")
			end
		end
	end
	
	describe VerbatimLine do
		# TODO: how to generate this comment?
	end
	
	describe ParamCommandComment do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "a_function"
			end
		end
		let(:comment) {comment_cursor.comment}
		let(:param_cmd_comments) {comment.children.select{|c| c.kind == :comment_param_command}}
		
		it "can be obtained from cursor" do
			expect(comment).to be_kind_of(FullComment)
			expect(comment.kind).to equal(:comment_full)
			expect(param_cmd_comments.first).to be_kind_of(ParamCommandComment)
			expect(param_cmd_comments.size).to eq(4)
		end
		
		describe "#text" do
			it "returns readble text" do
				expect(param_cmd_comments[0].text.strip).to eq("some input")
				expect(param_cmd_comments[1].text.strip).to eq("some flags")
			end
		end
		
		describe "#direction_explicit?" do
			it "checks the direction is specified explicitly" do
				expect(param_cmd_comments[0].direction_explicit?).to be true
				expect(param_cmd_comments[3].direction_explicit?).to be false
			end
		end
		
		describe "#direction" do
			it "returns parameter passing direction" do
				expect(param_cmd_comments[0].direction).to eq(:pass_direction_in)
				expect(param_cmd_comments[1].direction).to eq(:pass_direction_out)
				expect(param_cmd_comments[2].direction).to eq(:pass_direction_inout)
				expect(param_cmd_comments[3].direction).to eq(:pass_direction_in)
			end
		end
	end
	
	describe TParamCommandComment do
		let(:comment_cursor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function_template and child.spelling == "c_function"
			end
		end
		let(:comment) {comment_cursor.comment}
		let(:tparam_cmd_comments) {comment.children.select{|c| c.kind == :comment_tparam_command}}
		
		it "can be obtained from cursor" do
			expect(comment).to be_kind_of(FullComment)
			expect(comment.kind).to equal(:comment_full)
			expect(tparam_cmd_comments.first).to be_kind_of(TParamCommandComment)
			expect(tparam_cmd_comments.size).to eq(3)
		end
		
		describe "#text" do
			it "returns readble text" do
				expect(tparam_cmd_comments[0].text.strip).to eq("some type of foo")
				expect(tparam_cmd_comments[1].text.strip).to eq("some type of bar")
			end
		end
		
		describe "#name" do
			it "returns template parameter name" do
				expect(tparam_cmd_comments[0].name).to eq("T1")
				expect(tparam_cmd_comments[1].name).to eq("T2")
				expect(tparam_cmd_comments[2].name).to eq("T3")
			end
		end
		
		describe "#valid_position?" do
			it "checks this parameter has valid position" do
				expect(tparam_cmd_comments[0].valid_position?).to be true
			end
		end
		
		describe "#depth" do
			it "returns nesting depth of this parameter" do
				expect(tparam_cmd_comments[0].depth).to eq(1)
				expect(tparam_cmd_comments[1].depth).to eq(2)
				expect(tparam_cmd_comments[2].depth).to eq(1)
			end
		end
		
		describe "#index" do
			it "returns index of the parameter at the given nesting depth" do
				expect(tparam_cmd_comments[0].index(0)).to eq(0)
				expect(tparam_cmd_comments[1].index(0)).to eq(1)
				expect(tparam_cmd_comments[1].index(1)).to eq(0)
				expect(tparam_cmd_comments[2].index(0)).to eq(1)
			end
		end
	end
end
