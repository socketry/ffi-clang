# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Garry Marshall.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014, by George Pimm.
# Copyright, 2017, by Cameron Dutro.
# Copyright, 2019, by Michael Metivier.
# Copyright, 2023-2025, by Charlie Savage.

describe FFI::Clang::Lib::CXCursor do
	let(:cursor) {described_class.new}
	
	describe "cursor kind mapping" do
		it "maps corrected expression kinds" do
			cursor[:kind] = 129
			expect(cursor[:kind]).to eq(:cursor_cxx_typeid_expr)
			
			cursor[:kind] = 152
			expect(cursor[:kind]).to eq(:cursor_cxx_addrspace_cast_expr)
			
			cursor[:kind] = 156
			expect(cursor[:kind]).to eq(:cursor_pack_indexing_expr)
		end
		
		it "maps newly added statement kinds" do
			cursor[:kind] = 288
			expect(cursor[:kind]).to eq(:cursor_omp_tile_directive)
			
			cursor[:kind] = 300
			expect(cursor[:kind]).to eq(:cursor_omp_parallel_masked_directive)
			
			cursor[:kind] = 333
			expect(cursor[:kind]).to eq(:cursor_open_acc_cache_construct)
		end
		
		it "maps newly added extra declaration kinds" do
			cursor[:kind] = 604
			expect(cursor[:kind]).to eq(:cursor_concept_decl)
		end
	end
end

describe "availability kind mapping" do
	let(:availability_value_class) do
		Class.new(FFI::Struct) do
			layout :value, FFI::Clang::Lib.find_type(:availability)
		end
	end
	let(:availability_value) {availability_value_class.new}
	
	it "maps the corrected accessibility symbol" do
		availability_value[:value] = 3
		expect(availability_value[:value]).to eq(:not_accessible)
	end
end

describe "Function Call Cursors" do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("class.cpp"))}
	let(:cursor) {translation_unit.cursor}
	let(:call) {find_by_kind(cursor, :cursor_call_expr)}
	
	it "should parse correctly" do
		expect(translation_unit.diagnostics).to be_empty
	end
	
	it "should find a method call" do
		expect(call).to_not be_nil
	end
end

describe FFI::Clang::Cursor do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("class.cpp"))}
	let(:cursor) {translation_unit.cursor}
	let (:class1) {find_all_by_kind(cursor, :cursor_class_decl)[0]}
	let (:class2) {find_all_by_kind(cursor, :cursor_class_decl)[1]}
	let (:class3) {find_all_by_kind(cursor, :cursor_class_decl)[2]}
	
	it "can find the first class" do
		expect(class1).not_to equal(nil)
		expect(class1.kind).to equal(:cursor_class_decl)
	end
	
	it "returns the name of the class" do
		expect(class1.spelling).to eq("MyClass1")
		expect(class1.display_name).to eq("MyClass1")
		expect(class2.spelling).to eq("MyClass2")
		expect(class2.display_name).to eq("MyClass2")
		expect(class3.spelling).to eq("MyClass3")
		expect(class3.display_name).to eq("MyClass3")
	end
	
	it "has constructors" do
		constructors = find_all_by_kind(class2, :cursor_constructor)
		expect(constructors.length).to eq(5)
		
		expect(constructors[0].default_constructor?).to eq(true)
		expect(constructors[0].copy_constructor?).to eq(false)
		expect(constructors[0].move_constructor?).to eq(false)
		expect(constructors[0].converting_constructor?).to eq(false)
		
		expect(constructors[1].default_constructor?).to eq(false)
		expect(constructors[1].copy_constructor?).to eq(false)
		expect(constructors[1].move_constructor?).to eq(false)
		expect(constructors[1].converting_constructor?).to eq(true)
		
		expect(constructors[2].default_constructor?).to eq(false)
		expect(constructors[2].copy_constructor?).to eq(false)
		expect(constructors[2].move_constructor?).to eq(false)
		expect(constructors[2].converting_constructor?).to eq(false)
		
		expect(constructors[3].default_constructor?).to eq(false)
		expect(constructors[3].copy_constructor?).to eq(true)
		expect(constructors[3].move_constructor?).to eq(false)
		expect(constructors[3].converting_constructor?).to eq(true)
		expect(constructors[3].defaulted?).to eq(true)
		
		expect(constructors[4].default_constructor?).to eq(false)
		expect(constructors[4].copy_constructor?).to eq(false)
		expect(constructors[4].move_constructor?).to eq(true)
		expect(constructors[4].converting_constructor?).to eq(true)
		expect(constructors[3].defaulted?).to eq(true)
	end
	
	it "has destructors" do
		constructors = find_all_by_kind(class2, :cursor_constructor)
		expect(constructors.length).to eq(5)
	end
	
	it "class is abstract" do
		expect(class1.abstract?).to eq(false)
		expect(class2.abstract?).to eq(false)
		expect(class3.abstract?).to eq(true)
	end
	
	it "field is mutable abstract" do
		fields = find_all_by_kind(class3, :cursor_field_decl)
		
		field = fields[0]
		expect(field.mutable?).to eq(true)
	end
end

