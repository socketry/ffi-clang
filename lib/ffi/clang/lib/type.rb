# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2013-2014, by Masahiro Sano.
# Copyright, 2014, by Niklas Therning.
# Copyright, 2024-2025, by Charlie Savage.

module FFI
	module Clang
		module Lib
			enum :kind, [
				:type_invalid, 0,
				:type_unexposed, 1,
				:type_void, 2,
				:type_bool, 3,
				:type_char_u, 4,
				:type_uchar, 5,
				:type_char16, 6,
				:type_char32, 7,
				:type_ushort, 8,
				:type_uint, 9,
				:type_ulong, 10,
				:type_ulonglong, 11,
				:type_uint128, 12,
				:type_char_s, 13,
				:type_schar, 14,
				:type_wchar, 15,
				:type_short, 16,
				:type_int, 17,
				:type_long, 18,
				:type_longlong, 19,
				:type_int128, 20,
				:type_float, 21,
				:type_double, 22,
				:type_longdouble, 23,
				:type_nullptr, 24,
				:type_overload, 25,
				:type_dependent, 26,
				:type_obj_c_id, 27,
				:type_obj_c_class, 28,
				:type_obj_c_sel, 29,
				:type_float128, 30,
				:type_half, 31,
				:type_float16, 32,
				:type_short_accum, 33,
				:type_accum, 34,
				:type_long_accum, 35,
				:type_ushort_accum, 36,
				:type_uaccum, 37,
				:type_ulong_accum, 38,
				:type_bfloat16, 39,
				:type_ibm128, 40,
				:type_complex, 100,
				:type_pointer, 101,
				:type_block_pointer, 102,
				:type_lvalue_ref, 103,
				:type_rvalue_ref, 104,
				:type_record, 105,
				:type_enum, 106,
				:type_typedef, 107,
				:type_obj_c_interface, 108,
				:type_obj_c_object_pointer, 109,
				:type_function_no_proto, 110,
				:type_function_proto, 111,
				:type_constant_array, 112,
				:type_vector, 113,
				:type_incomplete_array, 114,
				:type_variable_array, 115,
				:type_dependent_sized_array, 116,
				:type_member_pointer, 117,
				:type_auto, 118,
				:type_elaborated, 119,
				:type_pipe, 120,
				:type_ocl_image_1d_ro, 121,
				:type_ocl_image_1d_array_ro, 122,
				:type_ocl_image_1d_buffer_ro, 123,
				:type_ocl_image_2d_ro, 124,
				:type_ocl_image_2d_array_ro, 125,
				:type_ocl_image_2d_depth_ro, 126,
				:type_ocl_image_2d_array_depth_ro, 127,
				:type_ocl_image_2d_msaa_ro, 128,
				:type_ocl_image_2d_array_msaa_ro, 129,
				:type_ocl_image_2d_msaa_depth_ro, 130,
				:type_ocl_image_2d_array_msaa_depth_ro, 131,
				:type_ocl_image_3d_ro, 132,
				:type_ocl_image_1d_wo, 133,
				:type_ocl_image_1d_array_wo, 134,
				:type_ocl_image_1d_buffer_wo, 135,
				:type_ocl_image_2d_wo, 136,
				:type_ocl_image_2d_array_wo, 137,
				:type_ocl_image_2d_depth_wo, 138,
				:type_ocl_image_2d_arraydepth_wo, 139,
				:type_ocl_image_2d_msaa_wo, 140,
				:type_ocl_image_2d_array_msaa_wo, 141,
				:type_ocl_image_2d_msaa_depth_wo, 142,
				:type_ocl_image_2d_array_msaa_depth_wo, 143,
				:type_ocl_image_3d_wo, 144,
				:type_ocl_image_1d_rw, 145,
				:type_ocl_image_1d_array_rw, 146,
				:type_ocl_image_1d_buffer_rw, 147,
				:type_ocl_image_2d_rw, 148,
				:type_ocl_image_2d_array_rw, 149,
				:type_ocl_image_2d_depth_rw, 150,
				:type_ocl_image_2d_arraydepth_rw, 151,
				:type_ocl_image_2d_msaa_rw, 152,
				:type_ocl_image_2d_array_msaa_rw, 153,
				:type_ocl_image_2d_msaa_depth_rw, 154,
				:type_ocl_image_2d_array_msaa_depth_rw, 155,
				:type_ocl_image_3d_rw, 156,
				:type_ocl_sampler, 157,
				:type_ocl_event, 158,
				:type_ocl_queue, 159,
				:type_ocl_reserve_id, 160,
				:type_objc_object, 161,
				:type_objc_type_param, 162,
				:type_attributed, 163,
				:type_ocl_intel_subgroup_avc_mce_payload, 164,
				:type_ocl_intel_subgroup_avc_ime_payload, 165,
				:type_ocl_intel_subgroup_avc_ref_payload, 166,
				:type_ocl_intel_subgroup_avc_sic_payload, 167,
				:type_ocl_intel_subgroup_avc_mce_result, 168,
				:type_ocl_intel_subgroup_avc_ime_result, 169,
				:type_ocl_intel_subgroup_avc_ref_result, 170,
				:type_ocl_intel_subgroup_avc_sic_result, 171,
				:type_ocl_intel_subgroup_avc_ime_result_single_reference_streamout, 172,
				:type_ocl_intel_subgroup_avc_ime_result_dual_reference_streamout, 173,
				:type_ocl_intel_subgroup_avc_ime_single_reference_streamin, 174,
				:type_ocl_intel_subgroup_avc_ime_dual_reference_streamin, 175,
				:type_ocl_intel_subgroup_avc_ime_result_single_ref_streamout, 172,
				:type_ocl_intel_subgroup_avc_ime_result_dual_ref_streamout, 173,
				:type_ocl_intel_subgroup_avc_ime_single_ref_streamin, 174,
				:type_ocl_intel_subgroup_avc_ime_dual_ref_streamin, 175,
				:type_ext_vector, 176,
				:type_atomic, 177,
				:type_btf_tag_attributed, 178,
				:type_hlsl_resource, 179,
				:type_hlsl_attributed_resource, 180,
				:type_hlsl_inline_spirv, 181
			]
			
			enum :calling_conv, [
				:calling_conv_default, 0,
				:calling_conv_c, 1,
				:calling_conv_x86_stdcall, 2,
				:calling_conv_x86_fastcall, 3,
				:calling_conv_x86_thiscall, 4,
				:calling_conv_x86_pascal, 5,
				:calling_conv_aapcs, 6,
				:calling_conv_aapcs_vfp, 7,
				:calling_conv_pnacl_call, 8,
				:calling_conv_intel_ocl_bicc, 9,
				:calling_conv_x86_64_win64, 10,
				:calling_conv_x86_64_sysv, 11,
				:calling_conv_x86_vector_call, 12,
				:calling_conv_swift, 13,
				:calling_conv_preserve_most, 14,
				:calling_conv_preserve_all, 15,
				:calling_conv_aarch64_vector_call, 16,
				:calling_conv_swift_async, 17,
				:calling_conv_aarch64_sve_pcs, 18,
				:calling_conv_m68k_rtd, 19,
				:calling_conv_preserve_none, 20,
				:calling_conv_riscv_vector_call, 21,
				:calling_conv_invalid, 100,
				:calling_conv_unexposed, 200
			]
			
			enum :ref_qualifier_kind, [
				:ref_qualifier_none, 0,
				:ref_qualifier_lvalue, 1,
				:ref_qualifier_rvalue, 2,
			]
			
			enum :layout_error, [
				:layout_error_invalid, -1,
				:layout_error_incomplete, -2,
				:layout_error_dependent, -3,
				:layout_error_not_constant_size, -4,
				:layout_error_invalid_field_name, -5,
				:layout_error_undeduced, -6
			]
			
			# Also defined in cursor.rb
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
			
			# FFI struct representing a type in libclang.
			# @private
			class CXType < FFI::Struct
				layout(
					:kind, :kind,
					:data, [:pointer, 2]
				)
			end
			
			attach_function :get_type_kind_spelling, :clang_getTypeKindSpelling, [:kind], CXString.by_value
			attach_function :get_type_spelling, :clang_getTypeSpelling, [CXType.by_value], CXString.by_value
			attach_function :get_named_type, :clang_Type_getNamedType, [CXType.by_value], CXType.by_value
			
			attach_function :is_function_type_variadic, :clang_isFunctionTypeVariadic, [CXType.by_value], :uint
			attach_function :is_pod_type, :clang_isPODType, [CXType.by_value], :uint
			
			attach_function :get_pointee_type, :clang_getPointeeType, [CXType.by_value], CXType.by_value
			attach_function :get_result_type, :clang_getResultType, [CXType.by_value], CXType.by_value
			attach_function :get_canonical_type, :clang_getCanonicalType, [CXType.by_value], CXType.by_value
			
			attach_function :type_get_class_type, :clang_Type_getClassType, [CXType.by_value], CXType.by_value
			
			attach_function :is_const_qualified_type, :clang_isConstQualifiedType, [CXType.by_value], :uint
			attach_function :is_volatile_qualified_type, :clang_isVolatileQualifiedType, [CXType.by_value], :uint
			attach_function :is_restrict_qualified_type, :clang_isRestrictQualifiedType, [CXType.by_value], :uint
			
			attach_function :get_num_arg_types, :clang_getNumArgTypes, [CXType.by_value], :int
			attach_function :get_arg_type, :clang_getArgType, [CXType.by_value, :uint], CXType.by_value
			attach_function :get_num_elements, :clang_getNumElements, [CXType.by_value], :long_long
			attach_function :get_element_type, :clang_getElementType, [CXType.by_value], CXType.by_value
			attach_function :get_array_size, :clang_getArraySize, [CXType.by_value], :long_long
			attach_function :get_array_element_type ,:clang_getArrayElementType, [CXType.by_value], CXType.by_value
			
			attach_function :type_get_align_of, :clang_Type_getAlignOf, [CXType.by_value], :long_long
			attach_function :type_get_size_of, :clang_Type_getSizeOf, [CXType.by_value], :long_long
			attach_function :type_get_offset_of, :clang_Type_getOffsetOf, [CXType.by_value, :string], :long_long
			
			attach_function :type_get_cxx_ref_qualifier, :clang_Type_getCXXRefQualifier, [CXType.by_value], :ref_qualifier_kind
			
			attach_function :get_fuction_type_calling_conv, :clang_getFunctionTypeCallingConv, [CXType.by_value], :calling_conv
			attach_function :get_exception_specification_type, :clang_getExceptionSpecificationType, [CXType.by_value], :exception_specification_type
			
			attach_function :equal_types, :clang_equalTypes, [CXType.by_value, CXType.by_value], :uint
			
			attach_function :get_num_template_arguments, :clang_Type_getNumTemplateArguments, [CXType.by_value], :int
			attach_function :get_template_argument_as_type, :clang_Type_getTemplateArgumentAsType, [CXType.by_value, :uint], CXType.by_value
			
			attach_function :get_address_space, :clang_getAddressSpace, [CXType.by_value], :uint
			attach_function :get_typedef_name, :clang_getTypedefName, [CXType.by_value], CXString.by_value
			attach_function :type_is_transparent_tag_typedef, :clang_Type_isTransparentTagTypedef, [CXType.by_value], :uint
			attach_function :type_get_nullability, :clang_Type_getNullability, [CXType.by_value], :int
			attach_function :type_get_modified_type, :clang_Type_getModifiedType, [CXType.by_value], CXType.by_value
			attach_function :type_get_value_type, :clang_Type_getValueType, [CXType.by_value], CXType.by_value
		end
	end
end
