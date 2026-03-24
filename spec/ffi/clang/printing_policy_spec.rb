# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

describe "printing policy property mappings" do
	it "includes the constant array size property" do
		expect(FFI::Clang::Lib::PrintingPolicyProperty[:printing_policy_constant_array_size_as_written]).to eq(7)
	end
end

describe FFI::Clang::PrintingPolicy do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("test.cxx"))}
	let(:cursor) {translation_unit.cursor}
	let(:func_cursor) do
		find_matching(cursor) do |child, parent|
			child.kind == :cursor_function and child.spelling == "f_non_variadic"
		end
	end
	let(:policy) {func_cursor.printing_policy}
	
	it "can be obtained from a cursor" do
		expect(policy).to be_kind_of(FFI::Clang::PrintingPolicy)
	end
	
	describe "#get_property" do
		it "returns a boolean value for a property" do
			result = policy.get_property(:printing_policy_fully_qualified_name)
			expect(result == true || result == false).to be true
		end
	end
	
	describe "#set_property" do
		it "sets a property value" do
			policy.set_property(:printing_policy_fully_qualified_name, true)
			expect(policy.get_property(:printing_policy_fully_qualified_name)).to be true
			
			policy.set_property(:printing_policy_fully_qualified_name, false)
			expect(policy.get_property(:printing_policy_fully_qualified_name)).to be false
		end
	end
	
	describe "#pretty_print" do
		it "returns a formatted string representation" do
			result = policy.pretty_print
			expect(result).to be_kind_of(String)
			expect(result).to include("f_non_variadic")
		end
	end
end
