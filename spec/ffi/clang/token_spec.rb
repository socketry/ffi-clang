# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2024, by Charlie Savage.

describe Tokens do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("list.c"))}
	let(:cursor) {translation_unit.cursor}
	let(:range) {find_by_kind(cursor, :cursor_struct).extent}
	let(:tokens) {translation_unit.tokenize(range)}
	
	it "can be obtained from a translation unit" do
		expect(tokens).to be_kind_of(Tokens)
		expect(tokens.size).to be >= 12
		expect(tokens.tokens).to be_kind_of(Array)
		expect(tokens.tokens.first).to be_kind_of(Token)
	end
	
	it "calls dispose_tokens on GC" do
		tokens.autorelease = false
		expect(Lib).to receive(:dispose_tokens).at_least(:once)
		expect{tokens.free}.not_to raise_error
	end
	
	it "#each" do
		spy = double(stub: nil)
		expect(spy).to receive(:stub).exactly(tokens.size).times
		tokens.each {spy.stub}
	end
	
	it "#each returns an Enumerator if no block is given" do
		enumerator = tokens.each
		expect(enumerator).to be_kind_of(Enumerator)
		expect(enumerator.to_a).to eq(tokens.tokens)
	end
	
	it "#cursors" do
		expect(tokens.cursors).to be_kind_of(Array)
		expect(tokens.cursors.size).to eq(tokens.size)
		expect(tokens.cursors.first).to be_kind_of(Cursor)
	end
end

describe Token do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("list.c"))}
	let(:cursor) {translation_unit.cursor}
	let(:range) {find_by_kind(cursor, :cursor_struct).extent}
	let(:token) {translation_unit.tokenize(range).first}
	
	it "can be obtained from a translation unit" do
		expect(token).to be_kind_of(Token)
	end
	
	it "#kind" do
		expect(token.kind).to be_kind_of(Symbol)
		expect(token.kind).to eq(:keyword)
	end
	
	it "#spelling" do
		expect(token.spelling).to be_kind_of(String)
		expect(token.spelling).to eq("struct")
	end
	
	it "#location" do
		expect(token.location).to be_kind_of(SourceLocation)
		expect(token.location.line).to eq(1)
	end
	
	it "#extent" do
		expect(token.extent).to be_kind_of(SourceRange)
		expect(token.extent.start.line).to eq(1)
	end
end
