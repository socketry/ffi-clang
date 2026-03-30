# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2024-2026, by Charlie Savage.

describe FFI::Clang::Lib::CXType do
	let(:type) {described_class.new}
	
	describe "type kind mapping" do
		it "maps added builtin kinds" do
			type[:kind] = 30
			expect(type[:kind]).to eq(:type_float128)
			
			type[:kind] = 39
			expect(type[:kind]).to eq(:type_bfloat16)
			
			type[:kind] = 40
			expect(type[:kind]).to eq(:type_ibm128)
		end
		
		it "maps added HLSL kinds" do
			type[:kind] = 179
			expect(type[:kind]).to eq(:type_hlsl_resource)
			
			type[:kind] = 180
			expect(type[:kind]).to eq(:type_hlsl_attributed_resource)
			
			type[:kind] = 181
			expect(type[:kind]).to eq(:type_hlsl_inline_spirv)
		end
	end
end

describe "calling convention mapping" do
	let(:calling_conv_value_class) do
		Class.new(FFI::Struct) do
			layout :value, FFI::Clang::Lib.find_type(:calling_conv)
		end
	end
	let(:calling_conv_value) {calling_conv_value_class.new}
	
	it "maps corrected calling convention kinds" do
		calling_conv_value[:value] = 8
		expect(calling_conv_value[:value]).to eq(:calling_conv_x86_reg_call)
		
		calling_conv_value[:value] = 10
		expect(calling_conv_value[:value]).to eq(:calling_conv_win64)
	end
	
	it "maps added RISCV VLS calling convention kinds" do
		calling_conv_value[:value] = 22
		expect(calling_conv_value[:value]).to eq(:calling_conv_riscv_vls_call_32)
		
		calling_conv_value[:value] = 27
		expect(calling_conv_value[:value]).to eq(:calling_conv_riscv_vls_call_1024)
		
		calling_conv_value[:value] = 33
		expect(calling_conv_value[:value]).to eq(:calling_conv_riscv_vls_call_65536)
	end
end

