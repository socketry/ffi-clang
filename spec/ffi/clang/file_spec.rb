# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.

describe File do
	let(:file_list) {Index.new.parse_translation_unit(fixture_path("list.c")).file(fixture_path("list.c"))}
	let(:file_docs) {Index.new.parse_translation_unit(fixture_path("docs.c")).file(fixture_path("docs.h"))}
	let(:file_includes) {Index.new.parse_translation_unit(fixture_path("includes.c"), [], [], [:detailed_preprocessing_record]).file(fixture_path("includes.c"))}
	let(:unsaved_contents) {"int main(void) {\n\treturn 42;\n}\n"}
	let(:unsaved_translation_unit) {Index.new.parse_translation_unit("a.c", nil, [UnsavedFile.new("a.c", unsaved_contents)])}
	let(:unsaved_file) {unsaved_translation_unit.file("a.c")}
	
	it "can be obtained from a translation unit" do
		expect(file_list).to be_kind_of(FFI::Clang::File)
	end
	
	describe "#name" do
		let(:name) {file_list.name}
		
		it "returns its file name" do
			expect(name).to be_kind_of(String)
			expect(name).to eq(fixture_path("list.c"))
		end
	end
	
	describe "#to_s" do
		let(:name) {file_list.to_s}
		
		it "returns its file name" do
			expect(name).to be_kind_of(String)
			expect(name).to eq(fixture_path("list.c"))
		end
	end
	
	describe "#contents" do
		it "returns the loaded file contents" do
			expect(file_list.contents).to eq(::File.read(fixture_path("list.c")))
		end
		
		it "returns unsaved file contents from the translation unit" do
			expect(unsaved_file.contents).to eq(unsaved_contents)
		end
	end
	
	describe "#time" do
		let(:time) {file_list.time}
		
		it "returns file time" do
			expect(time).to be_kind_of(Time)
		end
	end
	
	describe "#include_guarded?" do
		it "returns false if included file is notguarded" do
			expect(file_list.include_guarded?).to be false
		end
		
		it "returns true if included file is guarded" do
			expect(file_docs.include_guarded?).to be true
		end
	end
	
	describe "#device" do
		it "returns device from CXFileUniqueID" do
			expect(file_list.device).to be_kind_of(Integer)
		end
	end
	
	describe "#inode" do
		it "returns inode from CXFileUniqueID" do
			expect(file_list.inode).to be_kind_of(Integer)
		end
	end
	
	describe "#modification" do
		it "returns modification time as Time from CXFileUniqueID" do
			expect(file_list.modification).to be_kind_of(Time)
		end
	end
	
	describe "#find_includes" do
		it "returns an Enumerator if no block is given" do
			enumerator = file_includes.find_includes
			included_files = enumerator.map {|cursor, range| cursor.included_file.name}
			
			expect(enumerator).to be_kind_of(Enumerator)
			expect(included_files).to eq([fixture_path("docs.h"), fixture_path("extra.h")])
		end
		
		it "visits include directives in order" do
			visited = []
			
			file_includes.find_includes do |cursor, range|
				visited << [cursor.kind, cursor.included_file.name, range.start.line, range.start.column]
			end
			
			expect(visited).to eq([
				[:cursor_inclusion_directive, fixture_path("docs.h"), 1, 1],
				[:cursor_inclusion_directive, fixture_path("extra.h"), 2, 1],
			])
		end
		
		it "supports :break to stop iteration early" do
			visited = []
			
			file_includes.find_includes do |cursor, range|
				visited << cursor.included_file.name
				:break
			end
			
			expect(visited).to eq([fixture_path("docs.h")])
		end
	end
end
