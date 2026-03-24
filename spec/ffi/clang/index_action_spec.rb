# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Charlie Savage.

describe IndexAction do
	let(:index) {Index.new}
	let(:action) {IndexAction.new(index)}
	let(:source_file) {fixture_path("indexing.c")}
	let(:included_header) {fixture_path("extra.h")}
	let(:command_line_args) {["-std=c99"]}
	let(:translation_unit_opts) {[:detailed_preprocessing_record]}
	let(:translation_unit) {index.parse_translation_unit(source_file, command_line_args, [], translation_unit_opts)}
	let(:root_cursor) {translation_unit.cursor}
	let(:main_file) {translation_unit.file}
	let(:included_file) {translation_unit.file(included_header)}
	let(:global_value_cursor) {find_matching(root_cursor){|cursor, _parent| cursor.kind == :cursor_variable && cursor.spelling == "global_value"}}
	let(:use_global_cursor) {find_matching(root_cursor){|cursor, _parent| cursor.kind == :cursor_function && cursor.spelling == "use_global"}}
	let(:extra_function_cursor) {find_matching(root_cursor){|cursor, _parent| cursor.kind == :cursor_function && cursor.spelling == "extra_function"}}
	let(:global_value_reference_cursor) {find_matching(root_cursor){|cursor, _parent| cursor.kind == :cursor_decl_ref_expr && cursor.spelling == "global_value"}}
	let(:extra_function_reference_cursor) {find_matching(root_cursor){|cursor, _parent| cursor.kind == :cursor_call_expr && cursor.spelling == "extra_function"}}
	
	def build_entity_info(cursor, kind, name, usr = "usr:#{name}")
		info = FFI::Clang::Lib::CXIdxEntityInfo.new
		name_pointer = FFI::MemoryPointer.from_string(name)
		usr_pointer = FFI::MemoryPointer.from_string(usr)
		
		info[:kind] = kind
		info[:template_kind] = :non_template
		info[:language] = :c
		info[:name] = name_pointer
		info[:usr] = usr_pointer
		info[:cursor] = cursor.cursor
		
		return info, [name_pointer, usr_pointer]
	end
	
	def build_decl_info(cursor, entity_info, is_definition: false, flags: [])
		info = FFI::Clang::Lib::CXIdxDeclInfo.new
		
		info[:entity_info] = entity_info.pointer
		info[:cursor] = cursor.cursor
		info[:loc] = FFI::Clang::Lib::CXIdxLoc.new
		info[:is_definition] = is_definition ? 1 : 0
		info[:flags] = FFI::Clang::Lib.bitmask_from(FFI::Clang::Lib::IdxDeclInfoFlags, flags)
		
		info
	end
	
	def build_entity_reference_info(cursor, referenced_entity, roles)
		info = FFI::Clang::Lib::CXIdxEntityRefInfo.new
		
		info[:kind] = :direct
		info[:cursor] = cursor.cursor
		info[:loc] = FFI::Clang::Lib::CXIdxLoc.new
		info[:referenced_entity] = referenced_entity.pointer
		info[:role] = FFI::Clang::Lib.bitmask_from(FFI::Clang::Lib::SymbolRole, roles)
		
		info
	end
	
	def build_included_file_info(file, filename)
		info = FFI::Clang::Lib::CXIdxIncludedFileInfo.new
		filename_pointer = FFI::MemoryPointer.from_string(filename)
		
		info[:hash_loc] = FFI::Clang::Lib::CXIdxLoc.new
		info[:filename] = filename_pointer
		info[:file] = file
		
		return info, [filename_pointer]
	end
	
	def emit_indexing_events(callbacks)
		included_file_info, _included_backing = build_included_file_info(included_file, "extra.h")
		global_value_entity_info, _global_value_backing = build_entity_info(global_value_cursor, :variable, "global_value")
		use_global_entity_info, _use_global_backing = build_entity_info(use_global_cursor, :function, "use_global")
		extra_function_entity_info, _extra_function_backing = build_entity_info(extra_function_cursor, :function, "extra_function")
		global_value_decl_info = build_decl_info(global_value_cursor, global_value_entity_info, is_definition: true)
		use_global_decl_info = build_decl_info(use_global_cursor, use_global_entity_info, is_definition: true)
		diagnostic_set_pointer = FFI::MemoryPointer.new(:char, 1)
		diagnostic_pointer = FFI::MemoryPointer.new(:char, 1)
		@diagnostic_payload = Object.new
		global_value_reference_info = build_entity_reference_info(global_value_reference_cursor, global_value_entity_info, [:reference])
		extra_function_reference_info = build_entity_reference_info(extra_function_reference_cursor, extra_function_entity_info, [:reference, :call])
		
		allow(FFI::Clang::Lib).to receive(:get_num_diagnostics_in_set).with(diagnostic_set_pointer).and_return(1)
		allow(FFI::Clang::Lib).to receive(:get_diagnostic_in_set).with(diagnostic_set_pointer, 0).and_return(diagnostic_pointer)
		allow(IndexAction::Diagnostic).to receive(:new).with(diagnostic_pointer).and_return(@diagnostic_payload)
		
		callbacks[:started_translation_unit].call(nil, nil)
		callbacks[:entered_main_file].call(nil, main_file, nil)
		callbacks[:pp_included_file].call(nil, included_file_info.pointer)
		callbacks[:index_declaration].call(nil, global_value_decl_info.pointer)
		callbacks[:index_declaration].call(nil, use_global_decl_info.pointer)
		callbacks[:diagnostic].call(nil, diagnostic_set_pointer, nil)
		callbacks[:index_entity_reference].call(nil, global_value_reference_info.pointer)
		callbacks[:index_entity_reference].call(nil, extra_function_reference_info.pointer)
		
		@diagnostic_payload
	end
	
	def stub_index_source_file(entry_point)
		returned_translation_unit_pointer = FFI::MemoryPointer.new(:char, 1)
		
		allow(TranslationUnit).to receive(:new).and_call_original
		allow(TranslationUnit).to receive(:new).with(returned_translation_unit_pointer, index).and_return(translation_unit)
		allow(FFI::Clang::Lib).to receive(entry_point) do |_action, _client_data, callbacks, _callback_size, _index_opts, _source_filename, _args_pointer, _args_length, _unsaved_files, _unsaved_length, out_tu, _tu_opts|
			emit_indexing_events(callbacks)
			out_tu.write_pointer(returned_translation_unit_pointer)
			:cx_error_success
		end
	end
	
	it "indexes a source file and yields high-level events" do
		stub_index_source_file(:index_source_file)
		
		events = []
		
		returned_translation_unit = action.index_source_file(source_file, command_line_args, [], [], translation_unit_opts) do |event, payload|
			events << [event, payload]
		end
		
		expect(returned_translation_unit).to eq(translation_unit)
		expect(events.map(&:first)).to include(:started_translation_unit, :entered_main_file, :included_file, :declaration, :diagnostic, :reference)
		
		main_file = events.find{|event, _payload| event == :entered_main_file}.last
		expect(main_file).to be_kind_of(FFI::Clang::File)
		expect(main_file.name).to eq(source_file)
		
		included_file = events.find do |event, payload|
			event == :included_file && payload.filename == "extra.h"
		end.last
		expect(included_file).to be_kind_of(IndexAction::IncludedFile)
		expect(included_file.file).to be_kind_of(FFI::Clang::File)
		expect(included_file.file.name).to end_with("extra.h")
		expect(included_file.import?).to be false
		expect(included_file.angled?).to be false
		expect(included_file.module_import?).to be false
		
		declarations = events.select{|event, _payload| event == :declaration}.map(&:last)
		expect(declarations.map{|declaration| declaration.entity&.name}).to include("global_value", "use_global")
		
		use_global = declarations.find{|declaration| declaration.entity&.name == "use_global"}
		expect(use_global).to be_kind_of(IndexAction::Declaration)
		expect(use_global.definition?).to be true
		expect(use_global.cursor.spelling).to eq("use_global")
		
		diagnostics = events.select{|event, _payload| event == :diagnostic}.map(&:last)
		expect(diagnostics.length).to eq(1)
		expect(diagnostics.first.length).to eq(1)
		expect(diagnostics.first.first).to equal(@diagnostic_payload)
		
		references = events.select{|event, _payload| event == :reference}.map(&:last)
		expect(references.map{|reference| reference.referenced_entity&.name}).to include("global_value", "extra_function")
		
		global_value_reference = references.find{|reference| reference.referenced_entity&.name == "global_value"}
		expect(global_value_reference.roles).to include(:reference)
		
		extra_function_reference = references.find{|reference| reference.referenced_entity&.name == "extra_function"}
		expect(extra_function_reference.roles).to include(:call)
	end
	
	it "indexes an existing translation unit and preserves it on emitted cursors" do
		declarations = []
		
		allow(FFI::Clang::Lib).to receive(:index_translation_unit) do |_action, _client_data, callbacks, _callback_size, _index_opts, _translation_unit|
			emit_indexing_events(callbacks)
			:cx_error_success
		end
		
		returned_translation_unit = action.index_translation_unit(translation_unit) do |event, payload|
			declarations << payload if event == :declaration
		end
		
		expect(returned_translation_unit).to eq(translation_unit)
		
		use_global = declarations.find{|declaration| declaration.entity&.name == "use_global"}
		expect(use_global.cursor.translation_unit).to eq(translation_unit)
		expect(use_global.entity.cursor.translation_unit).to eq(translation_unit)
	end
	
	it "returns nil when indexing is aborted" do
		allow(FFI::Clang::Lib).to receive(:index_translation_unit) do |_action, _client_data, callbacks, _callback_size, _index_opts, _translation_unit|
			use_global_entity_info, _use_global_backing = build_entity_info(use_global_cursor, :function, "use_global")
			use_global_decl_info = build_decl_info(use_global_cursor, use_global_entity_info, is_definition: true)
			
			callbacks[:index_declaration].call(nil, use_global_decl_info.pointer)
			callbacks[:abort_query].call(nil, nil)
			
			:cx_error_success
		end
		
		result = action.index_translation_unit(translation_unit) do |event, _payload|
			:abort if event == :declaration
		end
		
		expect(result).to be_nil
	end
	
	it "indexes a source file with a full compiler invocation" do
		stub_index_source_file(:index_source_file_full_argv)
		
		events = []
		
		returned_translation_unit = action.index_source_file_with_invocation(source_file, ["clang", *command_line_args], [], [], translation_unit_opts) do |event, payload|
			events << [event, payload]
		end
		
		expect(returned_translation_unit).to eq(translation_unit)
		expect(events.map(&:first)).to include(:started_translation_unit, :entered_main_file)
	end
	
	it "raises on indexing failure" do
		allow(FFI::Clang::Lib).to receive(:index_source_file).and_return(:cx_error_failure)
		
		expect do
			action.index_source_file(source_file, command_line_args, [], [], translation_unit_opts){}
		end.to raise_error(FFI::Clang::Error, /cx_error_failure/)
	end
	
	it "returns an Enumerator when no block is given" do
		enumerator = action.index_source_file(source_file, command_line_args, [], [], translation_unit_opts)
		
		expect(enumerator).to be_kind_of(Enumerator)
	end
