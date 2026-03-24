# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2019, by Michael Metivier.
# Copyright, 2023-2026, by Charlie Savage.

describe TranslationUnit do
	before :all do
		FileUtils.mkdir_p TMP_DIR
	end
	
	after :all do
		FileUtils.rm_rf TMP_DIR
	end
	
	let(:translation_unit) {Index.new.parse_translation_unit fixture_path("a.c")}
	
	it "returns a list of diagnostics" do
		diags = translation_unit.diagnostics
		expect(diags).to be_kind_of(Array)
		expect(diags).to_not be_empty
	end
	
	it "returns a list of diagnostics from an unsaved file" do
		file = UnsavedFile.new("a.c", File.read(fixture_path("a.c")))
		translation_unit = Index.new.parse_translation_unit("a.c", nil,[file])
		diags = translation_unit.diagnostics
		expect(diags).to be_kind_of(Array)
		expect(diags).to_not be_empty
	end
	
	it "calls dispose_translation_unit on GC" do
		translation_unit.autorelease = false
		# expect(Lib).to receive(:dispose_translation_unit).with(translation_unit).once
		expect{translation_unit.free}.not_to raise_error
	end
	
	describe "#spelling" do
		let (:spelling) {translation_unit.spelling}
		
		it "returns own filename" do
			expect(spelling).to be_kind_of(String)
			expect(spelling).to eq(fixture_path("a.c"))
		end
	end
	
	describe "#file" do
		let (:specified_file) {translation_unit.file(fixture_path("a.c"))}
		let (:unspecified_file) {translation_unit.file}
		
		it "returns File instance" do
			expect(specified_file).to be_kind_of(FFI::Clang::File)
		end
		
		it "returns main file when file name is not specified" do
			expect(unspecified_file).to be_kind_of(FFI::Clang::File)
			expect(unspecified_file.name).to include("a.c")
		end
	end
	
	describe "#skipped_ranges" do
		let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("skipped_ranges.c"), nil, [], [:detailed_preprocessing_record])}
		let(:source_file) {translation_unit.file(fixture_path("skipped_ranges.c"))}
		let(:header_file) {translation_unit.file(fixture_path("skipped_ranges.h"))}
		
		it "returns skipped preprocessor ranges for a file" do
			ranges = translation_unit.skipped_ranges(source_file)
			
			expect(ranges.length).to eq(1)
			expect(ranges.first).to be_kind_of(SourceRange)
			expect(ranges.first.text).to include("skipped_in_source")
		end
		
		it "returns skipped preprocessor ranges for an included header" do
			ranges = translation_unit.skipped_ranges(header_file)
			
			expect(ranges.length).to eq(1)
			expect(ranges.first.text).to include("skipped_in_header")
		end
	end
	
	describe "#all_skipped_ranges" do
		let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("skipped_ranges.c"), nil, [], [:detailed_preprocessing_record])}
		
		it "returns skipped preprocessor ranges across all files" do
			ranges = translation_unit.all_skipped_ranges
			text = ranges.map(&:text).join("\n")
			
			expect(ranges.length).to eq(2)
			expect(ranges).to all(be_kind_of(SourceRange))
			expect(text).to include("skipped_in_source")
			expect(text).to include("skipped_in_header")
		end
		
		it "disposes the skipped range list after extracting the ranges" do
			expect(Lib).to receive(:dispose_source_range_list).and_call_original
			
			translation_unit.all_skipped_ranges
		end
	end
	
	describe "#location" do
		let(:file) {translation_unit.file(fixture_path("a.c"))}
		let(:column) {12}
		let(:location) {translation_unit.location(file, 1, column)}
		
		it "returns source location at a specific point" do
			expect(location).to be_kind_of(SourceLocation)
			expect(location.file).to eq(fixture_path("a.c"))
			expect(location.line).to eq(1)
			expect(location.column).to eq(column)
		end
	end
	
	describe "#location_offset" do
		let(:file) {translation_unit.file(fixture_path("a.c"))}
		let(:offset) {10}
		let(:location) {translation_unit.location_offset(file, offset)}
		
		it "returns source location at a specific offset point" do
			expect(location).to be_kind_of(SourceLocation)
			expect(location.file).to eq(fixture_path("a.c"))
			expect(location.column).to eq(offset+1)
		end
	end
	
	describe "#cursor" do
		let(:cursor) {translation_unit.cursor}
		let(:location) {translation_unit.location(translation_unit.file(fixture_path("a.c")), 1, 10)}
		let(:cursor_with_loc) {translation_unit.cursor(location)}
		
		it "returns translation unit cursor if no arguments are specified" do
			expect(cursor).to be_kind_of(Cursor)
			expect(cursor.kind).to eq(:cursor_translation_unit)
		end
		
		it "returns a correspond cursor if a source location is passed" do
			expect(cursor_with_loc).to be_kind_of(Cursor)
			expect(cursor_with_loc.kind).to eq(:cursor_parm_decl)
		end
	end
	
	describe "#self.default_editing_translation_unit_options" do
		let (:opts) {FFI::Clang::TranslationUnit.default_editing_translation_unit_options}
		it "returns hash with symbols of TranslationUnitFlags" do
			expect(opts).to be_kind_of(Array)
			opts.each do |symbol|
				expect(FFI::Clang::Lib::TranslationUnitFlags.symbols).to include(symbol)
			end
		end
	end
	
	describe "#default_save_options" do
		let (:opts) {translation_unit.default_save_options}
		it "returns hash with symbols of SaveTranslationUnitFlags" do
			expect(opts).to be_kind_of(Array)
			opts.each do |symbol|
				expect(FFI::Clang::Lib::SaveTranslationUnitFlags.symbols).to include(symbol)
			end
		end
	end
	
	describe "#save" do
		let (:filepath) {"#{TMP_DIR}/save_translation_unit"}
		let (:may_not_exist_filepath) {"#{TMP_DIR}/not_writable_directory/save_translation_unit"}
		
		it "saves translation unit as a file" do
			expect{translation_unit.save(filepath)}.not_to raise_error
			expect(FileTest.exist?(filepath)).to be true
		end
		
		it "saves translation unit using an explicit valid save option" do
			expect{translation_unit.save(filepath, [:save_translation_unit_none])}.not_to raise_error
			expect(FileTest.exist?(filepath)).to be true
		end
		
		it "raises exception if a save option is invalid" do
			expect{translation_unit.save(filepath, [:not_a_real_flag])}.to raise_error(FFI::Clang::Error)
		end
		
		it "raises exception if save path is not writable" do
			FileUtils.mkdir_p File.dirname(may_not_exist_filepath)
			File.chmod(0444, File.dirname(may_not_exist_filepath))
			if FFI::Clang.clang_version_string[/\d+/].to_i >= 19
				expect{translation_unit.save(may_not_exist_filepath)}.not_to raise_error
			else
				expect{translation_unit.save(may_not_exist_filepath)}.to raise_error(FFI::Clang::Error)
				expect(FileTest.exist?(may_not_exist_filepath)).to be false
			end
		end
	end
	
	describe "#default_reparse_options" do
		let (:opts) {translation_unit.default_reparse_options}
		it "returns hash with symbols of ReparseFlags" do
			expect(opts).to be_kind_of(Array)
			opts.each do |symbol|
				expect(FFI::Clang::Lib::ReparseFlags.symbols).to include(symbol)
			end
		end
	end
	
	describe "#reparse" do
		let (:path) {"#{TMP_DIR}/reparse_tmp.c"}
		before :each do
			FileUtils.touch path
			@reparse_translation_unit = Index.new.parse_translation_unit(path)
		end
		after :each do
			FileUtils.rm path, :force => true
		end
		
		it "recretes translation unit" do
			File::open(path, "w+") do |io|
				io.write("int a;")
			end
			
			expect(find_by_kind(@reparse_translation_unit.cursor, :cursor_variable)).to be nil
			expect{@reparse_translation_unit.reparse}.not_to raise_error
			expect(find_by_kind(@reparse_translation_unit.cursor, :cursor_variable).spelling).to eq("a")
		end
		
		it "uses libclang's default reparse options when options are not provided" do
			default_reparse_options = Lib.default_reparse_options(@reparse_translation_unit)
			expect(Lib).to receive(:default_reparse_options).with(@reparse_translation_unit).and_return(default_reparse_options)
			expect(Lib).to receive(:reparse_translation_unit).with(@reparse_translation_unit, 0, nil, default_reparse_options).and_return(0)
			
			expect{@reparse_translation_unit.reparse}.not_to raise_error
		end
		
		it "passes explicit reparse options through to libclang" do
			explicit_reparse_options = Lib.bitmask_from(Lib::ReparseFlags, [:none])
			expect(Lib).to receive(:bitmask_from).with(Lib::ReparseFlags, [:none]).and_return(explicit_reparse_options)
			expect(Lib).to receive(:reparse_translation_unit).with(@reparse_translation_unit, 0, nil, explicit_reparse_options).and_return(0)
			
			expect{@reparse_translation_unit.reparse([], [:none])}.not_to raise_error
		end
		
		it "raises exception if a reparse option is invalid" do
			expect{@reparse_translation_unit.reparse([], [:not_a_real_flag])}.to raise_error(FFI::Clang::Error)
		end
		
		it "raises exception if the file is not found when reparsing" do
			FileUtils.rm path, :force => true
			expect{@reparse_translation_unit.reparse}.to raise_error(FFI::Clang::Error)
		end
	end
	
	describe "#inclusions" do
		let(:docs_tu) {Index.new.parse_translation_unit(fixture_path("docs.c"))}
		
		it "iterates over included files" do
			files = []
			docs_tu.inclusions do |file, locations|
				files << file
			end
			expect(files).to be_kind_of(Array)
			expect(files.length).to be > 0
			expect(files.any?{|f| f.include?("docs.h")}).to be true
		end
	end
	
	describe "#suspend" do
		it "returns true when the translation unit is successfully suspended" do
			expect(translation_unit.suspend).to be true
		end
	end
	
	describe "#resource_usage" do
		let (:ru) {translation_unit.resource_usage}
		it "returns ResourceUsage instance that represents memory usage of TU" do
			expect(ru).to be_kind_of(TranslationUnit::ResourceUsage)
		end
	end
	
	describe TranslationUnit::ResourceUsage do
		let (:ru) {translation_unit.resource_usage}
		describe "#entries" do
			let (:entries) {translation_unit.resource_usage.entries}
			it "returns array of CXTUResourceUsageEntry" do
				expect(entries).to be_kind_of(Array)
				expect(entries.first).to be_kind_of(Lib::CXTUResourceUsageEntry)
				expect(entries.first[:kind]).to be_kind_of(Symbol)
				expect(entries.first[:amount]).to be_kind_of(Integer)
			end
		end
		
		describe "#self.name" do
			let(:name) {FFI::Clang::TranslationUnit::ResourceUsage.name(:ast)}
			it "returns the name of the memory category" do
				expect(name).to be_kind_of(String)
			end
		end
		
		describe "#self.release" do
			it "releases data by calling 'clang_disposeCXTUResourceUsage'" do
				ru.autorelease = false
				expect{ru.free}.not_to raise_error
			end
		end
	end
end
