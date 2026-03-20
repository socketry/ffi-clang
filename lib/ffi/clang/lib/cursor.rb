# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Garry Marshall.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013, by Dave Wilkinson.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2013-2014, by Masahiro Sano.
# Copyright, 2014, by George Pimm.
# Copyright, 2014, by Niklas Therning.
# Copyright, 2019, by Michael Metivier.
# Copyright, 2020, by Zete Lui.
# Copyright, 2023-2024, by Charlie Savage.

require_relative "translation_unit"
require_relative "diagnostic"
require_relative "comment"
require_relative "type"

module FFI
	module Clang
		module Lib
			# In Clang 15 the enum value changed from 300 to 350!
			CUSOR_TRANSLATION_UNIT = Clang.clang_version < Gem::Version.new("15.0.0") ? 300 : 350
			
			enum :cursor_kind, [
				:cursor_unexposed_decl, 1,
				:cursor_struct, 2,
				# :cursor_struct_decl, :cursor_struct
				:cursor_union, 3,
				# :cursor_union_decl, :cursor_union
				:cursor_class_decl, 4,
				:cursor_enum_decl, 5,
				:cursor_field_decl, 6,
				:cursor_enum_constant_decl, 7,
				:cursor_function, 8,
				# :cursor_function_decl, :cursor_function,
				:cursor_variable, 9,
				# :cursor_var_decl, :cursor_variable,
				:cursor_parm_decl, 10,
				:cursor_obj_c_interface_decl, 11,
				:cursor_obj_c_category_decl, 12,
				:cursor_obj_c_protocol_decl, 13,
				:cursor_obj_c_property_decl, 14,
				:cursor_obj_c_instance_var_decl, 15,
				# :cursor_obj_c_ivar_decl, :cursor_obj_c_instance_var_decl,
				:cursor_obj_c_instance_method_decl, 16,
				:cursor_obj_c_class_method_decl, 17,
				:cursor_obj_c_implementation_decl, 18,
				:cursor_obj_c_category_impl_decl, 19,
				:cursor_typedef_decl, 20,
				:cursor_cxx_method, 21,
				:cursor_namespace, 22,
				:cursor_linkage_spec, 23,
				:cursor_constructor, 24,
				:cursor_destructor, 25,
				:cursor_conversion_function, 26,
				:cursor_template_type_parameter, 27,
				:cursor_non_type_template_parameter, 28,
				:cursor_template_template_parameter, 29,
				:cursor_function_template, 30,
				:cursor_class_template, 31,
				:cursor_class_template_partial_specialization, 32,
				:cursor_namespace_alias, 33,
				:cursor_using_directive, 34,
				:cursor_using_declaration, 35,
				:cursor_type_alias_decl, 36,
				:cursor_obj_c_synthesize_decl, 37,
				:cursor_obj_c_dynamic_decl, 38,
				:cursor_cxx_access_specifier, 39,
				# :cursor_first_decl, :cursor_unexposed_decl,
				# :cursor_last_decl, :cursor_cxx_access_specifier,
				:cursor_first_ref, 40,
				:cursor_obj_c_super_class_ref, 40,
				:cursor_obj_c_protocol_ref, 41,
				:cursor_obj_c_class_ref, 42,
				:cursor_type_ref, 43,
				:cursor_cxx_base_specifier, 44,
				:cursor_template_ref, 45,
				:cursor_namespace_ref, 46,
				:cursor_member_ref, 47,
				:cursor_label_ref, 48,
				:cursor_overloaded_decl_ref, 49,
				:cursor_variable_ref, 50,
				# :cursor_last_ref, :cursor_variable_ref,
				:cursor_first_invalid, 70,
				:cursor_invalid_file, 70,
				:cursor_no_decl_found, 71,
				:cursor_not_implemented, 72,
				:cursor_invalid_code, 73,
				# :cursor_last_invalid, :cursor_invalid_code,
				:cursor_first_expr, 100,
				:cursor_unexposed_expr, 100,
				:cursor_decl_ref_expr, 101,
				:cursor_member_ref_expr, 102,
				:cursor_call_expr, 103,
				:cursor_obj_c_message_expr, 104,
				:cursor_block_expr, 105,
				:cursor_integer_literal, 106,
				:cursor_floating_literal, 107,
				:cursor_imaginary_literal, 108,
				:cursor_string_literal, 109,
				:cursor_character_literal, 110,
				:cursor_paren_expr, 111,
				:cursor_unary_operator, 112,
				:cursor_array_subscript_expr, 113,
				:cursor_binary_operator, 114,
				:cursor_compound_assign_operator, 115,
				:cursor_conditional_operator, 116,
				:cursor_c_style_cast_expr, 117,
				:cursor_compound_literal_expr, 118,
				:cursor_init_list_expr, 119,
				:cursor_addr_label_expr, 120,
				:cursor_stmt_expr, 121,
				:cursor_generic_selection_expr, 122,
				:cursor_gnu_null_expr, 123,
				:cursor_cxx_static_cast_expr, 124,
				:cursor_cxx_dynamic_cast_expr, 125,
				:cursor_cxx_reinterpret_cast_expr, 126,
				:cursor_cxx_const_cast_expr, 127,
				:cursor_cxx_functional_cast_expr, 128,
				:cursor_cxx_typeid_expr, 129,
				:cursor_cxx_bool_literal_expr, 130,
				:cursor_cxx_null_ptr_literal_expr, 131,
				:cursor_cxx_this_expr, 132,
				:cursor_cxx_throw_expr, 133,
				:cursor_cxx_new_expr, 134,
				:cursor_cxx_delete_expr, 135,
				:cursor_unary_expr, 136,
				:cursor_obj_c_string_literal, 137,
				:cursor_obj_c_encode_expr, 138,
				:cursor_obj_c_selector_expr, 139,
				:cursor_obj_c_protocol_expr, 140,
				:cursor_obj_c_bridged_cast_expr, 141,
				:cursor_pack_expansion_expr, 142,
				:cursor_size_of_pack_expr, 143,
				:cursor_lambda_expr, 144,
				:cursor_obj_c_bool_literal_expr, 145,
				:cursor_obj_c_self_expr, 146,
				:cursor_omp_array_section_expr, 147,
				:cursor_obj_c_availability_check_expr, 148,
				:cursor_fixed_point_literal, 149,
				:cursor_omp_array_shaping_expr, 150,
				:cursor_omp_iterator_expr, 151,
				:cursor_cxx_addrspace_cast_expr, 152,
				:cursor_concept_specialization_expr, 153,
				:cursor_requires_expr, 154,
				:cursor_cxx_paren_list_init_expr, 155,
				:cursor_pack_indexing_expr, 156,
				# :cursor_last_expr, :cursor_pack_indexing_expr,
				:cursor_unexposed_stmt, 200,
				# :cursor_first_stmt, :cursor_unexposed_stmt,
				:cursor_label_stmt, 201,
				:cursor_compound_stmt, 202,
				:cursor_case_stmt, 203,
				:cursor_default_stmt, 204,
				:cursor_if_stmt, 205,
				:cursor_switch_stmt, 206,
				:cursor_while_stmt, 207,
				:cursor_do_stmt, 208,
				:cursor_for_stmt, 209,
				:cursor_goto_stmt, 210,
				:cursor_indirect_goto_stmt, 211,
				:cursor_continue_stmt, 212,
				:cursor_break_stmt, 213,
				:cursor_return_stmt, 214,
				:cursor_gcc_asm_stmt, 215,
				# :cursor_asm_stmt, :cursor_gcc_asm_stmt,
				:cursor_obj_c_at_try_stmt, 216,
				:cursor_obj_c_at_catch_stmt, 217,
				:cursor_obj_c_at_finally_stmt, 218,
				:cursor_obj_c_at_throw_stmt, 219,
				:cursor_obj_c_at_synchronized_stmt, 220,
				:cursor_obj_c_autorelease_pool_stmt, 221,
				:cursor_obj_c_for_collection_stmt, 222,
				:cursor_cxx_catch_stmt, 223,
				:cursor_cxx_try_stmt, 224,
				:cursor_cxx_for_range_stmt, 225,
				:cursor_seh_try_stmt, 226,
				:cursor_seh_except_stmt, 227,
				:cursor_seh_finally_stmt, 228,
				:cursor_ms_asm_stmt, 229,
				:cursor_null_stmt, 230,
				:cursor_decl_stmt, 231,
				:cursor_omp_parallel_directive, 232,
				:cursor_omp_simd_directive, 233,
				:cursor_omp_for_directive, 234,
				:cursor_omp_sections_directive, 235,
				:cursor_omp_section_directive, 236,
				:cursor_omp_single_directive, 237,
				:cursor_omp_parallel_for_directive, 238,
				:cursor_omp_parallel_sections_directive, 239,
				:cursor_omp_task_directive, 240,
				:cursor_omp_master_directive, 241,
				:cursor_omp_critical_directive, 242,
				:cursor_omp_taskyield_directive, 243,
				:cursor_omp_barrier_directive, 244,
				:cursor_omp_taskwait_directive, 245,
				:cursor_omp_flush_directive, 246,
				:cursor_seh_leave_stmt, 247,
				:cursor_omp_ordered_directive, 248,
				:cursor_omp_atomic_directive, 249,
				:cursor_omp_for_simd_directive, 250,
				:cursor_omp_parallel_for_simd_directive, 251,
				:cursor_omp_target_directive, 252,
				:cursor_omp_teams_directive, 253,
				:cursor_omp_taskgroup_directive, 254,
				:cursor_omp_cancellation_point_directive, 255,
				:cursor_omp_cancel_directive, 256,
				:cursor_omp_target_data_directive, 257,
				:cursor_omp_task_loop_directive, 258,
				:cursor_omp_task_loop_simd_directive, 259,
				:cursor_omp_distribute_directive, 260,
				:cursor_omp_target_enter_data_directive, 261,
				:cursor_omp_target_exit_data_directive, 262,
				:cursor_omp_target_parallel_directive, 263,
				:cursor_omp_target_parallel_for_directive, 264,
				:cursor_omp_target_update_directive, 265,
				:cursor_omp_distribute_parallel_for_directive, 266,
				:cursor_omp_distribute_parallel_for_simd_directive, 267,
				:cursor_omp_distribute_simd_directive, 268,
				:cursor_omp_target_parallel_for_simd_directive, 269,
				:cursor_omp_target_simd_directive, 270,
				:cursor_omp_teams_distribute_directive, 271,
				:cursor_omp_teams_distribute_simd_directive, 272,
				:cursor_omp_teams_distribute_parallel_for_simd_directive, 273,
				:cursor_omp_teams_distribute_parallel_for_directive, 274,
				:cursor_omp_target_teams_directive, 275,
				:cursor_omp_target_teams_distribute_directive, 276,
				:cursor_omp_target_teams_distribute_parallel_for_directive, 277,
				:cursor_omp_target_teams_distribute_parallel_for_simd_directive, 278,
				:cursor_omp_target_teams_distribute_simd_directive, 279,
				:cursor_builtin_bit_cast_expr, 280,
				:cursor_omp_master_task_loop_directive, 281,
				:cursor_omp_parallel_master_task_loop_directive, 282,
				:cursor_omp_master_task_loop_simd_directive, 283,
				:cursor_omp_parallel_master_task_loop_simd_directive, 284,
				:cursor_omp_parallel_master_directive, 285,
				:cursor_omp_depobj_directive, 286,
				:cursor_omp_scan_directive, 287,
				:cursor_omp_tile_directive, 288,
				:cursor_omp_canonical_loop, 289,
				:cursor_omp_interop_directive, 290,
				:cursor_omp_dispatch_directive, 291,
				:cursor_omp_masked_directive, 292,
				:cursor_omp_unroll_directive, 293,
				:cursor_omp_meta_directive, 294,
				:cursor_omp_generic_loop_directive, 295,
				:cursor_omp_teams_generic_loop_directive, 296,
				:cursor_omp_target_teams_generic_loop_directive, 297,
				:cursor_omp_parallel_generic_loop_directive, 298,
				:cursor_omp_target_parallel_generic_loop_directive, 299,
				:cursor_omp_parallel_masked_directive, 300,
				:cursor_omp_masked_task_loop_directive, 301,
				:cursor_omp_masked_task_loop_simd_directive, 302,
				:cursor_omp_parallel_masked_task_loop_directive, 303,
				:cursor_omp_parallel_masked_task_loop_simd_directive, 304,
				:cursor_omp_error_directive, 305,
				:cursor_omp_scope_directive, 306,
				:cursor_omp_reverse_directive, 307,
				:cursor_omp_interchange_directive, 308,
				:cursor_omp_assume_directive, 309,
				:cursor_omp_stripe_directive, 310,
				:cursor_open_acc_compute_construct, 320,
				:cursor_open_acc_loop_construct, 321,
				:cursor_open_acc_combined_construct, 322,
				:cursor_open_acc_data_construct, 323,
				:cursor_open_acc_enter_data_construct, 324,
				:cursor_open_acc_exit_data_construct, 325,
				:cursor_open_acc_host_data_construct, 326,
				:cursor_open_acc_wait_construct, 327,
				:cursor_open_acc_init_construct, 328,
				:cursor_open_acc_shutdown_construct, 329,
				:cursor_open_acc_set_construct, 330,
				:cursor_open_acc_update_construct, 331,
				:cursor_open_acc_atomic_construct, 332,
				:cursor_open_acc_cache_construct, 333,
				# :cursor_last_stmt, :cursor_open_acc_cache_construct,
				:cursor_translation_unit, CUSOR_TRANSLATION_UNIT,
				:cursor_first_attr, 400,
				:cursor_unexposed_attr, 400,
				:cursor_ibaction_attr, 401,
				:cursor_iboutlet_attr, 402,
				:cursor_iboutlet_collection_attr, 403,
				:cursor_cxx_final_attr, 404,
				:cursor_cxx_override_attr, 405,
				:cursor_annotate_attr, 406,
				:cursor_asm_label_attr, 407,
				:cursor_packed_attr, 408,
				:cursor_pure_attr, 409,
				:cursor_const_attr, 410,
				:cursor_no_duplicate_attr, 411,
				:cursor_cuda_constant_attr, 412,
				:cursor_cuda_device_attr, 413,
				:cursor_cuda_global_attr, 414,
				:cursor_cuda_host_attr, 415,
				:cursor_cuda_shared_attr, 416,
				:cursor_visibility_attr, 417,
				:cursor_dll_export, 418,
				:cursor_dll_import, 419,
				:cursor_ns_returns_retained, 420,
				:cursor_ns_returns_not_retained, 421,
				:cursor_ns_returns_autoreleased, 422,
				:cursor_ns_consumes_self, 423,
				:cursor_ns_consumed, 424,
				:cursor_obj_c_exception, 425,
				:cursor_obj_c_ns_object, 426,
				:cursor_obj_c_independent_class, 427,
				:cursor_obj_c_precise_lifetime, 428,
				:cursor_obj_c_returns_inner_pointer, 429,
				:cursor_obj_c_requires_super, 430,
				:cursor_obj_c_root_class, 431,
				:cursor_obj_c_subclassing_restricted, 432,
				:cursor_obj_c_explicit_protocol_impl, 433,
				:cursor_obj_c_designated_initializer, 434,
				:cursor_obj_c_runtime_visible, 435,
				:cursor_obj_c_boxable, 436,
				:cursor_flag_enum, 437,
				:cursor_convergent_attr, 438,
				:cursor_warn_unused_attr, 439,
				:cursor_warn_unused_result_attr, 440,
				:cursor_aligned_attr, 441,
				# :cursor_last_attr, :cursor_aligned_attr,
				:cursor_preprocessing_directive, 500,
				:cursor_macro_definition, 501,
				:cursor_macro_expansion, 502,
				# :cursor_macro_instantiation, :cursor_macro_expansion,
				:cursor_inclusion_directive, 503,
				# :cursor_first_preprocessing, :cursor_preprocessing_directive,
				# :cursor_last_preprocessing, :cursor_inclusion_directive,
				:cursor_module_import_decl, 600,
				:cursor_type_alias_template_decl, 601,
				:cursor_static_assert, 602,
				:cursor_friend_decl, 603,
				:cursor_concept_decl, 604,
				# :cursor_first_extra_decl, :cursor_module_import_decl,
				# :cursor_last_extra_decl, :cursor_concept_decl,
				:cursor_overload_candidate, 700
			]
			
			enum :access_specifier, [
				:invalid, 0,
				:public, 1,
				:protected, 2,
				:private, 3
			]
			
			enum :availability, [
				:available, 0,
				:deprecated, 1,
				:not_available, 2,
				:not_accesible, 3
			]
			
			enum :linkage_kind, [
				:invalid, 0,
				:no_linkage, 1,
				:internal, 2,
				:unique_external, 3,
				:external, 4,
			]
			
			enum :exception_specification_type, [
				:none,
				:dynamic_none,
				:dynamic,
				:ms_any,
				:basic_noexcept,
				:computed_noexcept,
				:unevaluated,
				:uninstantiated,
				:unparsed,
				:no_throw
			]
			
			# FFI struct representing a cursor in the libclang AST.
			# @private
			class CXCursor < FFI::Struct
				layout(
					:kind, :cursor_kind,
					:xdata, :int,
					:data, [:pointer, 3]
				)
			end
			
			# FFI struct representing a version number with major, minor, and subminor components.
			# @private
			class CXVersion < FFI::Struct
				layout(
					:major, :int,
					:minor, :int,
					:subminor, :int,
				)
				
				# Get the major version number.
				# @returns [Integer] The major version.
				def major
					self[:major]
				end
				
				# Get the minor version number.
				# @returns [Integer] The minor version.
				def minor
					self[:minor]
				end
				
				# Get the subminor version number.
				# @returns [Integer] The subminor version.
				def subminor
					self[:subminor]
				end
				
				# Get the version as a string.
				# @returns [String] The version string (e.g., "1.2.3").
				def version_string
					[major, minor, subminor].reject{|v| v < 0}.map(&:to_s).join(".")
				end
				
				# Convert to a string representation.
				# @returns [String] The version string.
				def to_s
					version_string
				end
			end
			
			# FFI struct representing platform-specific availability information.
			# @private
			class CXPlatformAvailability < FFI::Struct
				layout(
					:platform, CXString,
					:introduced, CXVersion,
					:deprecated, CXVersion,
					:obsoleted, CXVersion,
					:unavailable, :int,
					:message, CXString,
				)
			end
			
			enum :visitor_result, [:break, :continue]
			
			# FFI struct for visiting cursors and ranges.
			# @private
			class CXCursorAndRangeVisitor < FFI::Struct
				layout(
					:context, :pointer,
					:visit, callback([:pointer, CXCursor.by_value, CXSourceRange.by_value], :visitor_result),
				)
			end
			
			enum :cxx_access_specifier, [:invalid, :public, :protected, :private]
			attach_function :get_cxx_access_specifier, :clang_getCXXAccessSpecifier, [CXCursor.by_value], :cxx_access_specifier
			
			attach_function :get_enum_value, :clang_getEnumConstantDeclValue, [CXCursor.by_value], :long_long
			attach_function :get_enum_unsigned_value, :clang_getEnumConstantDeclUnsignedValue, [CXCursor.by_value], :ulong_long
			
			attach_function :is_virtual_base, :clang_isVirtualBase, [CXCursor.by_value], :uint
			attach_function :is_dynamic_call, :clang_Cursor_isDynamicCall, [CXCursor.by_value], :uint
			attach_function :is_variadic, :clang_Cursor_isVariadic, [CXCursor.by_value], :uint
			
			attach_function :is_definition, :clang_isCursorDefinition, [CXCursor.by_value], :uint
			attach_function :cxx_method_is_static, :clang_CXXMethod_isStatic, [CXCursor.by_value], :uint
			attach_function :cxx_method_is_virtual, :clang_CXXMethod_isVirtual, [CXCursor.by_value], :uint
			
			attach_function :cxx_method_is_pure_virtual, :clang_CXXMethod_isPureVirtual, [CXCursor.by_value], :uint
			
			attach_function :cxx_get_access_specifier, :clang_getCXXAccessSpecifier, [CXCursor.by_value], :access_specifier
			
			enum :language_kind, [:invalid, :c, :obj_c, :c_plus_plus]
			attach_function :get_language, :clang_getCursorLanguage, [CXCursor.by_value], :language_kind
			
			attach_function :get_canonical_cursor, :clang_getCanonicalCursor, [CXCursor.by_value], CXCursor.by_value
			attach_function :get_cursor_definition, :clang_getCursorDefinition, [CXCursor.by_value], CXCursor.by_value
			attach_function :get_specialized_cursor_template, :clang_getSpecializedCursorTemplate, [CXCursor.by_value], CXCursor.by_value
			attach_function :get_template_cursor_kind, :clang_getTemplateCursorKind, [CXCursor.by_value], :cursor_kind
			
			attach_function :get_translation_unit_cursor, :clang_getTranslationUnitCursor, [:CXTranslationUnit], CXCursor.by_value
			attach_function :cursor_get_translation_unit, :clang_Cursor_getTranslationUnit, [CXCursor.by_value], :CXTranslationUnit
			
			attach_function :get_null_cursor, :clang_getNullCursor, [], CXCursor.by_value
			
			attach_function :cursor_is_null, :clang_Cursor_isNull, [CXCursor.by_value], :int
			
			attach_function :cursor_get_comment_range, :clang_Cursor_getCommentRange, [CXCursor.by_value], CXSourceRange.by_value
			attach_function :cursor_get_raw_comment_text, :clang_Cursor_getRawCommentText, [CXCursor.by_value], CXString.by_value
			attach_function :cursor_get_parsed_comment, :clang_Cursor_getParsedComment, [CXCursor.by_value], CXComment.by_value
			
			attach_function :get_cursor, :clang_getCursor, [:CXTranslationUnit, CXSourceLocation.by_value], CXCursor.by_value
			attach_function :get_cursor_location, :clang_getCursorLocation, [CXCursor.by_value], CXSourceLocation.by_value
			attach_function :get_cursor_extent, :clang_getCursorExtent, [CXCursor.by_value], CXSourceRange.by_value
			attach_function :get_cursor_display_name, :clang_getCursorDisplayName, [CXCursor.by_value], CXString.by_value
			attach_function :get_cursor_spelling, :clang_getCursorSpelling, [CXCursor.by_value], CXString.by_value
			attach_function :get_cursor_usr, :clang_getCursorUSR, [CXCursor.by_value], CXString.by_value
			attach_function :get_cursor_kind_spelling, :clang_getCursorKindSpelling, [:cursor_kind], CXString.by_value
			
			attach_function :are_equal, :clang_equalCursors, [CXCursor.by_value, CXCursor.by_value], :uint
			
			attach_function :is_declaration, :clang_isDeclaration, [:cursor_kind], :uint
			attach_function :is_reference, :clang_isReference, [:cursor_kind], :uint
			attach_function :is_expression, :clang_isExpression, [:cursor_kind], :uint
			attach_function :is_statement, :clang_isStatement, [:cursor_kind], :uint
			attach_function :is_attribute, :clang_isAttribute, [:cursor_kind], :uint
			attach_function :is_invalid, :clang_isInvalid, [:cursor_kind], :uint
			attach_function :is_translation_unit, :clang_isTranslationUnit, [:cursor_kind], :uint
			attach_function :is_preprocessing, :clang_isPreprocessing, [:cursor_kind], :uint
			attach_function :is_unexposed, :clang_isUnexposed, [:cursor_kind], :uint
			
			enum :child_visit_result, [:break, :continue, :recurse]
			
			callback :visit_children_function, [CXCursor.by_value, CXCursor.by_value, :pointer], :child_visit_result
			attach_function :visit_children, :clang_visitChildren, [CXCursor.by_value, :visit_children_function, :pointer], :uint
			
			callback :visit_fields_callback, [CXCursor.by_value, :pointer], :uint
			attach_function :type_visit_fields, :clang_Type_visitFields, [CXType.by_value, :visit_fields_callback, :pointer], :uint
			
			enum :result, [:success, :invalid, :visit_break]
			attach_function :find_references_in_file, :clang_findReferencesInFile, [CXCursor.by_value, :CXFile, CXCursorAndRangeVisitor.by_value], :result
			
			attach_function :get_cursor_type, :clang_getCursorType, [CXCursor.by_value], CXType.by_value
			attach_function :cursor_is_anonymous, :clang_Cursor_isAnonymous, [CXCursor.by_value], :uint
			attach_function :cursor_is_anonymous_record_decl, :clang_Cursor_isAnonymousRecordDecl, [CXCursor.by_value], :uint
			attach_function :get_cursor_result_type, :clang_getCursorResultType, [CXCursor.by_value], CXType.by_value
			attach_function :get_typedef_decl_underlying_type, :clang_getTypedefDeclUnderlyingType, [CXCursor.by_value], CXType.by_value
			attach_function :get_enum_decl_integer_type, :clang_getEnumDeclIntegerType, [CXCursor.by_value], CXType.by_value
			attach_function :get_type_declaration, :clang_getTypeDeclaration, [CXType.by_value], FFI::Clang::Lib::CXCursor.by_value
			
			attach_function :get_cursor_referenced, :clang_getCursorReferenced, [CXCursor.by_value], CXCursor.by_value
			attach_function :get_cursor_semantic_parent, :clang_getCursorSemanticParent, [CXCursor.by_value], CXCursor.by_value
			attach_function :get_cursor_lexical_parent, :clang_getCursorLexicalParent, [CXCursor.by_value], CXCursor.by_value
			
			attach_function :get_cursor_availability, :clang_getCursorAvailability, [CXCursor.by_value], :availability
			attach_function :get_cursor_linkage, :clang_getCursorLinkage, [CXCursor.by_value], :linkage_kind
			attach_function :get_cursor_exception_specification_type, :clang_getCursorExceptionSpecificationType, [CXCursor.by_value], :exception_specification_type
			attach_function :get_included_file, :clang_getIncludedFile, [CXCursor.by_value], :CXFile
			attach_function :get_cursor_hash, :clang_hashCursor, [CXCursor.by_value], :uint
			
			attach_function :is_bit_field,:clang_Cursor_isBitField, [CXCursor.by_value], :uint
			attach_function :get_field_decl_bit_width, :clang_getFieldDeclBitWidth, [CXCursor.by_value], :int
			
			attach_function :get_overloaded_decl, :clang_getOverloadedDecl, [CXCursor.by_value, :uint], CXCursor.by_value
			attach_function :get_num_overloaded_decls, :clang_getNumOverloadedDecls, [CXCursor.by_value], :uint
			
			attach_function :cursor_get_argument, :clang_Cursor_getArgument, [CXCursor.by_value, :uint], CXCursor.by_value
			attach_function :cursor_get_num_arguments, :clang_Cursor_getNumArguments, [CXCursor.by_value], :int
			
			attach_function :get_decl_objc_type_encoding, :clang_getDeclObjCTypeEncoding, [CXCursor.by_value], CXString.by_value
			
			attach_function :get_cursor_platform_availability, :clang_getCursorPlatformAvailability, [CXCursor.by_value, :pointer, :pointer, :pointer, :pointer, :pointer, :int], :int
			attach_function :dispose_platform_availability, :clang_disposeCXPlatformAvailability, [:pointer], :void
			
			attach_function :get_overridden_cursors, :clang_getOverriddenCursors, [CXCursor.by_value, :pointer, :pointer], :void
			attach_function :dispose_overridden_cursors, :clang_disposeOverriddenCursors, [:pointer], :void
			
			attach_function :get_num_args, :clang_Cursor_getNumArguments, [CXCursor.by_value], :int
			
			attach_function :is_converting_constructor, :clang_CXXConstructor_isConvertingConstructor, [CXCursor.by_value], :uint
			attach_function :is_copy_constructor, :clang_CXXConstructor_isCopyConstructor, [CXCursor.by_value], :uint
			attach_function :is_default_constructor, :clang_CXXConstructor_isDefaultConstructor, [CXCursor.by_value], :uint
			attach_function :is_move_constructor, :clang_CXXConstructor_isMoveConstructor, [CXCursor.by_value], :uint
			attach_function :is_mutable, :clang_CXXField_isMutable, [CXCursor.by_value], :uint
			attach_function :is_defaulted, :clang_CXXMethod_isDefaulted, [CXCursor.by_value], :uint
			attach_function :is_abstract, :clang_CXXRecord_isAbstract, [CXCursor.by_value], :uint
			attach_function :is_enum_scoped, :clang_EnumDecl_isScoped, [CXCursor.by_value], :uint
			attach_function :is_const, :clang_CXXMethod_isConst, [CXCursor.by_value], :uint
			
			enum :visibility_kind, [
				:visibility_invalid, 0,
				:visibility_hidden, 1,
				:visibility_protected, 2,
				:visibility_default, 3
			]
			
			enum :storage_class, [
				:sc_invalid, 0,
				:sc_none, 1,
				:sc_extern, 2,
				:sc_static, 3,
				:sc_private_extern, 4,
				:sc_opencl_work_group_local, 5,
				:sc_auto, 6,
				:sc_register, 7
			]
			
			enum :tls_kind, [
				:tls_none, 0,
				:tls_dynamic, 1,
				:tls_static, 2
			]
			
			attach_function :is_invalid_declaration, :clang_isInvalidDeclaration, [CXCursor.by_value], :uint
			attach_function :cursor_has_attrs, :clang_Cursor_hasAttrs, [CXCursor.by_value], :uint
			attach_function :get_cursor_visibility, :clang_getCursorVisibility, [CXCursor.by_value], :visibility_kind
			attach_function :cursor_get_storage_class, :clang_Cursor_getStorageClass, [CXCursor.by_value], :storage_class
			attach_function :cursor_get_tls_kind, :clang_getCursorTLSKind, [CXCursor.by_value], :tls_kind
			attach_function :cursor_is_function_inlined, :clang_Cursor_isFunctionInlined, [CXCursor.by_value], :uint
			attach_function :cursor_is_macro_function_like, :clang_Cursor_isMacroFunctionLike, [CXCursor.by_value], :uint
			attach_function :cursor_is_macro_builtin, :clang_Cursor_isMacroBuiltin, [CXCursor.by_value], :uint
			attach_function :cursor_has_var_decl_global_storage, :clang_Cursor_hasVarDeclGlobalStorage, [CXCursor.by_value], :uint
			attach_function :cursor_has_var_decl_external_storage, :clang_Cursor_hasVarDeclExternalStorage, [CXCursor.by_value], :uint
			attach_function :cursor_is_inline_namespace, :clang_Cursor_isInlineNamespace, [CXCursor.by_value], :uint
			attach_function :cursor_get_mangling, :clang_Cursor_getMangling, [CXCursor.by_value], CXString.by_value
			attach_function :cursor_get_offset_of_field, :clang_Cursor_getOffsetOfField, [CXCursor.by_value], :long_long
			attach_function :cursor_get_brief_comment_text, :clang_Cursor_getBriefCommentText, [CXCursor.by_value], CXString.by_value
			attach_function :cursor_get_spelling_name_range, :clang_Cursor_getSpellingNameRange, [CXCursor.by_value, :uint, :uint], CXSourceRange.by_value
			
			if Clang.clang_version >= Gem::Version.new("16.0.0")
				attach_function :get_unqualified_type, :clang_getUnqualifiedType, [CXType.by_value], CXType.by_value
				attach_function :get_non_reference_type, :clang_getNonReferenceType, [CXType.by_value], CXType.by_value
				attach_function :is_deleted, :clang_CXXMethod_isDeleted, [CXCursor.by_value], :uint
				attach_function :is_copy_assignment_operator, :clang_CXXMethod_isCopyAssignmentOperator, [CXCursor.by_value], :uint
				attach_function :is_move_assignment_operator, :clang_CXXMethod_isMoveAssignmentOperator, [CXCursor.by_value], :uint
			end
			
			if Clang.clang_version >= Gem::Version.new("17.0.0")
				attach_function :is_explicit, :clang_CXXMethod_isExplicit, [CXCursor.by_value], :uint
				
				enum :binary_operator_kind, [
					:binary_operator_invalid,
					:binary_operator_ptr_mem_d,
					:binary_operator_ptr_mem_i,
					:binary_operator_mul,
					:binary_operator_div,
					:binary_operator_rem,
					:binary_operator_add,
					:binary_operator_sub,
					:binary_operator_shl,
					:binary_operator_shr,
					:binary_operator_cmp,
					:binary_operator_lt,
					:binary_operator_gt,
					:binary_operator_le,
					:binary_operator_ge,
					:binary_operator_eq,
					:binary_operator_ne,
					:binary_operator_and,
					:binary_operator_xor,
					:binary_operator_or,
					:binary_operator_l_and,
					:binary_operator_l_or,
					:binary_operator_assign,
					:binary_operator_mul_assign,
					:binary_operator_div_assign,
					:binary_operator_rem_assign,
					:binary_operator_add_assign,
					:binary_operator_sub_assign,
					:binary_operator_shl_assign,
					:binary_operator_shr_assign,
					:binary_operator_and_assign,
					:binary_operator_xor_assign,
					:binary_operator_or_assign,
					:binary_operator_comma
				]
				
				attach_function :get_binary_operator_kind_spelling, :clang_getBinaryOperatorKindSpelling, [:binary_operator_kind], CXString.by_value
				attach_function :get_cursor_binary_operator_kind, :clang_getCursorBinaryOperatorKind, [CXCursor.by_value], :binary_operator_kind
				
				enum :unary_operator_kind, [
					:unary_operator_Invalid,
					:unary_operator_PostInc,
					:unary_operator_PostDec,
					:unary_operator_PreInc,
					:unary_operator_PreDec,
					:unary_operator_AddrOf,
					:unary_operator_Deref,
					:unary_operator_Plus,
					:unary_operator_Minus,
					:unary_operator_Not,
					:unary_operator_LNot,
					:unary_operator_Real,
					:unary_operator_Imag,
					:unary_operator_Extension,
					:unary_operator_Coawait
				]
				
				attach_function :get_unary_operator_kind_spelling, :clang_getUnaryOperatorKindSpelling, [:unary_operator_kind], CXString.by_value
				attach_function :get_cursor_unary_operator_kind, :clang_getCursorUnaryOperatorKind, [CXCursor.by_value], :unary_operator_kind
			end
		end
	end
end
