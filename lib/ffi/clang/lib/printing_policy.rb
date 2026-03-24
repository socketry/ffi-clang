# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2026, by Charlie Savage.
# Copyright, 2024-2025, by Samuel Williams.

module FFI
	module Clang
		module Lib
			typedef :pointer, :CXPrintingPolicy
			
			PrintingPolicyProperty = enum [
				:printing_policy_indentation,
				:printing_policy_suppress_specifiers,
				:printing_policy_suppress_tag_keyword,
				:printing_policy_include_tag_definition,
				:printing_policy_suppress_scope,
				:printing_policy_suppress_unwritten_scope,
				:printing_policy_suppress_initializers,
				:printing_policy_constant_array_size_as_written,
				:printing_policy_anonymous_tag_locations,
				:printing_policy_suppress_strong_lifetime,
				:printing_policy_suppress_lifetime_qualifiers,
				:printing_policy_suppress_template_args_in_cxx_constructors,
				:printing_policy_bool,
				:printing_policy_restrict,
				:printing_policy_alignof,
				:printing_policy_underscore_alignof,
				:printing_policy_use_void_for_zero_params,
				:printing_policy_terse_output,
				:printing_policy_polish_for_declaration,
				:printing_policy_half,
				:printing_policy_msw_char,
				:printing_policy_include_new_lines,
				:printing_policy_msvc_formatting,
				:printing_policy_constants_as_written,
				:printing_policy_suppress_implicit_base,
				:printing_policy_fully_qualified_name,
				:printing_policy_last_property
			]
			
			attach_function :printing_policy_get_property, :clang_PrintingPolicy_getProperty, [:CXPrintingPolicy, PrintingPolicyProperty], :uint
			attach_function :printing_policy_set_property, :clang_PrintingPolicy_setProperty, [:CXPrintingPolicy, PrintingPolicyProperty, :uint], :void
			attach_function :get_printing_policy, :clang_getCursorPrintingPolicy, [CXCursor.by_value], :CXPrintingPolicy
			attach_function :dispose_printing_policy, :clang_PrintingPolicy_dispose, [:CXPrintingPolicy], :void
			attach_function :pretty_print, :clang_getCursorPrettyPrinted, [CXCursor.by_value, :CXPrintingPolicy], CXString.by_value
			
			if Clang.clang_version >= Gem::Version.new("21.0.0")
				attach_function :get_type_pretty_printed, :clang_getTypePrettyPrinted, [CXType.by_value, :CXPrintingPolicy], CXString.by_value
				attach_function :get_fully_qualified_name, :clang_getFullyQualifiedName, [CXType.by_value, :CXPrintingPolicy, :uint], CXString.by_value
			end
		end
	end
end