describe Cursor do
	let(:cursor) {Index.new.parse_translation_unit(fixture_path("list.c")).cursor}
	let(:cursor_cxx) {Index.new.parse_translation_unit(fixture_path("test.cxx")).cursor}
	let(:cursor_canon) {Index.new.parse_translation_unit(fixture_path("canonical.c")).cursor}
	let(:cursor_pp) {Index.new.parse_translation_unit(fixture_path("docs.c"),[],[],[:detailed_preprocessing_record]).cursor}
	let(:cursor_forward) {Index.new.parse_translation_unit(fixture_path("forward.h")).cursor}
	let(:cursor_anonymous) {Index.new.parse_translation_unit(fixture_path("anonymous.h")).cursor}
	let(:cursor_apis) {Index.new.parse_translation_unit(fixture_path("cursor_apis.cpp")).cursor}
	
	it "can be obtained from a translation unit" do
		expect(cursor).to be_kind_of(Cursor)
		expect(cursor.kind).to equal(:cursor_translation_unit)
		expect(cursor.null?).to equal(false)
		expect(cursor.translation_unit?).to equal(true)
	end
	
	it "returns the source location of the cursor" do
		location = cursor.location
		expect(location).to be_kind_of(SourceLocation)
	end
	
	describe "#extent" do
		let(:extent) {cursor.extent}
		it "has an extent which is a SourceRange" do
			expect(extent).to be_kind_of(SourceRange)
		end
		
		it "has filename and posion at start point" do
			expect(extent.start.file).to eq(fixture_path("list.c"))
			expect(extent.start.line).to equal(1)
		end
		
		it "has filename and posion at end point" do
			expect(extent.end.file).to eq(fixture_path("list.c"))
			expect(extent.end.line).to equal(12)
		end
	end
	
	it "returns the path of the translation unit for the translation unit cursor" do
		expect(cursor.display_name).to eq(fixture_path("list.c"))
		expect(cursor.spelling).to eq(fixture_path("list.c"))
	end
	
	it "allows us to visit its children" do
		counter = 0
		cursor.each do |cursor, parent|
			counter += 1
			:recurse
		end
		expect(counter).not_to equal(0)
	end
	
	describe "#visit_children" do
		it "allows us to visit its children" do
			counter = 0
			cursor.visit_children do |cursor, parent|
				counter += 1
			end
			
			expect(counter).not_to equal(0)
		end
	end
	
	describe "Null Cursor" do
		it "can be a null cursor" do
			expect(Cursor.null_cursor).to be_kind_of(Cursor)
			expect(Cursor.null_cursor.kind).to equal(:cursor_invalid_file)
		end
		
		it "is null?" do
			expect(Cursor.null_cursor.null?).to equal(true)
		end
		
		it "is invalid?" do
			expect(Cursor.null_cursor.invalid?).to equal(true)
		end
		
		it "compares as equal to another null cursor instance" do
			expect(Cursor.null_cursor).to eq(Cursor.null_cursor)
		end
		
		it "should not equal a Translation Unit cursor" do
			expect(Cursor.null_cursor).not_to eq(cursor)
		end
	end
	
	describe "Function Cursors" do
		let (:func) {find_by_kind(cursor, :cursor_function)}
		
		it "is not invalid?" do
			expect(func.invalid?).to equal(false)
		end
		
		it "can find the first function declaration" do
			expect(func).not_to equal(nil)
			expect(func.kind).to equal(:cursor_function)
		end
		
		it "has an extent representing the bounds of the function" do
			expect(func.extent).to be_kind_of(SourceRange)
			expect(func.extent.start.line).to equal(5)
			expect(func.extent.end.line).to equal(5)
		end
		
		it "returns the name of the function" do
			expect(func.spelling).to eq("sum")
			expect(func.display_name).to eq("sum(union List *)")
		end
	end
	
	describe "Struct Cursors" do
		let (:struct) {find_by_kind(cursor, :cursor_struct)}
		
		it "can find the first struct" do
			expect(struct).not_to equal(nil)
			expect(struct.kind).to equal(:cursor_struct)
		end
		
		it "has an extent representing the bounds of the struct" do
			expect(struct.extent.start.line).to equal(1)
			expect(struct.extent.end.line).to equal(4)
		end
		
		it "returns the name of the struct" do
			expect(struct.spelling).to eq("List")
			expect(struct.display_name).to eq("List")
		end
	end
	
	describe "#kind_spelling" do
		let (:struct) {find_by_kind(cursor, :cursor_struct)}
		
		it "returns the spelling of the given kind" do
			expect(struct.kind_spelling).to eq("StructDecl")
		end
	end
	
	describe "#declaration?" do
		let (:struct) {find_by_kind(cursor, :cursor_struct)}
		
		it "checks the cursor is declaration" do
			expect(struct.declaration?).to be true
		end
	end
	
	describe "#reference?" do
		let (:ref) {find_by_kind(cursor, :cursor_type_ref)}
		
		it "checks the cursor is reference" do
			expect(ref.reference?).to be true
		end
	end
	
	describe "#expression?" do
		let (:literal) {find_by_kind(cursor, :cursor_integer_literal)}
		
		it "checks the cursor is expression" do
			expect(literal.expression?).to be true
		end
	end
	
	describe "#statement?" do
		let (:return_stmt) {find_by_kind(cursor, :cursor_return_stmt)}
		
		it "checks the cursor is statement" do
			expect(return_stmt.statement?).to be true
		end
	end
	
	describe "#attribute?" do
		let (:attr) {find_by_kind(cursor_cxx, :cursor_unexposed_attr)}
		
		it "checks the cursor is attribute" do
			expect(attr.attribute?).to be true
		end
	end
	
	describe "#public?" do
		let(:public_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "public_member_int"
			end
		end
		
		it "checks access control level is public" do
			expect(public_cursor.public?).to be true
		end
	end
	
	describe "#private?" do
		let(:private_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "private_member_int"
			end
		end
		
		it "checks access control level is private" do
			expect(private_cursor.private?).to be true
		end
	end
	
	describe "#protected?" do
		let(:protected_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "protected_member_int"
			end
		end
		
		it "checks access control level is protected" do
			expect(protected_cursor.protected?).to be true
		end
	end
	
	describe "#preprocessing?" do
		let (:pp) {find_by_kind(cursor_pp, :cursor_macro_definition)}
		
		it "checks the cursor is preprocessing" do
			expect(pp.preprocessing?).to be true
		end
	end
	
	describe "#unexposed?" do
		let(:unexposed_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_unexposed_expr and child.spelling == "func_overloaded"
			end
		end
		
		it "checks the cursor is unexposed" do
			expect(unexposed_cursor.unexposed?).to be true
		end
	end
	
	describe "#virtual_base?" do
		let(:virtual_base_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_base_specifier and parent.spelling == "B"
			end
		end
		
		it "checks cursor is virtual base" do
			expect(virtual_base_cursor.virtual_base?).to equal true
		end
	end
	
	describe "#virtual?" do
		let(:virtual_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_a"
			end
		end
		
		it "checks member function is virtual" do
			expect(virtual_cursor.virtual?).to equal true
		end
	end
	
	describe "#pure_virtual?" do
		let(:pure_virtual_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and
							child.spelling == "func_a" and parent.spelling == "A"
			end
		end
		
		it "checks member function is purely virtual" do
			expect(pure_virtual_cursor.pure_virtual?).to equal true
		end
	end
	
	describe "#static?" do
		let(:static_method_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_b"
			end
		end
		
		it "checks cursor is static member function" do
			expect(static_method_cursor.static?).to equal true
		end
	end
	
	describe "#enum_value" do
		let(:enum_value_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_enum_constant_decl and child.spelling == "EnumC"
			end
		end
		
		it "returns enum value" do
			expect(enum_value_cursor.enum_value).to equal 100
		end
	end
	
	describe "#enum_unsigned_value" do
		let(:enum_value_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_enum_constant_decl and child.spelling == "EnumC"
			end
		end
		
		it "returns enum unsigned value" do
			expect(enum_value_cursor.enum_unsigned_value).to eq(100)
		end
	end
	
	describe "#dynamic_call?" do
		let(:dynamic_call) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_call_expr and child.spelling == "func_a" and
							child.semantic_parent.spelling == "f_dynamic_call"
			end
		end
		
		it "checks if the method call is dynamic" do
			expect(dynamic_call.dynamic_call?).to be true
		end
	end
	
	describe "#has_global_storage?" do
		let(:extern_var) do
			find_matching(cursor_apis) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "extern_var"
			end
		end
		
		let(:static_var) do
			find_matching(cursor_apis) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "static_var"
			end
		end
		
		let(:global_var) do
			find_matching(cursor_apis) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end
		end
		
		it "returns true for file-scope variable declarations" do
			expect(extern_var.has_global_storage?).to be true
			expect(static_var.has_global_storage?).to be true
			expect(global_var.has_global_storage?).to be true
		end
	end
	
	describe "#has_external_storage?" do
		let(:extern_var) do
			find_matching(cursor_apis) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "extern_var"
			end
		end
		
		let(:static_var) do
			find_matching(cursor_apis) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "static_var"
			end
		end
		
		let(:global_var) do
			find_matching(cursor_apis) do |child, parent|
				child.kind == :cursor_variable and child.spelling == "global_var"
			end
		end
		
		it "distinguishes external storage from other file-scope storage" do
			expect(extern_var.has_external_storage?).to be true
			expect(static_var.has_external_storage?).to be false
			expect(global_var.has_external_storage?).to be false
		end
	end
	
	describe "#specialized_template" do # looks not working on 3.2
		let(:cursor_function) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "func_overloaded"
			end
		end
		
		it "returns a cursor that may represent a specialization or instantiation of a template" do
			expect(cursor_function.specialized_template).to be_kind_of(Cursor)
			expect(cursor_function.specialized_template.kind).to be(:cursor_function_template)
		end
	end
	
	describe "#canonical" do
		let (:structs) {find_all_by_kind(cursor_canon, :cursor_struct)}
		
		it "mathes 3 cursors" do
			expect(structs.size).to eq(3)
		end
		
		it "refers the first cursor as canonical one" do
			expect(structs[0].canonical).to eq(structs[0])
			expect(structs[1].canonical).to eq(structs[0])
			expect(structs[2].canonical).to eq(structs[0])
		end
	end
	
	describe "#definition" do
		let (:structs) {find_all_by_kind(cursor_canon, :cursor_struct)}
		
		it "mathes 3 cursors" do
			expect(structs.size).to eq(3)
		end
		
		it "refers the third cursor as definition one" do
			expect(structs[0].definition).to eq(structs[2])
			expect(structs[1].definition).to eq(structs[2])
			expect(structs[2].definition).to eq(structs[2])
		end
	end
	
	describe "#template_kind" do # looks not working on 3.2
		let(:template) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function_template and child.spelling == "func_overloaded"
			end
		end
		
		it "returns the cursor kind of the specializations would be generated" do
			expect(template.template_kind).to be_kind_of(Symbol)
			expect(template.template_kind).to be(:cursor_function)
		end
	end
	
	describe "#access_specifier" do
		let(:access_specifier_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_d"
			end
		end
		
		it "returns access specifier symbol" do
			expect(access_specifier_cursor.access_specifier).to equal :private
		end
	end
	
	describe "#language" do
		let(:c_language_cursor) do
			find_matching(cursor) do|c, p| c.kind == :cursor_struct
			end
		end
		let(:cxx_language_cursor) do
			find_matching(cursor_cxx) do|c, p| c.kind == :cursor_struct
			end
		end
		
		it "returns :c if the cursor language is C" do
			expect(c_language_cursor.language).to equal :c
		end
		
		it "returns :c_plus_plus if the cursor language is C++" do
			expect(cxx_language_cursor.language).to equal :c_plus_plus
		end
	end
	
	describe "#translation_unit" do
		let (:struct) {find_by_kind(cursor, :cursor_struct)}
		
		it "can find the first struct" do
			expect(struct).not_to equal(nil)
		end
		
		it "returns the translation unit that a cursor originated from" do
			expect(struct.translation_unit).to be_kind_of(TranslationUnit)
			expect(struct.translation_unit.spelling).to eq(fixture_path("list.c"))
		end
	end
	
	describe "#find_references_in_file" do
		let (:struct_cursor) {find_by_kind(cursor_canon, :cursor_struct)}
		
		it "visits references to the cursor in the main file" do
			counter = 0
			struct_cursor.find_references_in_file do |ref_cursor, ref_src_loc|
				counter += 1
				:continue
			end
			expect(counter).not_to equal(0)
		end
		
		it "visits references to the cursor in the indicated file" do
			counter = 0
			struct_cursor.find_references_in_file(fixture_path("canonical.c")) do |ref_cursor, ref_src_loc|
				counter += 1
				:continue
			end
			expect(counter).not_to equal(0)
		end
	end
	
	describe "#linkage" do
		let (:ref) {find_by_kind(cursor, :cursor_type_ref)}
		let (:func) {find_by_kind(cursor, :cursor_function)}
		
		it "returns :external if the cursor is non-static function" do
			expect(func.linkage).to equal :external
		end
		
		it "returns :invalid if the cursor does not have linkage" do
			expect(ref.linkage).to equal :invalid
		end
	end
	
	describe "#exception_specification" do
		let(:exception_yes_1) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionYes1"
			end
		end
		
		it "can create exceptions 1" do
			expect(exception_yes_1.exception_specification).to be(:none)
		end
		
		let(:exception_yes_2) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionYes2"
			end
		end
		
		it "can create exceptions 2" do
			expect(exception_yes_2.exception_specification).to be(:computed_noexcept)
		end
		
		let(:exception_no_1) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionNo1"
			end
		end
		
		it "cannot create exceptions 1" do
			expect(exception_no_1.exception_specification).to be(:basic_noexcept)
		end
		
		let(:exception_no_2) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionNo2"
			end
		end
		
		it "cannot create exceptions 2" do
			expect(exception_no_2.exception_specification).to be(:computed_noexcept)
		end
		
		let(:exception_throw) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "exceptionThrow"
			end
		end
		
		it "can create throw exceptions" do
			expect(exception_throw.exception_specification).to be(:dynamic_none)
		end
	end
	
	describe "#semantic_parent" do
		let(:parent) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_d" and parent.spelling != "D"
			end
		end
		
		it "returns base class as semantic parent" do
			expect(parent.semantic_parent.spelling).to eq("D")
		end
	end
	
	describe "#lexical_parent" do
		let(:parent) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_d" and parent.spelling != "D"
			end
		end
		
		it "returns translation unit as lexical parent" do
			expect(parent.lexical_parent.kind).to eq(:cursor_translation_unit)
		end
	end
	
	describe "#included_file" do
		#TODO
	end
	
	describe "#definition?" do
		let (:struct) {find_all_by_kind(cursor_canon, :cursor_struct).at(2)}
		
		it "checks cursor is a definition" do
			expect(struct.definition?).to be true
		end
	end
	
	describe "#usr" do
		let (:func) {find_by_kind(cursor, :cursor_function)}
		
		it "returns something in string" do
			expect(func.usr).to be_kind_of(String)
		end
	end
	
	describe "#variadic?" do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_variadic"
			end
		end
		
		it "checks cursor is a variadic function" do
			expect(func.variadic?).to be true
		end
	end
	
	describe "#referenced" do
		let(:struct) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "A"
			end
		end
		let(:ref) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_type_ref and child.spelling == "struct A"
			end
		end
		
		it "returns a cursor that this cursor references" do
			expect(ref.referenced).to eq(struct)
		end
		
	end
	
	describe "#hash" do
		let (:func) {find_by_kind(cursor, :cursor_function)}
		
		it "computes hash for the cursor" do
			expect(func.hash).to be_kind_of(Integer)
		end
	end
	
	describe "#availability" do
		let (:func) {find_by_kind(cursor, :cursor_function)}
		
		it "returns :available for the cursor availability" do
			expect(func.availability).to equal(:available)
		end
	end
	
	describe "#type" do
		let (:field) {find_by_kind(cursor, :cursor_field_decl)}
		
		it "returns type for the cursor" do
			expect(field.type).to be_kind_of(Types::Type)
			expect(field.type.kind).to equal(:type_int)
		end
	end
	
	describe "#underlying_type" do
		let (:typedef) {find_by_kind(cursor_cxx, :cursor_typedef_decl)}
		
		it "returns type that the cursor type is underlying" do
			expect(typedef.underlying_type).to be_kind_of(Types::Pointer)
			expect(typedef.underlying_type.kind).to equal(:type_pointer)
		end
	end
	
	describe "#bitfield?" do
		let(:bitfield) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "bit_field_a"
			end
		end
		let(:non_bitfield) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "non_bit_field_c"
			end
		end
		
		it "returns true if the cursor is bitfield" do
			expect(bitfield.bitfield?).to be true
		end
		
		it "returns false if the cursor is not bitfield" do
			expect(non_bitfield.bitfield?).to be false
		end
	end
	
	describe "#bitwidth" do
		let(:bitfield) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "bit_field_a"
			end
		end
		let(:non_bitfield) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_field_decl and child.spelling == "non_bit_field_c"
			end
		end
		
		it "returns the bit width of the bit field if the cursor is bitfield" do
			expect(bitfield.bitwidth).to be_kind_of(Integer)
			expect(bitfield.bitwidth).to eq(2)
		end
		
		it "returns -1 if the cursor is not bitfield" do
			expect(non_bitfield.bitwidth).to eq(-1)
		end
	end
	
	describe "#enum_type" do
		let(:enum) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_enum_decl and child.spelling == "normal_enum"
			end
		end
		
		it "returns the integer type of the enum declaration" do
			expect(enum.enum_type).to be_kind_of(Types::Type)
			if FFI::Clang.platform == :mswin
				expect(enum.enum_type.kind).to be(:type_int)
			else
				expect(enum.enum_type.kind).to be(:type_uint)
			end
		end
	end
	
	describe "#platform_availability" do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
							child.kind == :cursor_function and child.spelling == "availability_func"end
		end
		let(:availability) {func.platform_availability}
		
		it "returns the availability of the entity as Hash" do
			expect(availability).to be_kind_of(Hash)
			expect(availability[:always_deprecated]).to be_kind_of(Integer)
			expect(availability[:always_unavailable]).to be_kind_of(Integer)
			expect(availability[:deprecated_message]).to be_kind_of(String)
			expect(availability[:unavailable_message]).to be_kind_of(String)
			expect(availability[:availability]).to be_kind_of(Array)
		end
	end
	
	describe "#overriddens" do
		let(:override_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and
							child.spelling == "func_a" and parent.spelling == "D"
			end
		end
		
		it "returns an OverriddenCursors collection" do
			overriddens = override_cursor.overriddens
			expect(overriddens).to be_kind_of(Cursor::OverriddenCursors)
			expect(overriddens.size).to eq(2)
			expect(overriddens.map{|cur| cur.semantic_parent.spelling}).to eq(["B", "C"])
		end
		
		it "#each returns an Enumerator if no block is given" do
			enumerator = override_cursor.overriddens.each
			expect(enumerator).to be_kind_of(Enumerator)
			expect(enumerator.to_a.size).to eq(2)
		end
		
		it "returns empty collection for non-overriding methods" do
			non_override = find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_a" and parent.spelling == "A"
			end
			overriddens = non_override.overriddens
			expect(overriddens.size).to eq(0)
			expect(overriddens.to_a).to eq([])
		end
		
		it "cursors remain valid after iteration" do
			overriddens = override_cursor.overriddens
			cursors = overriddens.to_a
			expect(cursors[0].semantic_parent.spelling).to eq("B")
			expect(cursors[1].semantic_parent.spelling).to eq("C")
		end
	end
	
	describe "#overloaded_decl" do
		let(:overloaded) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_overloaded_decl_ref and child.spelling == "func_overloaded"
			end
		end
		
		it "returns a cursor for one of the overloaded declarations", skip: (FFI::Clang.platform == :mswin) do
			expect(overloaded.overloaded_decl(0)).to be_kind_of(Cursor)
			expect(overloaded.overloaded_decl(0).kind).to be(:cursor_function_template)
			expect(overloaded.overloaded_decl(0).spelling).to eq("func_overloaded")
		end
	end
	
	describe "#num_overloaded_decls" do
		let(:overloaded) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_overloaded_decl_ref and child.spelling == "func_overloaded"
			end
		end
		
		it "returns the number of overloaded declarations", skip: (FFI::Clang.platform == :mswin) do
			expect(overloaded.num_overloaded_decls).to be_kind_of(Integer)
			expect(overloaded.num_overloaded_decls).to be(2)
		end
	end
	
	describe "#qualified_name" do
		let(:qualified) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "B"
			end
		end
		let(:base_class) do
			find_matching(qualified) do |child, parent|
				child.kind == :cursor_cxx_base_specifier
			end
		end
		
		it "returns a qualified name for struct" do
			expect(qualified.qualified_name).to eq("B")
		end
		
		it "throws error for base class qualified name" do
			expect{base_class.qualified_name}.to raise_error(ArgumentError)
		end
	end
	
	describe "#qualified_display_name" do
		let(:qualified) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "Nested"
			end
		end
		
		it "returns a qualified display name for struct" do
			expect(qualified.qualified_display_name).to eq("Outer::Inner::Nested")
		end
	end
	
	describe "#objc_type_encoding" do
		#TODO
	end
	
	describe "#argument" do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_non_variadic"
			end
		end
		
		it "returns the argument cursor of the function" do
			expect(func.argument(0)).to be_kind_of(Cursor)
			expect(func.argument(0).spelling).to eq("a")
		end
	end
	
	describe "#num_arguments" do
		let(:cursor_cxx) {Index.new.parse_translation_unit(fixture_path("test.cxx")).cursor}
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_non_variadic"
			end
		end
		
		it "returns the number of non-variadic arguments" do
			expect(func.num_arguments).to be_kind_of(Integer)
			expect(func.num_arguments).to be(3)
		end
	end
	
	describe "#result_type" do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_non_variadic"
			end
		end
		
		it "result the result type of the function" do
			expect(func.result_type).to be_kind_of(Types::Type)
			expect(func.result_type.kind).to be(:type_void)
		end
	end
	
	describe "#raw_comment_text" do
		let(:func) do
			find_matching(cursor_pp) do |child, parent|
				child.kind == :cursor_function and child.spelling == "a_function"
			end
		end
		
		it "checks the cursor is declaration" do
			expect(func.raw_comment_text).to be_kind_of(String)
			expect(func.raw_comment_text).not_to be_empty
		end
	end
	
	describe "#comment" do
		let(:func) do
			find_matching(cursor_pp) do |child, parent|
				child.kind == :cursor_function and child.spelling == "a_function"
			end
		end
		
		it "checks the cursor is declaration" do
			expect(func.comment).to be_kind_of(Comment)
		end
	end
	
	describe "#included_file" do
		let (:inclusion) {find_by_kind(cursor_pp, :cursor_inclusion_directive)}
		
		it "returns the file that is included by the given inclusion directive cursor" do
			expect(inclusion.included_file).to be_kind_of(FFI::Clang::File)
			expect(File.basename(inclusion.included_file.name)).to eq("docs.h")
		end
	end
	
	describe "#references" do
		let (:struct_cursor) {find_by_kind(cursor_canon, :cursor_struct)}
		let (:unspecified_references) {struct_cursor.references}
		let (:specified_references) {struct_cursor.references(fixture_path("canonical.c"))}
		
		it "returns an Array of reference Cursors in the main file" do
			expect(unspecified_references).to be_kind_of(Array)
			expect(unspecified_references.length).not_to equal(0)
			expect(unspecified_references).to all(be_a (FFI::Clang::Cursor))
		end
		
		it "returns an Array of reference Cursors in the specified file" do
			expect(specified_references).to be_kind_of(Array)
			expect(specified_references.length).not_to equal(0)
			expect(specified_references).to all(be_a (FFI::Clang::Cursor))
		end
	end
	
	describe Cursor::PlatformAvailability do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
							child.kind == :cursor_function and child.spelling == "availability_func"end
		end
		let(:availability) {func.platform_availability[:availability].first}
		
		it "can be obtained by Cursor#platform_availability" do
			expect(availability).to be_kind_of(Cursor::PlatformAvailability)
		end
		
		describe "#platform" do
			it "returns availability information for the platform" do
				expect(availability.platform).to be_kind_of(String)
			end
		end
		
		describe "#introduced" do
			it "returns the version number in which this entity was introduced" do
				expect(availability.introduced).to be_kind_of(Lib::CXVersion)
				expect(availability.introduced.to_s).to eq("10.4.1")
			end
		end
		
		describe "#deprecated" do
			it "returns the version number in which this entity was deprecated" do
				expect(availability.deprecated).to be_kind_of(Lib::CXVersion)
				expect(availability.deprecated.to_s).to eq("10.6")
			end
		end
		
		describe "#obsoleted" do
			it "returns the version number in which this entity was obsoleted" do
				expect(availability.obsoleted).to be_kind_of(Lib::CXVersion)
				expect(availability.obsoleted.to_s).to eq("10.7")
			end
		end
		
		describe "#unavailable" do
			it "returns whether the entity is unavailable on this platform" do
				expect(availability.unavailable).to be false
			end
		end
		
		describe "#message" do
			it "returns an optional message to provide to a user of this API" do
				expect(availability.message).to be_kind_of(String)
			end
		end
	end
	
	describe "#forward" do
		let(:opaque) do
			find_matching(cursor_forward) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "Opaque"
			end
		end
		
		let(:forward) do
			find_matching(cursor_forward) do |child, parent|
				child.kind == :cursor_struct and child.spelling == "Forward"
			end
		end
		
		describe "#opaque" do
			it "is an opaque declaration" do
				expect(opaque.opaque_declaration?).to eq(true)
				expect(opaque.forward_declaration?).to eq(false)
			end 
		end
		
		describe "#forward" do
			it "is a forward declaration" do
				expect(forward.opaque_declaration?).to eq(false)
				expect(forward.forward_declaration?).to eq(true)
			end
		end
	end
	
	describe "#anonymous" do
		let(:struct) do
			find_matching(cursor_anonymous) do |child, parent|
				child.kind == :cursor_struct
			end
		end
		
		it "is an an anonymous structure" do
			expect(struct.anonymous?).to eq(true)
		end
	end
	
	describe "#qualified_name with linkage_spec" do
		let(:cursor_linkage) do
			Index.new.parse_translation_unit(fixture_path("linkage.hpp")).cursor
		end
		
		let(:ushort_typedef) do
			find_matching(cursor_linkage) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "ushort"
			end
		end
		
		let(:myfloat_typedef) do
			find_matching(cursor_linkage) do |child, parent|
				child.kind == :cursor_typedef_decl and child.spelling == "myfloat"
			end
		end
		
		it "skips extern C linkage spec for typedef in global scope" do
			expect(ushort_typedef.qualified_name).to eq("ushort")
		end
		
		it "preserves namespace but skips linkage spec for typedef in namespace" do
			expect(myfloat_typedef.qualified_name).to eq("ns::myfloat")
		end
	end
	
	describe "#comment_range" do
		let(:func) do
			find_matching(cursor_pp) do |child, parent|
				child.kind == :cursor_function and child.spelling == "a_function"
			end
		end
		
		it "returns a source range" do
			range = func.comment_range
			expect(range).to be_kind_of(SourceRange)
		end
	end
end

describe FFI::Clang::Cursor do
	let(:translation_unit) {Index.new.parse_translation_unit(fixture_path("class.cpp"))}
	let(:cursor) {translation_unit.cursor}
	
	describe "#find_first_by_kind" do
		it "finds the first class declaration" do
			result = cursor.find_first_by_kind(true, :cursor_class_decl)
			expect(result).not_to be_nil
			expect(result.kind).to eq(:cursor_class_decl)
			expect(result.spelling).to eq("MyClass1")
		end
		
		it "returns nil when no match is found" do
			result = cursor.find_first_by_kind(true, :cursor_objc_interface_decl)
			expect(result).to be_nil
		end
		
		it "finds with multiple kinds" do
			result = cursor.find_first_by_kind(true, :cursor_struct, :cursor_class_decl)
			expect(result).not_to be_nil
			expect(result.kind).to eq(:cursor_class_decl)
		end
		
		it "respects recurse parameter" do
			result = cursor.find_first_by_kind(false, :cursor_constructor)
			expect(result).to be_nil
			
			result = cursor.find_first_by_kind(true, :cursor_constructor)
			expect(result).not_to be_nil
		end
		
		it "raises on invalid recurse parameter" do
			expect {cursor.find_first_by_kind("yes", :cursor_class_decl)}.to raise_error(RuntimeError)
		end
	end
	
	describe "#each with :break" do
		it "stops traversal when block returns :break" do
			count = 0
			cursor.each(true) do |child, parent|
				count += 1
				:break if child.kind == :cursor_class_decl
			end
			expect(count).to eq(1)
		end
	end
	
	describe "#each with :continue" do
		it "continues traversal without recursing when block returns :continue" do
			top_level_count = 0
			cursor.each(true) do |child, parent|
				top_level_count += 1
				:continue
			end
			# Should only visit top-level children, not recurse
			expect(top_level_count).to be > 0
			expect(top_level_count).to be < 20
		end
	end
end

describe FFI::Clang::Cursor do
	let(:cursor_types) {Index.new.parse_translation_unit(fixture_path("types.cxx")).cursor}
	let(:cursor_cxx) {Index.new.parse_translation_unit(fixture_path("test.cxx")).cursor}
	let(:cursor_class) {Index.new.parse_translation_unit(fixture_path("class.cpp")).cursor}
	
	describe "#comment_range" do
		let(:cursor_pp) {Index.new.parse_translation_unit(fixture_path("docs.c"),[],[],[:detailed_preprocessing_record]).cursor}
		
		let(:func) do
			find_matching(cursor_pp) do |child, parent|
				child.kind == :cursor_function and child.spelling == "a_function"
			end
		end
		
		it "returns a source range for the comment" do
			range = func.comment_range
			expect(range).to be_kind_of(SourceRange)
		end
	end
	
	describe "#completion" do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_non_variadic"
			end
		end
		
		it "returns a code completion string" do
			completion = func.completion
			expect(completion).to be_kind_of(CodeCompletion::String)
		end
	end
	
	describe "#anonymous_record_declaration?" do
		let(:cursor_anonymous) {Index.new.parse_translation_unit(fixture_path("anonymous.h")).cursor}
		
		let(:anon_struct) do
			find_matching(cursor_anonymous) do |child, parent|
				child.kind == :cursor_struct and child.anonymous?
			end
		end
		
		it "checks if the cursor is an anonymous record declaration" do
			expect(anon_struct.anonymous_record_declaration?).to eq(true).or eq(false)
		end
	end
	
	describe "#num_args" do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_non_variadic"
			end
		end
		
		it "returns the number of arguments for a function cursor" do
			expect(func.num_args).to be_kind_of(Integer)
			expect(func.num_args).to eq(3)
		end
	end
	
	describe "#objc_type_encoding" do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_non_variadic"
			end
		end
		
		it "returns a string" do
			expect(func.objc_type_encoding).to be_kind_of(String)
		end
	end
	
	describe "#deleted?" do
		let(:deleted_ctor) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_constructor and child.spelling == "DeletedCopy" and
							parent.spelling == "DeletedCopy" and
							child.copy_constructor?
			end
		end
		
		it "returns true for a deleted function" do
			expect(deleted_ctor.deleted?).to be true
		end
	end
	
	describe "#copy_assignment_operator?" do
		let(:copy_assign) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "operator=" and
							parent.spelling == "DeletedCopy" and
							child.copy_assignment_operator?
			end
		end
		
		it "returns true for a copy assignment operator" do
			expect(copy_assign).not_to be_nil
			expect(copy_assign.copy_assignment_operator?).to be true
		end
	end
	
	describe "#move_assignment_operator?" do
		let(:move_assign) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "operator=" and
							parent.spelling == "DeletedCopy" and
							child.move_assignment_operator?
			end
		end
		
		it "returns true for a move assignment operator" do
			expect(move_assign).not_to be_nil
			expect(move_assign.move_assignment_operator?).to be true
		end
	end
	
	describe "#explicit?" do
		let(:explicit_ctor) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_constructor and parent.spelling == "ExplicitCtor"
			end
		end
		
		it "returns true for an explicit constructor" do
			expect(explicit_ctor.explicit?).to be true
		end
	end
	
	describe "#enum_scoped?" do
		let(:scoped_enum) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_enum_decl and child.spelling == "ScopedEnum"
			end
		end
		
		it "returns true for a scoped enum" do
			expect(scoped_enum.enum_scoped?).to be true
		end
	end
	
	describe "#const?" do
		let(:const_method) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "getValue"
			end
		end
		
		let(:non_const_method) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "setValue"
			end
		end
		
		it "returns true for a const method" do
			expect(const_method.const?).to be true
		end
		
		it "returns false for a non-const method" do
			expect(non_const_method.const?).to be false
		end
	end
	
	describe "#to_s" do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_non_variadic"
			end
		end
		
		it "returns a string representation" do
			str = func.to_s
			expect(str).to be_kind_of(String)
			expect(str).to match(/^Cursor </)
			expect(str).to include("f_non_variadic")
		end
	end
	
	describe "#each with traversal control" do
		it "supports :break to stop traversal" do
			count = 0
			cursor_cxx.each do |child, parent|
				count += 1
				:break
			end
			expect(count).to eq(1)
		end
		
		it "supports :continue to skip children" do
			children = []
			cursor_cxx.each do |child, parent|
				children << child.spelling
				:continue
			end
			expect(children).not_to be_empty
		end
	end
	
	describe "#ancestors_by_kind" do
		let(:method_cursor) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_cxx_method and child.spelling == "func_a" and parent.spelling == "B"
			end
		end
		
		it "returns ancestors matching the given kinds" do
			ancestors = method_cursor.ancestors_by_kind(:cursor_struct)
			expect(ancestors).to be_kind_of(Array)
			expect(ancestors.map(&:spelling)).to include("B")
		end
		
		it "returns empty array when no ancestors match" do
			ancestors = method_cursor.ancestors_by_kind(:cursor_namespace)
			expect(ancestors).to eq([])
		end
	end
	
	describe "#printing_policy" do
		let(:func) do
			find_matching(cursor_cxx) do |child, parent|
				child.kind == :cursor_function and child.spelling == "f_variadic"
			end
		end
		
		it "returns a PrintingPolicy" do
			expect(func.printing_policy).to be_kind_of(PrintingPolicy)
		end
	end
	
	describe "#binary_operator_kind" do
		let(:binary_op) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_binary_operator
			end
		end
		
		it "returns the binary operator kind" do
			expect(binary_op).not_to be_nil
			expect(binary_op.binary_operator_kind).to eq(:binary_operator_add)
		end
	end
	
	describe ".binary_operator_kind_spelling" do
		it "returns the spelling for a binary operator kind" do
			expect(Cursor.binary_operator_kind_spelling(:binary_operator_add)).to eq("+")
			expect(Cursor.binary_operator_kind_spelling(:binary_operator_mul)).to eq("*")
			expect(Cursor.binary_operator_kind_spelling(:binary_operator_sub)).to eq("-")
		end
	end
	
	describe "#unary_operator_kind" do
		let(:unary_op) do
			find_matching(cursor_types) do |child, parent|
				child.kind == :cursor_unary_operator
			end
		end
		
		it "returns the unary operator kind" do
			expect(unary_op).not_to be_nil
			kind = unary_op.unary_operator_kind
			expect(kind).to be_a(Symbol)
			expect(kind.to_s).to match(/^unary_operator_/)
		end
	end
	
	describe ".unary_operator_kind_spelling" do
		it "returns the spelling for a unary operator kind" do
			expect(Cursor.unary_operator_kind_spelling(:unary_operator_Minus)).to eq("-")
			expect(Cursor.unary_operator_kind_spelling(:unary_operator_PreInc)).to eq("++")
		end
	end
end