end

describe Index do
	let(:index) {Index.new}
	let(:source_file) {fixture_path("indexing.c")}
	let(:command_line_args) {["-std=c99"]}
	let(:translation_unit_opts) {[:detailed_preprocessing_record]}
	let(:translation_unit) {index.parse_translation_unit(source_file, command_line_args, [], translation_unit_opts)}
	
	it "creates reusable index actions" do
		expect(index.create_action).to be_kind_of(IndexAction)
	end
	
	it "provides a convenience source file indexing method" do
		action = instance_double(IndexAction)
		
		expect(index).to receive(:create_action).and_return(action)
		expect(action).to receive(:index_source_file).with(source_file, command_line_args, [], [], translation_unit_opts).and_return(translation_unit)
		
		expect(index.index_source_file(source_file, command_line_args, [], [], translation_unit_opts){}).to eq(translation_unit)
	end
	
	it "provides a convenience full invocation indexing method" do
		action = instance_double(IndexAction)
		full_argv = ["clang", *command_line_args]
		
		expect(index).to receive(:create_action).and_return(action)
		expect(action).to receive(:index_source_file_with_invocation).with(source_file, full_argv, [], [], translation_unit_opts).and_return(translation_unit)
		
		expect(index.index_source_file_with_invocation(source_file, full_argv, [], [], translation_unit_opts){}).to eq(translation_unit)
	end
	
	it "provides a convenience translation unit indexing method" do
		action = instance_double(IndexAction)
		
		expect(index).to receive(:create_action).and_return(action)
		expect(action).to receive(:index_translation_unit).with(translation_unit, []).and_return(translation_unit)
		
		expect(index.index_translation_unit(translation_unit){}).to eq(translation_unit)
	end
end