describe FFI::Clang::Types::Type do
	let(:cursor) {Index.new.parse_translation_unit(fixture_path("a.c")).cursor}
	let(:cursor_cxx) {Index.new.parse_translation_unit(fixture_path("test.cxx")).cursor}
	let(:cursor_list) {Index.new.parse_translation_unit(fixture_path("list.c")).cursor}
	let(:cursor_templates) {Index.new.parse_translation_unit(fixture_path("templates.hpp")).cursor}
	let(:cursor_type_apis) {Index.new.parse_translation_unit(fixture_path("type_apis.c")).cursor}
	let(:type) {find_by_kind(cursor, :cursor_function).type}
	
	it "can tell us about the main function" do
		expect(type.variadic?).to equal(false)
		
		expect(type.args_size).to equal(2)
		expect(type.arg_type(0).spelling).to eq("int")
		expect(type.arg_type(1).spelling).to eq("const char *")
		expect(type.result_type.spelling).to eq("int")
	end
	
	describe "#kind_spelling" do
		let(:kind_spelling_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "const_int_ptr"
			end.type
		end
		
		it "returns type kind name with string" do
			expect(kind_spelling_type.kind_spelling).to eq "Typedef"
		end
	end
	
	describe "#canonical" do
		let(:canonical_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "const_int_ptr"
			end.type.canonical
		end
		
		it "extracts typedef" do
			expect(canonical_type).to be_kind_of(Types::Pointer)
			expect(canonical_type.kind).to be(:type_pointer)
			expect(canonical_type.spelling).to eq("const int *")
		end
	end
	
	describe "#pointee" do
		let(:pointee_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "const_int_ptr"
			end.type.canonical.pointee
		end
		
		it "gets pointee type of pointer, C++ reference" do
			expect(pointee_type).to be_kind_of(Types::Type)
			expect(pointee_type.kind).to be(:type_int)
			expect(pointee_type.spelling).to eq("const int")
		end
	end
	
	describe "#function_type" do
		let(:reference_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "takesARef"
			end.type
		end
		
		it "iterates arg_types" do
			expect(reference_type).to be_kind_of(Types::Function)
			expect(reference_type.arg_types.to_a).to be_kind_of(Array)
			expect(reference_type.arg_types.to_a.size).to eq(2)
		end
		
		it "supports non-reference arg_types" do
			args_types = reference_type.arg_types.to_a
			expect(args_types[0].kind).to eq(:type_lvalue_ref)
			expect(args_types[0].non_reference_type.kind).to eq(:type_int)
			expect(args_types[1].kind).to eq(:type_rvalue_ref)
			expect(args_types[1].non_reference_type.kind).to eq(:type_float)
		end
	end
	
	describe "#unqualified_type" do
		let(:const_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "const_int_ptr"
			end.type.canonical.pointee
		end
		
		it "returns the type with qualifiers removed" do
			expect(const_type.const_qualified?).to be true
			unqualified = const_type.unqualified_type
			expect(unqualified).to be_kind_of(Types::Type)
			expect(unqualified.const_qualified?).to be false
			expect(unqualified.kind).to eq(:type_int)
		end
		
		it "returns the same type when already unqualified" do
			int_type = find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "int_member_a"
			end.type
			expect(int_type.const_qualified?).to be false
			expect(int_type.unqualified_type.kind).to eq(int_type.kind)
		end
	end
	
	describe "#const_qualified?" do
		let(:pointer_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "const_int_ptr"
			end.type.canonical
		end
		
		let(:pointee_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "const_int_ptr"
			end.type.canonical.pointee
		end
		
		it "checks type is const qualified" do
			expect(pointee_type.const_qualified?).to equal true
		end
		
		it "cannot check whether pointee type is const qualified" do
			expect(pointer_type.const_qualified?).to equal false
		end
	end
	
	describe "#volatile_qualified?" do
		let(:pointer_type) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "volatile_int_ptr"
			end.type
		end
		
		it "checks type is volatile qualified" do
			expect(pointer_type.volatile_qualified?).to be true
		end
	end
	
	describe "#restrict_qualified?" do
		let(:pointer_type) do
			find_matching(cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "restrict_int_ptr"
			end.type
		end
		
		it "checks type is restrict qualified" do
			expect(pointer_type.restrict_qualified?).to be true
		end
	end
	
	describe "#element_type" do
		let(:array_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "int_array"
			end.type
		end
		
		it "returns the element type of the array type" do
			expect(array_type.element_type).to be_kind_of(Types::Type)
			expect(array_type.element_type.kind).to eq(:type_int)
		end
	end
	
	describe "#num_elements" do
		let(:array_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "int_array"
			end.type
		end
		
		it "returns the number of elements of the array" do
			expect(array_type.size).to eq(8)
		end
	end
	
	describe "#array_element_type" do
		let(:array_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "int_array"
			end.type
		end
		
		it "returns the array element type of the array type" do
			expect(array_type.element_type).to be_kind_of(Types::Type)
			expect(array_type.element_type.kind).to eq(:type_int)
		end
	end
	
	describe "#array_size" do
		let(:array_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "int_array"
			end.type
		end
		
		it "returns the number of elements of the array" do
			expect(array_type.size).to eq(8)
		end
	end
	
	describe "#alignof" do
		let(:array_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "int_array"
			end.type
		end
		
		it "returns the alignment of the type in bytes" do
			expect(array_type.alignof).to be_kind_of(Integer)
			expect(array_type.alignof).to be > 0
		end
	end
	
	describe "#sizeof" do
		let(:array_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "int_array"
			end.type
		end
		
		it "returns the size of the type in bytes" do
			expect(array_type.sizeof).to be_kind_of(Integer)
			expect(array_type.sizeof).to be(32)
		end
	end
	
	describe "#offsetof" do
		let(:struct) do
			find_matching(cursor_list) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "List"
			end.type
		end
		
		it "returns the offset of a field in a record of the type in bits" do
			expect(struct.offsetof("Next")).to be_kind_of(Integer)
			expect(struct.offsetof("Next")).to be(64)
		end
	end
	
	describe "#ref_qualifier" do
		let(:lvalue) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_lvalue_ref"
			end.type
		end
		let(:rvalue) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_rvalue_ref"
			end.type
		end
		let(:none) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_none"
			end.type
		end
		
		it "returns :ref_qualifier_lvalue the type is ref-qualified with lvalue" do
			expect(lvalue.ref_qualifier).to be(:ref_qualifier_lvalue)
		end
		
		it "returns :ref_qualifier_rvalue the type is ref-qualified with rvalue" do
			expect(rvalue.ref_qualifier).to be(:ref_qualifier_rvalue)
		end
		
		it "returns :ref_qualifier_none the type is not ref-qualified" do
			expect(none.ref_qualifier).to be(:ref_qualifier_none)
		end
	end
	
	describe "#pod?" do
		let(:struct) do
			find_matching(cursor_list) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "List"
			end.type
		end
		
		it "returns true if the type is a POD type" do
			expect(struct.pod?).to be true
		end
	end
	
	describe "#class_type" do
		let(:member_pointer) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "member_pointer"
			end.type
		end
		
		it "returns the class type of the member pointer type" do
			expect(member_pointer.class_type).to be_kind_of(Types::Record).or be_kind_of(Types::Elaborated)
			expect(member_pointer.class_type.spelling).to eq("A")
		end
	end
	
	describe "#declaration" do
		let(:struct_ref) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_type_ref and child.spelling == "struct D"
			end.type
		end
		let(:struct_decl) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "D"
			end
		end
		let(:no_decl) {find_by_kind(cursor_cxx, :cursor_cxx_method).type}
		
		it "returns the class type of the member pointer type" do
			expect(struct_ref.declaration).to be_kind_of(Cursor)
			expect(struct_ref.declaration.kind).to be(:cursor_struct)
			expect(struct_ref.declaration).to eq(struct_decl)
		end
		
		it "returns :cursor_no_decl_found if the type has no declaration" do
			expect(no_decl.declaration).to be_kind_of(Cursor)
			expect(no_decl.declaration.kind).to be(:cursor_no_decl_found)
		end
	end
	
	describe "#calling_conv" do
		let(:function) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_variadic"
			end.type
		end
		
		it "returns the calling convention associated with the function type" do
			expect(function.calling_conv).to be(:calling_conv_c)
		end
	end
	
	describe "#exception_specification" do
		let(:exception_yes_1) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionYes1"
			end.type
		end
		
		it "can create exceptions 1" do
			expect(exception_yes_1.exception_specification).to be(:none)
		end
		
		let(:exception_yes_2) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionYes2"
			end.type
		end
		
		it "can create exceptions 2" do
			expect(exception_yes_2.exception_specification).to be(:computed_noexcept)
		end
		
		let(:exception_no_1) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionNo1"
			end.type
		end
		
		it "cannot create exceptions 1" do
			expect(exception_no_1.exception_specification).to be(:basic_noexcept)
		end
		
		let(:exception_no_2) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionNo2"
			end.type
		end
		
		it "cannot create exceptions 2" do
			expect(exception_no_2.exception_specification).to be(:computed_noexcept)
		end
		
		let(:exception_throw) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionThrow"
			end.type
		end
		
		it "can create throw exceptions" do
			expect(exception_throw.exception_specification).to be(:dynamic_none)
		end
	end
	
	describe "#==" do
		let(:type_decl) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "int_member_a"
			end.type
		end
		
		let(:type_ref) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_decl_ref_expr and child.spelling == "int_member_a"
			end.type
		end
		
		it "checks if two types represent the same type" do
			expect(type_decl == type_ref).to be true
		end
	end
	
	describe "#visit_base_classes" do
		let(:cursor_apis) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
		let(:derived_struct) do
			find_matching(cursor_apis.cursor) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "Derived"
			end
		end
		
		it "visits all base classes" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			bases = []
			derived_struct.type.visit_base_classes do |base|
				bases << base.spelling
			end
			expect(bases).to eq(["Base1", "Base2"])
		end
		
		it "supports :break to stop early" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			bases = []
			derived_struct.type.visit_base_classes do |base|
				bases << base.spelling
				:break
			end
			expect(bases.length).to eq(1)
		end
		
		it "returns an Enumerator when no block is given" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			enumerator = derived_struct.type.visit_base_classes
			expect(enumerator).to be_kind_of(Enumerator)
			expect(enumerator.map(&:spelling)).to eq(["Base1", "Base2"])
		end
	end
	
	describe "#visit_methods" do
		let(:cursor_apis) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
		let(:derived_struct) do
			find_matching(cursor_apis.cursor) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "Derived"
			end
		end
		
		it "visits all methods of a class" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			methods = []
			derived_struct.type.visit_methods do |method|
				methods << method.spelling
			end
			expect(methods).to include("derived_method", "another_method")
		end
		
		it "supports :break to stop early" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			methods = []
			derived_struct.type.visit_methods do |method|
				methods << method.spelling
				:break
			end
			expect(methods.length).to eq(1)
		end
		
		it "returns an Enumerator when no block is given" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			enumerator = derived_struct.type.visit_methods
			expect(enumerator).to be_kind_of(Enumerator)
			expect(enumerator.map(&:spelling)).to include("derived_method", "another_method")
		end
	end
	
	describe "#visit_fields" do
		let(:cursor_apis) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
		let(:field_struct) do
			find_matching(cursor_apis.cursor) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "FieldStruct"
			end
		end
		
		it "visits all fields of a struct" do
			fields = []
			field_struct.type.visit_fields do |field|
				fields << field.spelling
			end
			expect(fields).to eq(["field_a", "field_b", "field_c"])
		end
		
		it "returns an Enumerator when no block is given" do
			enumerator = field_struct.type.visit_fields
			expect(enumerator).to be_kind_of(Enumerator)
			expect(enumerator.map(&:spelling)).to eq(["field_a", "field_b", "field_c"])
		end
	end
	
	describe "#address_space" do
		let(:cursor_apis) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
		let(:int_type) do
			find_matching(cursor_apis.cursor) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end.type
		end
		
		it "returns the address space" do
			expect(int_type.address_space).to eq(0)
		end
	end
	
	describe "#typedef_name" do
		let(:alias_typedef) do
			find_matching(cursor_type_apis) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "AliasInt"
			end
		end
		
		let(:transparent_enum_typedef) do
			find_matching(cursor_type_apis) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "TransparentEnum"
			end
		end
		
		it "returns the typedef name for typedef types" do
			expect(alias_typedef.type.typedef_name).to eq("AliasInt")
			expect(transparent_enum_typedef.type.typedef_name).to eq("TransparentEnum")
		end
	end
	
	describe "#transparent_tag_typedef?" do
		let(:alias_typedef) do
			find_matching(cursor_type_apis) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "AliasInt"
			end
		end
		
		let(:transparent_enum_typedef) do
			find_matching(cursor_type_apis) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "TransparentEnum"
			end
		end
		
		it "detects transparent tag typedefs" do
			expect(transparent_enum_typedef.type.transparent_tag_typedef?).to be true
			expect(alias_typedef.type.transparent_tag_typedef?).to be false
		end
	end
	
	describe "#nullability" do
		let(:alias_typedef) do
			find_matching(cursor_type_apis) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "AliasInt"
			end
		end
		
		it "returns invalid for types without nullability information" do
			expect(alias_typedef.underlying_type.nullability).to eq(3)
		end
	end
	
	describe "#modified_type" do
		let(:alias_typedef) do
			find_matching(cursor_type_apis) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "AliasInt"
			end
		end
		
		it "returns an invalid type for non-attributed types" do
			expect(alias_typedef.underlying_type.modified_type.kind).to eq(:type_invalid)
		end
	end
	
	describe "#value_type" do
		let(:atomic_counter) do
			find_matching(cursor_type_apis) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "atomic_counter"
			end
		end
		
		it "returns the value type of an atomic type" do
			value_type = atomic_counter.type.value_type
			expect(value_type).to be_kind_of(Types::Type)
			expect(value_type.kind).to eq(:type_int)
			expect(value_type.spelling).to eq("int")
		end
	end
	
	describe "#pretty_printed" do
		let(:cursor_apis) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
		let(:my_struct) do
			find_matching(cursor_apis.cursor) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "MyStruct"
			end
		end
		
		it "returns the pretty-printed type name" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			policy = FFI::Clang::PrintingPolicy.new(my_struct.cursor)
			name = my_struct.type.pretty_printed(policy)
			expect(name).to include("MyNamespace")
			expect(name).to include("MyStruct")
		end
	end
	
	describe "#fully_qualified_name" do
		let(:cursor_apis) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp"))}
		let(:my_struct) do
			find_matching(cursor_apis.cursor) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "MyStruct"
			end
		end
		
		it "returns the fully qualified type name" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			policy = FFI::Clang::PrintingPolicy.new(my_struct.cursor)
			name = my_struct.type.fully_qualified_name(policy)
			expect(name).to include("MyNamespace")
			expect(name).to include("MyStruct")
		end
		
		it "prepends :: with global ns prefix" do
			skip unless FFI::Clang.clang_version >= Gem::Version.new("21.0.0")
			policy = FFI::Clang::PrintingPolicy.new(my_struct.cursor)
			name = my_struct.type.fully_qualified_name(policy, with_global_ns_prefix: true)
			expect(name).to start_with("::")
		end
	end
	
	describe "#num_template_arguments" do
		let(:template_type) do
			find_matching(cursor_templates) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "p"
			end.type
		end
		
		let(:non_template_type) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "int_member_a"
			end.type
		end
		
		it "returns the number of template arguments for a template type" do
			expect(template_type.num_template_arguments).to eq(1)
		end
		
		it "returns -1 for non-template types" do
			expect(non_template_type.num_template_arguments).to eq(-1)
		end
	end
	
	describe "#template_argument_type" do
		let(:template_with_incomplete) do
			find_matching(cursor_templates) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "p"
			end.type
		end
		
		let(:template_with_complete) do
			find_matching(cursor_templates) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "data"
			end.type
		end
		
		it "returns the template argument type at the given index" do
			arg_type = template_with_complete.template_argument_type(0)
			expect(arg_type).to be_kind_of(Types::Type)
			expect(arg_type.kind).to eq(:type_int)
		end
		
		it "returns incomplete type for Ptr<Impl>" do
			arg_type = template_with_incomplete.template_argument_type(0)
			expect(arg_type).to be_kind_of(Types::Type)
			expect([:type_elaborated, :type_record]).to include(arg_type.kind)
			expect(arg_type.declaration.kind).to eq(:cursor_class_decl)
			expect(arg_type.declaration.spelling).to eq("Impl")
		end
	end
end

describe FFI::Clang::Types::Pointer do
	let(:cursor_types) {Index.new.parse_translation_unit(fixture_path("types.cxx")).cursor}
	
	describe "#function?" do
		let(:func_ptr_type) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "my_func_ptr"
			end.type.canonical
		end
		
		it "returns true for function pointer types" do
			expect(func_ptr_type).to be_kind_of(Types::Pointer)
			expect(func_ptr_type.function?).to be true
		end
		
		let(:struct_ptr) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "StructPtr"
			end.type.canonical
		end
		
		it "returns false for non-function pointer types" do
			expect(struct_ptr).to be_kind_of(Types::Pointer)
			expect(struct_ptr.function?).to be false
		end
	end
	
	describe "#class_type" do
		let(:non_member_pointer) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "StructPtr"
			end.type.canonical
		end
		
		it "returns nil for non-member pointer types" do
			expect(non_member_pointer.class_type).to be_nil
		end
	end
	
	describe "#forward_declaration?" do
		let(:cursor_fwd) {Index.new.parse_translation_unit(fixture_path("forward_decl.cpp")).cursor}
		
		let(:forward_ptr_type) do
			find_matching(cursor_fwd) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "forward_ptr"
			end.type
		end
		
		let(:full_ptr_type) do
			find_matching(cursor_fwd) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "full_ptr"
			end.type
		end
		
		it "returns true for pointers to forward-declared types" do
			expect(forward_ptr_type).to be_kind_of(Types::Pointer)
			expect(forward_ptr_type.forward_declaration?).to be true
		end
		
		it "returns false for pointers to fully-defined types" do
			expect(full_ptr_type).to be_kind_of(Types::Pointer)
			expect(full_ptr_type.forward_declaration?).to be false
		end
	end
end

describe FFI::Clang::Types::Record do
	let(:cursor_types) {Index.new.parse_translation_unit(fixture_path("types.c")).cursor}
	let(:cursor_list) {Index.new.parse_translation_unit(fixture_path("list.c")).cursor}
	
	describe "#anonymous?" do
		let(:cursor_anonymous) {Index.new.parse_translation_unit(fixture_path("anonymous.h")).cursor}
		
		let(:anon_struct) do
			find_matching(cursor_anonymous) do |child, parent|
				child.kind == :cursor_struct and child.anonymous?
			end.type
		end
		
		it "returns truthy for anonymous record types" do
			expect(anon_struct).to be_kind_of(Types::Record)
			expect(anon_struct.anonymous?).to be_truthy
		end
	end
	
	describe "#record_type" do
		let(:struct_type) do
			find_matching(cursor_list) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "List"
			end.type
		end
		
		let(:union_type) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_union and child.spelling == "SimpleUnion"
			end.type
		end
		
		it "returns :struct for struct types" do
			expect(struct_type).to be_kind_of(Types::Record)
			expect(struct_type.record_type).to eq(:struct)
		end
		
		it "returns :union for union types" do
			expect(union_type).to be_kind_of(Types::Record)
			expect(union_type.record_type).to eq(:union)
		end
	end
end

describe FFI::Clang::Types::Elaborated do
	let(:cursor_types) {Index.new.parse_translation_unit(fixture_path("types.cxx")).cursor}
	
	describe "#named_type" do
		let(:elaborated_type) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "my_struct"
			end.type
		end
		
		it "returns the named type" do
			# Newer clang versions (22+) may return Record directly instead of Elaborated
			if elaborated_type.is_a?(Types::Elaborated)
				named = elaborated_type.named_type
				expect(named).to be_kind_of(Types::Record)
				expect(named.spelling).to eq("SimpleStruct")
			else
				expect(elaborated_type).to be_kind_of(Types::Record)
				expect(elaborated_type.spelling).to include("SimpleStruct")
			end
		end
	end
	
	describe "#anonymous?" do
		let(:non_anonymous) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "my_struct"
			end.type
		end
		
		it "returns false for non-anonymous elaborated types" do
			# Newer clang versions (22+) may return Record directly instead of Elaborated
			expect(non_anonymous).to be_kind_of(Types::Elaborated).or be_kind_of(Types::Record)
			expect(non_anonymous.anonymous?).to be_falsey
		end
	end
	
	describe "#pointer?" do
		let(:non_pointer) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "my_struct"
			end.type
		end
		
		it "returns false when canonical type is not a pointer" do
			# Newer clang versions (22+) may return Record directly instead of Elaborated.
			# Record does not have a pointer? method, so only test on Elaborated.
			if non_pointer.is_a?(Types::Elaborated)
				expect(non_pointer.pointer?).to be false
			else
				expect(non_pointer).to be_kind_of(Types::Record)
			end
		end
	end
end

describe FFI::Clang::Types::Vector do
	let(:cursor_types) {Index.new.parse_translation_unit(fixture_path("types.cxx")).cursor}
	
	let(:vector_type) do
		find_matching(cursor_types) do |child, parent|
			child.kind == :cursor_variable and child.spelling == "my_vector"
		end.type.canonical
	end
	
	describe "#element_type" do
		it "returns the element type of the vector" do
			expect(vector_type).to be_kind_of(Types::Vector)
			element = vector_type.element_type
			expect(element.kind).to eq(:type_int)
		end
	end
	
	describe "#size" do
		it "returns the number of elements in the vector" do
			expect(vector_type).to be_kind_of(Types::Vector)
			expect(vector_type.size).to eq(4)
		end
	end
end

describe FFI::Clang::Types::TypeDef do
	let(:cursor_cxx) {Index.new.parse_translation_unit(fixture_path("test.cxx")).cursor}
	
	describe "#anonymous?" do
		let(:named_typedef) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "const_int_ptr"
			end.type
		end
		
		it "returns false for typedef of non-anonymous type" do
			expect(named_typedef).to be_kind_of(Types::TypeDef)
			expect(named_typedef.anonymous?).to be false
		end
	end
end
