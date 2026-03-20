# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2023, by Charlie Savage.

describe CodeCompletion do
	let(:filename) {fixture_path("completion.cxx")}
	let(:translation_unit) {Index.new.parse_translation_unit(filename)}
	let(:line) {13}
	let(:column) {6}
	let(:results) {translation_unit.code_complete(filename, line, column)}
	
	describe "self.default_code_completion_options" do
		let(:options) {FFI::Clang::CodeCompletion.default_code_completion_options}
		it "returns a default set of code-completion options" do
			expect(options).to be_kind_of(Array)
			options.each {|symbol|
				expect(FFI::Clang::Lib::CodeCompleteFlags.symbols).to include(symbol)
			}
		end
	end
	
	describe CodeCompletion::Results do
		it "can be obtained from a translation unit" do
			expect(results).to be_kind_of(CodeCompletion::Results)
			
			# At least 40 results, depends on standard library implementation:
			expect(results.size).to be >= 40
			
			expect(results.results).to be_kind_of(Array)
			expect(results.results.first).to be_kind_of(CodeCompletion::Result)
		end
		
		it "calls dispose_code_complete_results on GC" do
			expect(Lib).to receive(:dispose_code_complete_results).at_least(:once)
			expect{results.free}.not_to raise_error
		end
		
		it "#each" do
			spy = double(stub: nil)
			expect(spy).to receive(:stub).exactly(results.size).times
			results.each {spy.stub}
		end
		
		it "#each returns an Enumerator if no block is given" do
			enumerator = results.each
			expect(enumerator).to be_kind_of(Enumerator)
			expect(enumerator.to_a).to eq(results.results)
		end
		
		it "#num_diagnostics" do
			expect(results.num_diagnostics).to eq(2)
		end
		
		it "#diagnostic" do
			expect(results.diagnostic(0)).to be_kind_of(Diagnostic)
		end
		
		it "#diagnostics" do
			expect(results.diagnostics).to be_kind_of(Array)
			expect(results.diagnostics.first).to be_kind_of(Diagnostic)
			expect(results.diagnostics.size).to eq(results.num_diagnostics)
		end
		
		it "#contexts" do
			expect(results.contexts).to be_kind_of(Array)
			results.contexts.each {|symbol|
				expect(FFI::Clang::Lib::CompletionContext.symbols).to include(symbol)
			}
		end
		
		it "#container_usr" do
			expect(results.container_usr).to be_kind_of(String)
			expect(results.container_usr).to match(/std.+vector/)
		end
		
		it "#container_kind" do
			expect(results.container_kind).to be_kind_of(Symbol)
			expect(results.container_kind).to eq(:cursor_class_decl)
		end
		
		it "#incomplete?" do
			expect(results.incomplete?).to be false
		end
		
		it "#objc_selector" do
			expect(results.objc_selector).to be_kind_of(String).or be_nil
		end
		
		it "#inspect" do
			str = results.inspect
			expect(str).to be_kind_of(String)
		end
		
		it "#sort!" do
			results.sort!
			
			possibilities = results.first.string.chunks.select{|x| x[:kind] == :typed_text}.collect{|chunk| chunk[:text]}
			
			# may be sorted with typed_text kind, first result will start with 'a'.. not necessarily
			expect(possibilities).to be == possibilities.sort
		end
	end
	
	describe CodeCompletion::Result do
		let(:result) {results.results.first}
		it "#string" do
			expect(result.string).to be_kind_of(CodeCompletion::String)
		end
		
		it "#kind" do
			expect(result.kind).to be_kind_of(Symbol)
		end
		
		it "#inspect" do
			str = result.inspect
			expect(str).to be_kind_of(String)
			expect(str).to include("<")
		end
	end
	
	describe CodeCompletion::String do
		let(:str) {results.sort!; results.find{|x| x.string.chunk_text(1) == "assign"}.string}
		
		it "#num_chunks" do
			expect(str.num_chunks).to be >= 5
		end
		
		it "#chunk_kind" do
			expect(str.chunk_kind(0)).to eq(:result_type)
			expect(str.chunk_kind(1)).to eq(:typed_text)
		end
		
		it "#chunk_text" do
			expect(str.chunk_text(0)).to be =~ /void/
			expect(str.chunk_text(1)).to eq("assign")
		end
		
		it "#chunk_completion" do
			expect(str.chunk_completion(0)).to be_kind_of(CodeCompletion::String)
		end
		
		it "#chunks" do
			expect(str.chunks).to be_kind_of(Array)
			expect(str.chunks.first).to be_kind_of(Hash)
			expect(str.chunks.size).to eq(str.num_chunks)
		end
		
		it "#priority" do
			expect(str.priority).to be_kind_of(Integer)
		end
		
		it "#availability" do
			expect(str.availability).to be_kind_of(Symbol)
			expect(str.availability).to eq(:available)
		end
		
		it "#num_annotations" do
			expect(str.num_annotations).to be_kind_of(Integer)
			expect(str.num_annotations).to eq(0)
		end
		
		it "#annotation" do
			expect(str.annotation(100)).to be_nil
		end
		
		it "#annotations" do
			expect(str.annotations).to be_kind_of(Array)
		end
	end
	
	describe "CodeCompletion::String with annotations" do
		let(:annotated_results) {translation_unit.code_complete(filename, 17, 7)}
		let(:annotated_str) do
			annotated_results.find {|r| r.string.num_annotations > 0}.string
		end
		
		it "#num_annotations returns the annotation count" do
			expect(annotated_str.num_annotations).to eq(1)
		end
		
		it "#annotation returns the annotation text" do
			expect(annotated_str.annotation(0)).to eq("my_annotation")
		end
		
		it "#annotations returns all annotations" do
			expect(annotated_str.annotations).to eq(["my_annotation"])
		end
	end
	
	describe CodeCompletion::String do
		let(:str) {results.sort!; results.find{|x| x.string.chunk_text(1) == "assign"}.string}
		
		it "#parent" do
			expect(str.parent).to be_kind_of(String)
			expect(str.parent).to be =~ /std.+vector/
		end
		
		it "#comment" do
			expect(str.comment).to be_nil
			# TODO: need tests for String which has real comment
		end
		
		it "#inspect" do
			str_inspect = str.inspect
			expect(str_inspect).to be_kind_of(String)
		end
	end
end
