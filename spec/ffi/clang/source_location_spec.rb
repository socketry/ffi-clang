# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Garry Marshall.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2024-2026, by Charlie Savage.

describe SourceLocation do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("list.c"))}
	let(:translation_unit_location) {translation_unit.cursor.location}
	let(:diagnostic_location) {translation_unit.diagnostics.first.location}
	let(:loc1_translation_unit) {Index.new.parse_translation_unit(fixture_path("location1.c"))}
	let(:loc1_cursor) {find_by_kind(loc1_translation_unit.cursor, :cursor_function)}
	let(:docs_cursor) {Index.new.parse_translation_unit(fixture_path("docs.c")).cursor}
	
	it "should have a nil File if the SourceLocation is for a Translation Unit" do
		expect(translation_unit_location.file).to be_nil
	end
	
	it "should provide a File, line and column for a Diagnostic" do
		expect(diagnostic_location.file).to eq(fixture_path("list.c"))
		expect(diagnostic_location.line).to equal(5)
		expect(diagnostic_location.column).to equal(9)
	end
	
	it "should be ExpansionLocation" do
		expect(translation_unit_location).to be_kind_of(SourceLocation)
		expect(translation_unit_location).to be_kind_of(ExpansionLocation)
	end
	
	describe "Null Location" do
		let(:null_location) {SourceLocation.null_location}
		it "can be a null location" do
			expect(null_location).to be_kind_of(SourceLocation)
			expect(null_location.file).to be_nil
			expect(null_location.line).to eq(0)
			expect(null_location.column).to eq(0)
			expect(null_location.offset).to eq(0)
		end
		
		it "is null?" do
			expect(null_location.null?).to equal(true)
		end
		
		it "compares as equal to another null location instance" do
			expect(null_location).to eq(SourceLocation.null_location)
		end
	end
	
	describe "#from_main_file?" do
		it "returns true if the cursor location is in main file" do
			expect(loc1_cursor.location.from_main_file?).to be true
		end
		
		it "returns false if the cursor location is not in main file" do
			expect(docs_cursor.location.from_main_file?).to be false
		end
	end
	
	describe "#in_system_header?" do
		it "returns false if the cursor location is not in system header" do
			expect(loc1_cursor.location.in_system_header?).to be false
		end
	end
	
	describe "#expansion_location" do
		let (:expansion_location) {loc1_cursor.expansion_location}
		
		it "should be ExpansionLocaion" do
			expect(expansion_location).to be_kind_of(SourceLocation)
			expect(expansion_location).to be_kind_of(ExpansionLocation)
		end
		
		it "returns source location that does not care a # line directive" do
			expect(expansion_location.line).to eq(3)
		end
		
		describe "#as_string" do
			it "returns file:line:column:offset format" do
				str = expansion_location.as_string
				expect(str).to be_kind_of(String)
				expect(str).to match(/.*:\d+:\d+:\d+/)
			end
		end
		
		describe "#to_s" do
			it "returns a descriptive string" do
				str = expansion_location.to_s
				expect(str).to match(/^ExpansionLocation </)
			end
		end
	end
	
	describe "#presumed_location" do
		let (:presumed_location) {loc1_cursor.presumed_location}
		
		it "should be FileLocaion" do
			expect(presumed_location).to be_kind_of(SourceLocation)
			expect(presumed_location).to be_kind_of(PresumedLocation)
		end
		
		it "returns preprocessed filename" do
			expect(presumed_location.filename).to eq("dummy.c")
		end
		
		it "returns source location specified by a # line directive" do
			expect(presumed_location.line).to eq(124)
		end
		
		describe "#as_string" do
			it "returns filename:line:column format" do
				str = presumed_location.as_string
				expect(str).to be_kind_of(String)
				expect(str).to match(/.*:\d+:\d+/)
			end
		end
		
		describe "#to_s" do
			it "returns a descriptive string" do
				str = presumed_location.to_s
				expect(str).to match(/^PresumedLocation </)
			end
		end
	end
	
	describe "#file_location" do
		let (:file_location) {loc1_cursor.file_location}
		
		it "should be FileLocaion" do
			expect(file_location).to be_kind_of(SourceLocation)
			expect(file_location).to be_kind_of(FileLocation)
		end
		
		it "returns source location that does not care a # line directive" do
			expect(file_location.line).to eq(3)
		end
		
		describe "#as_string" do
			it "returns file:line:column:offset format" do
				str = file_location.as_string
				expect(str).to be_kind_of(String)
				expect(str).to match(/.*:\d+:\d+:\d+/)
			end
		end
		
		describe "#to_s" do
			it "returns a descriptive string" do
				str = file_location.to_s
				expect(str).to match(/^FileLocation </)
			end
		end
	end
	
	describe "#spelling_location" do
		let (:spelling_location) {loc1_cursor.spelling_location}
		
		it "should be SpellingLocaion" do
			expect(spelling_location).to be_kind_of(SourceLocation)
			expect(spelling_location).to be_kind_of(SpellingLocation)
		end
		
		it "returns source location that does not care a # line directive" do
			expect(spelling_location.line).to eq(3)
		end
		
		describe "#as_string" do
			it "returns file:line:column:offset format" do
				str = spelling_location.as_string
				expect(str).to be_kind_of(String)
				expect(str).to match(/.*:\d+:\d+:\d+/)
			end
		end
		
		describe "#to_s" do
			it "returns a descriptive string" do
				str = spelling_location.to_s
				expect(str).to match(/^SpellingLocation </)
			end
		end
	end
	
	describe "#<=>" do
		let(:cursor_apis_tu) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
		let(:root) {cursor_apis_tu.cursor}
		let(:first_func) do
			find_matching(root) do |child, parent|
				child.kind == :cursor_function and child.spelling == "inline_func"
			end
		end
		let(:second_func) do
			find_matching(root) do |child, parent|
				child.kind == :cursor_function and child.spelling == "hidden_func"
			end
		end
		
		it "returns -1 when the first location comes before the second" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("20.0.0")
			expect(first_func.location <=> second_func.location).to eq(-1)
		end
		
		it "returns 1 when the first location comes after the second" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("20.0.0")
			expect(second_func.location <=> first_func.location).to eq(1)
		end
		
		it "returns 0 for equal locations" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("20.0.0")
			expect(first_func.location <=> first_func.location).to eq(0)
		end
		
		it "returns nil for non-SourceLocation objects" do
			expect(first_func.location <=> "not a location").to be_nil
		end
		
		it "supports Comparable operators" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("20.0.0")
			expect(first_func.location < second_func.location).to be true
			expect(second_func.location > first_func.location).to be true
			expect(first_func.location <= first_func.location).to be true
		end
		
		it "returns nil when comparing a null location" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("20.0.0")
			null_loc = SourceLocation.null_location
			expect(first_func.location <=> null_loc).to be_nil
			expect(null_loc <=> first_func.location).to be_nil
		end
		
		it "returns 0 when comparing two null locations" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("20.0.0")
			expect(SourceLocation.null_location <=> SourceLocation.null_location).to eq(0)
		end
		
		it "returns nil for locations from different translation units" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("20.0.0")
			other_tu = Index.new.parse_translation_unit(fixture_path("list.c"))
			other_func = find_by_kind(other_tu.cursor, :cursor_function)
			expect(first_func.location <=> other_func.location).to be_nil
		end
	end
	
end
