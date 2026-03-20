# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

describe CursorSet do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("class.cpp"))}
	let(:root_cursor) {translation_unit.cursor}
	let(:class_cursor) {find_by_kind(root_cursor, :cursor_class_decl)}
	let(:method_cursor) {find_by_kind(root_cursor, :cursor_cxx_method)}
	let(:cursor_set) {CursorSet.new}
	
	it "can insert a cursor only once" do
		expect(cursor_set.insert(class_cursor)).to be(true)
		expect(cursor_set.insert(class_cursor)).to be(false)
	end
	
	it "can report whether a cursor is present" do
		expect(cursor_set.include?(class_cursor)).to be(false)
		expect(cursor_set.include?(method_cursor)).to be(false)
		
		cursor_set.insert(class_cursor)
		
		expect(cursor_set.include?(class_cursor)).to be(true)
		expect(cursor_set.include?(method_cursor)).to be(false)
	end
	
	it "calls dispose_cursor_set on free" do
		cursor_set.autorelease = false
		expect{cursor_set.free}.not_to raise_error
	end
end
