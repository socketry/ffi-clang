# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

describe FFI::Clang::Cursor do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
	let(:cursor) {translation_unit.cursor}
	
	describe "#storage_class" do
		let(:extern_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "extern_var"
			end
		end
		
		let(:static_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "static_var"
			end
		end
		
		let(:global_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end
		end
		
		it "returns :sc_extern for extern variables" do
			expect(extern_var.storage_class).to eq(:sc_extern)
		end
		
		it "returns :sc_static for static variables" do
			expect(static_var.storage_class).to eq(:sc_static)
		end
		
		it "returns :sc_none for normal global variables" do
			expect(global_var.storage_class).to eq(:sc_none)
		end
	end
	
	describe "#function_inlined?" do
		let(:inline_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "inline_func"
			end
		end
		
		let(:visible_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
		end
		
		it "returns true for inline functions" do
			expect(inline_func.function_inlined?).to eq(true)
		end
		
		it "returns false for non-inline functions" do
			expect(visible_func.function_inlined?).to eq(false)
		end
	end
	
	describe "#visibility" do
		let(:hidden_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "hidden_func"
			end
		end
		
		let(:visible_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
		end
		
		it "returns :visibility_hidden for hidden functions" do
			expect(hidden_func.visibility).to eq(:visibility_hidden)
		end
		
		it "returns :visibility_default for default visibility functions" do
			expect(visible_func.visibility).to eq(:visibility_default)
		end
	end
	
	describe "#offset_of_field" do
		let(:field_a) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "field_a" and parent.spelling == "FieldStruct"
			end
		end
		
		it "returns the offset in bits" do
			expect(field_a.offset_of_field).to eq(0)
		end
	end
	
	describe "#brief_comment_text" do
		let(:documented_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "documented_func"
			end
		end
		
		it "returns the brief comment text" do
			expect(documented_func.brief_comment_text).to eq("Brief comment on this function.")
		end
	end
	
	describe "#invalid_declaration?" do
		let(:global_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end
		end
		
		it "returns false for valid declarations" do
			expect(global_var.invalid_declaration?).to eq(false)
		end
	end
	
	describe "#has_attrs?" do
		let(:hidden_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "hidden_func"
			end
		end
		
		let(:global_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end
		end
		
		it "returns true for cursors with attributes" do
			expect(hidden_func.has_attrs?).to eq(true)
		end
		
		it "returns false for cursors without attributes" do
			expect(global_var.has_attrs?).to eq(false)
		end
	end
	
	describe "#mangling" do
		let(:visible_func) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
		end
		
		it "returns the mangled name" do
			mangled = visible_func.mangling
			expect(mangled).to be_kind_of(String)
			expect(mangled).not_to be_empty
		end
	end
	
	describe "#var_decl_initializer" do
		let(:initialized_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "initialized_var"
			end
		end
		
		let(:uninitialized_var) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "uninitialized_var"
			end
		end
		
		it "returns the initializer cursor for an initialized variable" do
			init = initialized_var.var_decl_initializer
			expect(init).to be_kind_of(FFI::Clang::Cursor)
			expect(init.kind).not_to eq(:cursor_invalid_file)
		end
		
		it "returns a null cursor for an uninitialized variable" do
			init = uninitialized_var.var_decl_initializer
			expect(init.null?).to be true
		end
	end
	
	describe "#external_symbol" do
		it "returns nil for non-external symbols" do
			func = find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
			expect(func.external_symbol).to be_nil
		end
	end
	
	describe "#reference_name_range" do
		it "returns a source range" do
			func = find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
			range = func.reference_name_range
			expect(range).to be_kind_of(FFI::Clang::SourceRange)
		end
		
		it "accepts name flags" do
			func = find_matching(cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
			range = func.reference_name_range([:want_qualifier, :want_single_piece])
			expect(range).to be_kind_of(FFI::Clang::SourceRange)
		end
	end
	
	describe "#offset_of_base" do
		let(:derived) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "Derived"
			end
		end
		
		it "returns the bit offset of a base class" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			bases = []
			derived.type.visit_base_classes do |base|
				bases << base
			end
			
			expect(bases.length).to eq(2)
			offset = derived.offset_of_base(bases.first)
			expect(offset).to be >= 0
		end
	end
	
	describe "#cxx_manglings" do
		let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("manglings.cpp"), ["-std=c++17"])}
		let(:cursor) {translation_unit.cursor}
		let(:normal_translation_unit) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"), ["-std=c++17"])}
		let(:normal_cursor) {normal_translation_unit.cursor}
		
		let(:constructor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_constructor and parent.spelling == "Widget"
			end
		end
		
		let(:destructor) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_destructor and parent.spelling == "Widget"
			end
		end
		
		let(:visible_func) do
			find_matching(normal_cursor) do |child, parent|
				child.kind == :cursor_function and child.spelling == "visible_func"
			end
		end
		
		it "returns mangled symbols for constructors" do
			manglings = constructor.cxx_manglings
			
			expect(manglings).to be_kind_of(StringSet)
			expect(manglings.to_a).not_to be_empty
			expect(manglings.to_a).to include(constructor.mangling)
			expect(manglings.to_a).to all(be_kind_of(String))
			expect(manglings.to_a).to all(satisfy{|mangling| !mangling.empty?})
		end
		
		it "returns mangled symbols for destructors" do
			manglings = destructor.cxx_manglings
			
			expect(manglings).to be_kind_of(StringSet)
			expect(manglings.to_a).not_to be_empty
			expect(manglings.to_a).to all(be_kind_of(String))
			expect(manglings.to_a).to all(satisfy{|mangling| !mangling.empty?})
		end
		
		it "returns an empty string set for non-constructor cursors" do
			manglings = visible_func.cxx_manglings
			
			expect(manglings).to be_kind_of(StringSet)
			expect(manglings.size).to eq(0)
			expect(manglings.to_a).to eq([])
		end
	end
end
