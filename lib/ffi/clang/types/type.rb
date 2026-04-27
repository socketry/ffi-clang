# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014, by Niklas Therning.
# Copyright, 2024-2026, by Charlie Savage.

module FFI
	module Clang
		module Types
			# Represents a type in the C/C++ type system.
			# This class wraps libclang's type representation and provides methods to query type properties.
			class Type
				# @attribute [r] type
				# 	@returns [FFI::Struct] The underlying CXType structure.
				# @attribute [r] translation_unit
				# 	@returns [TranslationUnit] The translation unit this type belongs to.
				attr_reader :type, :translation_unit
				
				# Create a type instance of the appropriate subclass based on the type kind.
				# @parameter cxtype [FFI::Struct] The low-level CXType structure.
				# @parameter translation_unit [TranslationUnit] The translation unit this type belongs to.
				# @returns [Type] A Type instance of the appropriate subclass.
				def self.create(cxtype, translation_unit)
					case cxtype[:kind]
					when :type_pointer, :type_block_pointer, :type_obj_c_object_pointer, :type_member_pointer
						Pointer.new(cxtype, translation_unit)
					when :type_constant_array, :type_incomplete_array, :type_variable_array, :type_dependent_sized_array
						Array.new(cxtype, translation_unit)
					when :type_vector
						Vector.new(cxtype, translation_unit)
					when :type_function_no_proto, :type_function_proto
						Function.new(cxtype, translation_unit)
					when :type_elaborated
						Elaborated.new(cxtype, translation_unit)
					when :type_typedef
						TypeDef.new(cxtype, translation_unit)
					when :type_record
						Record.new(cxtype, translation_unit)
					else
						Type.new(cxtype, translation_unit)
					end
				end
				
				# Create a new type instance.
				# @parameter type [FFI::Struct] The low-level CXType structure.
				# @parameter translation_unit [TranslationUnit] The translation unit this type belongs to.
				def initialize(type, translation_unit)
					@type = type
					@translation_unit = translation_unit
				end
				
				# Get the kind of this type.
				# @returns [Symbol] The type kind (e.g., :type_int, :type_pointer).
				def kind
					@type[:kind]
				end
				
				# Get the spelling of this type's kind.
				# @returns [String] A human-readable string describing the type kind.
				def kind_spelling
					Lib.extract_string Lib.get_type_kind_spelling @type[:kind]
				end
				
				# Get the spelling of this type.
				# @returns [String] The type as it would appear in source code.
				def spelling
					Lib.extract_string Lib.get_type_spelling(@type)
				end
				
				# Get the canonical type.
				# @returns [Type] The canonical (unqualified, unaliased) form of this type.
				def canonical
					Type.create Lib.get_canonical_type(@type), @translation_unit
				end
				
				# Check if this is a Plain Old Data (POD) type.
				# @returns [Boolean] True if this is a POD type.
				def pod?
					Lib.is_pod_type(@type) != 0
				end
				
				# Check if this type is const-qualified.
				# @returns [Boolean] True if the type has a const qualifier.
				def const_qualified?
					Lib.is_const_qualified_type(@type) != 0
				end
				
				# Check if this type is volatile-qualified.
				# @returns [Boolean] True if the type has a volatile qualifier.
				def volatile_qualified?
					Lib.is_volatile_qualified_type(@type) != 0
				end
				
				# Check if this type is restrict-qualified.
				# @returns [Boolean] True if the type has a restrict qualifier.
				def restrict_qualified?
					Lib.is_restrict_qualified_type(@type) != 0
				end
				
				# Get the alignment of this type in bytes.
				# @returns [Integer] The alignment requirement in bytes.
				def alignof
					Lib.type_get_align_of(@type)
				end
				
				# Get the size of this type in bytes.
				# @returns [Integer] The size in bytes, or -1 if the size cannot be determined.
				def sizeof
					Lib.type_get_size_of(@type)
				end
				
				# Get the ref-qualifier for this type (C++ only).
				# @returns [Symbol] The ref-qualifier (:ref_qualifier_none, :ref_qualifier_lvalue, :ref_qualifier_rvalue).
				def ref_qualifier
					Lib.type_get_cxx_ref_qualifier(@type)
				end
				
				# Get the cursor for the declaration of this type.
				# @returns [Cursor] The cursor representing the type declaration.
				def declaration
					Cursor.new Lib.get_type_declaration(@type), @translation_unit
				end
				
				# Get the type with all qualifiers (const, volatile, restrict) removed.
				# @returns [Type] The unqualified type.
				#
				# Guards against :type_invalid input: clang_getUnqualifiedType has
				# no null check on the underlying QualType (unlike its siblings
				# clang_getNonReferenceType / clang_getCanonicalType / etc.) and
				# segfaults on invalid types. Returning self preserves the
				# invalid kind without entering libclang.
				def unqualified_type
					return self if self.kind == :type_invalid
					Type.create Lib.get_unqualified_type(@type), @translation_unit
				end
				
				# True if this type is an lvalue or rvalue reference.
				# @returns [Boolean] Whether this type is `T &` or `T &&`.
				def reference?
					self.kind == :type_lvalue_ref || self.kind == :type_rvalue_ref
				end
				
				# Get the non-reference type.
				# For reference types, returns the type that is being referenced.
				# @returns [Type] The non-reference type.
				#
				# Guards against :type_invalid input: clang_getNonReferenceType
				# dereferences the underlying QualType without a null check and
				# segfaults on invalid types. Returning self preserves the
				# invalid kind without entering libclang.
				def non_reference_type
					return self if self.kind == :type_invalid
					Type.create Lib.get_non_reference_type(@type), @translation_unit
				end
				
				# Get the intrinsic type — strip the reference, follow pointer
				# indirection until reaching a non-pointer type, then drop
				# cv-qualifiers. Named after Rice's `intrinsic_type` metafunction
				# of the same shape. Useful when asking "what does this type
				# ultimately denote?" for skip-list and bindability checks.
				#
				# Examples:
				# * `T &`        becomes `T`
				# * `T *`        becomes `T`
				# * `T **&`      becomes `T`
				# * `const T &`  becomes `T`
				#
				# @returns [Type] The intrinsic (innermost, unqualified) type.
				def intrinsic_type
					type = self.non_reference_type
					while type.kind == :type_pointer
						type = type.pointee
					end
					type.unqualified_type
				end
				
				# Check if this type's declaration (after reference stripping)
				# has an accessible copy constructor and copyable bases.
				# Returns true for non-class types (fundamentals, pointers,
				# enums) and for types whose declaration is unavailable
				# (:cursor_no_decl_found).
				#
				# @returns [Boolean] True if instances of this type can be copied.
				def copyable?
					self.non_reference_type.declaration.copyable?
				end
				
				# Check if this type's declaration (after reference stripping)
				# has an accessible copy assignment operator and copy-assignable
				# bases. Returns true for non-class types (fundamentals, pointers,
				# enums) and for types whose declaration is unavailable
				# (:cursor_no_decl_found).
				#
				# @returns [Boolean] True if instances of this type can be copy-assigned.
				def copy_assignable?
					self.non_reference_type.declaration.copy_assignable?
				end
				
				# Get the type of a template argument at the given index.
				# For template specializations (e.g., `std::vector<int>`), this returns the type of
				# the template argument at the specified position.
				# @parameter index [Integer] The zero-based index of the template argument.
				# @returns [Type] The type of the template argument at the given index.
				def template_argument_type(index)
					Type.create Lib.get_template_argument_as_type(@type, index), @translation_unit
				end
				
				# Get the number of template arguments for this type.
				# For template specializations (e.g., `std::map<int, std::string>`), this returns the
				# number of template arguments. Returns -1 if this is not a template specialization.
				# @returns [Integer] The number of template arguments, or -1 if not a template type.
				def num_template_arguments
					Lib.get_num_template_arguments(@type)
				end
				
				# Get the address space of this type.
				# @returns [Integer] The address space number.
				def address_space
					Lib.get_address_space(@type)
				end
				
				# Get the typedef name of this type.
				# @returns [String] The typedef name.
				def typedef_name
					Lib.extract_string Lib.get_typedef_name(@type)
				end
				
				# Check if this typedef is transparent.
				# @returns [Boolean] True if this is a transparent tag typedef.
				def transparent_tag_typedef?
					Lib.type_is_transparent_tag_typedef(@type) != 0
				end
				
				# Get the nullability kind of a pointer type.
				# @returns [Integer] The nullability kind.
				def nullability
					Lib.type_get_nullability(@type)
				end
				
				# Get the type modified by an attributed type.
				# @returns [Type] The modified type.
				def modified_type
					Type.create Lib.type_get_modified_type(@type), @translation_unit
				end
				
				# Get the value type of an atomic type.
				# @returns [Type] The value type.
				def value_type
					Type.create Lib.type_get_value_type(@type), @translation_unit
				end
				
				# Pretty-print this type using a printing policy.
				# @parameter policy [PrintingPolicy] The printing policy to use.
				# @returns [String] The pretty-printed type string.
				def pretty_printed(policy)
					Lib.extract_string Lib.get_type_pretty_printed(@type, policy)
				end
				
				# Get the fully qualified name of this type.
				#
				# On libclang 21+ this dispatches to clang_getFullyQualifiedName.
				# On earlier libclang versions it falls back to a Ruby shim that
				# composes existing libclang APIs (declaration, qualified_name,
				# template arguments, pointer/array/reference unwrapping, etc.).
				#
				# Known shim limitation: STL container typedefs that depend on
				# default template arguments (e.g., `std::vector<T>::iterator`)
				# don't expand the defaults. Output is valid C++ and matches
				# the native result for non-STL types.
				#
				# @parameter policy [PrintingPolicy] The printing policy to use. Ignored by the shim.
				# @parameter with_global_ns_prefix [Boolean] Whether to prepend "::".
				# @returns [String] The fully qualified type name.
				def fully_qualified_name(policy = nil, with_global_ns_prefix: false)
					if Lib.respond_to?(:get_fully_qualified_name)
						Lib.extract_string Lib.get_fully_qualified_name(@type, policy, with_global_ns_prefix ? 1 : 0)
					else
						result = fqn_impl(policy)
						with_global_ns_prefix ? "::#{result}" : result
					end
				end
				
				# Shim implementation of fully_qualified_name. Recursively walks the
				# type tree, dispatching by kind. Public so it can be invoked across
				# Type subclass boundaries during recursion.
				# @parameter policy [PrintingPolicy] Threaded for native API parity; ignored.
				# @returns [String] The fully qualified type spelling.
				def fqn_impl(policy)
					case self.kind
					when :type_lvalue_ref
						"#{self.non_reference_type.fqn_impl(policy)} &"
					when :type_rvalue_ref
						"#{self.non_reference_type.fqn_impl(policy)} &&"
					when :type_pointer
						fqn_pointer(policy)
					when :type_constant_array
						"#{self.element_type.fqn_impl(policy)}[#{self.size}]"
					when :type_incomplete_array
						"#{self.element_type.fqn_impl(policy)}[]"
					when :type_elaborated
						fqn_elaborated(policy)
					when :type_record
						fqn_record
					else
						self.spelling
					end
				end
				
				# Spell a pointer type and its qualifier chain. Function pointers
				# get a single rendering with parameter list; data pointers walk
				# the chain collecting `*`/`*const` parts and qualify the leaf
				# child once. Output matches native fqn: `int **`, `const char *const`, etc.
				# @parameter policy [PrintingPolicy] Threaded to recursive fqn_impl calls.
				# @returns [String] The fully qualified pointer type spelling.
				def fqn_pointer(policy)
					pointee = self.pointee
					
					if [:type_function_proto, :type_function_no_proto].include?(pointee.kind)
						ptr_const = self.const_qualified? ? " const" : ""
						result_type = pointee.result_type.fqn_impl(policy)
						arg_types = pointee.arg_types.map{|arg_type| arg_type.fqn_impl(policy)}.join(", ")
						return "#{result_type} (*#{ptr_const})(#{arg_types})"
					end
					
					parts = []
					current = self
					while current.kind == :type_pointer
						inner = current.pointee
						break if [:type_function_proto, :type_function_no_proto].include?(inner.kind)
						
						parts << (current.const_qualified? ? "*const" : "*")
						current = inner
					end
					
					"#{current.fqn_impl(policy)} #{parts.reverse.join}"
				end
				
				# Spell an elaborated type (typedef / type alias / enum / class)
				# preserving the alias name where appropriate and qualifying
				# template arguments recursively.
				# @parameter policy [PrintingPolicy] Threaded to recursive calls.
				# @returns [String] The fully qualified elaborated type spelling.
				def fqn_elaborated(policy)
					decl = self.declaration
					const_prefix = self.const_qualified? ? "const " : ""
					
					case decl.kind
					when :cursor_typedef_decl, :cursor_type_alias_decl
						# Preserve the typedef/alias name and qualify with namespace.
						spelling = self.unqualified_type.spelling
						qualified = decl.qualified_name
						
						if spelling.include?("::")
							# Already partially qualified. For nested typedefs in
							# template classes (e.g., std::vector<Pixel>::iterator),
							# qualify template args using the parent type's fqn.
							parent = decl.semantic_parent
							if parent.kind == :cursor_class_decl || parent.kind == :cursor_struct
								parent_type = parent.type
								parent_fqn = parent_type.fqn_impl(policy)
								member_name = decl.spelling
								"#{const_prefix}#{parent_fqn}::#{member_name}"
							else
								"#{const_prefix}#{spelling}"
							end
						elsif qualified
							"#{const_prefix}#{qualified}"
						else
							"#{const_prefix}#{spelling}"
						end
						
					when :cursor_enum_decl
						"#{const_prefix}#{decl.qualified_name}"
						
					else
						# Alias-template detection: e.g. `AliasOptional<int>` -> `Optional<int>`.
						# The elaborated spelling preserves the alias; fqn_record
						# would resolve to the underlying type. Use spelling when
						# it's already qualified.
						unqual = self.unqualified_type.spelling
						if unqual.include?("::") && decl.spelling != unqual.sub(/<.*/, "").split("::").last
							"#{const_prefix}#{unqual}"
						else
							base = fqn_record
							if self.const_qualified? && !base.start_with?("const ")
								"const #{base}"
							else
								base
							end
						end
					end
				end
				
				# Spell a record type (class/struct) using its declaration's
				# type spelling, which suppresses inline namespaces and includes
				# template args. Falls back to qualified_name + spelling args
				# for dependent types.
				# @returns [String] The fully qualified record type spelling.
				def fqn_record
					decl = self.declaration
					return self.spelling if decl.kind == :cursor_no_decl_found
					
					const_prefix = self.const_qualified? ? "const " : ""
					
					# decl.type.spelling gives the right qualification (no inline
					# ns, with template args).
					decl_spelling = decl.type.spelling
					if decl_spelling && !decl_spelling.empty? && decl_spelling.include?("::")
						# For concrete template types, recursively qualify args.
						n = self.num_template_arguments
						if n > 0
							base = decl_spelling.sub(/<.*/, "")
							template_args = fqn_template_args(nil)
							"#{const_prefix}#{base}#{template_args}"
						else
							"#{const_prefix}#{decl_spelling}"
						end
					else
						# Fallback for types where decl.type.spelling is unqualified.
						qualified = decl.qualified_name
						bare_spelling = self.unqualified_type.spelling
						template_args = bare_spelling.include?("<") ? bare_spelling[/<.*/] : ""
						"#{const_prefix}#{qualified}#{template_args}"
					end
				end
				
				# Build the qualified template argument list by recursing into
				# each type argument. Non-type template parameters (e.g.
				# integral values) are recovered from the type's spelling.
				# @parameter policy [PrintingPolicy] Threaded to recursive calls.
				# @returns [String] The bracketed argument list, including angle brackets, or empty.
				def fqn_template_args(policy)
					n = self.num_template_arguments
					return "" unless n > 0
					
					# Extract original args from spelling for non-type template params.
					spelling_args = parse_template_args_from_spelling
					
					args = (0...n).map do |i|
						arg_type = self.template_argument_type(i)
						if arg_type.kind == :type_invalid
							# Non-type template arg (e.g., int N=3) — use from spelling.
							spelling_args ? spelling_args[i] : nil
						else
							arg_type.fqn_impl(policy)
						end
					end.compact
					
					return "" if args.empty?
					"<#{args.join(", ")}>"
				end
				
				# Parse template arguments from the type's unqualified spelling,
				# respecting nested angle brackets. Used to recover non-type
				# template arguments that libclang surfaces only as text.
				# @returns [Array(String) | nil] The argument substrings, or nil if no `<` was found.
				def parse_template_args_from_spelling
					bare = self.unqualified_type.spelling
					start = bare.index("<")
					return nil unless start
					
					depth = 0
					args = []
					current = +""
					bare[start + 1..].each_char do |c|
						case c
						when "<"
							depth += 1
							current << c
						when ">"
							if depth == 0
								args << current.strip unless current.strip.empty?
								break
							else
								depth -= 1
								current << c
							end
						when ","
							if depth == 0
								args << current.strip
								current = +""
							else
								current << c
							end
						else
							current << c
						end
					end
					args
				end
				
				# Visit all base classes of a C++ record type.
				# @yields {|cursor| ...} Each base class cursor.
				# 	@parameter cursor [Cursor] The base class cursor.
				# @returns [Enumerator] If no block is given.
				# @returns [self] The receiver.
				def visit_base_classes(&block)
					return to_enum(__method__) unless block_given?
					
					visit_type(:visit_cxx_base_classes, &block)
				end
				
				# Visit all methods of a C++ record type.
				# @yields {|cursor| ...} Each method cursor.
				# 	@parameter cursor [Cursor] The method cursor.
				# @returns [Enumerator] If no block is given.
				# @returns [self] The receiver.
				def visit_methods(&block)
					return to_enum(__method__) unless block_given?
					
					visit_type(:visit_cxx_methods, &block)
				end
				
				# Visit all fields of a record type.
				# @yields {|cursor| ...} Each field cursor.
				# 	@parameter cursor [Cursor] The field cursor.
				# @returns [Enumerator] If no block is given.
				# @returns [self] The receiver.
				def visit_fields(&block)
					return to_enum(__method__) unless block_given?
					
					visit_type(:type_visit_fields, &block)
				end
				
				private
				
				# Visit a type using a libclang visitor function.
				# The C API documents a non-zero return on early termination,
				# but in practice (libclang 21.1.7) it returns 1 in both cases,
				# so ffi-clang treats these as side-effect iterators and returns self.
				# @parameter function_name [Symbol] The Lib function to invoke.
				# @yields {|cursor| ...} Each visited cursor.
				# @returns [self] The receiver.
				def visit_type(function_name, &block)
					callback = Proc.new do |cursor, _data|
						result = block.call(Cursor.new(cursor, @translation_unit))
						result == :break ? 0 : 1
					end
					Lib.send(function_name, @type, callback, nil)
					self
				end
				
				public
				
				# Compare this type with another for equality.
				# @parameter other [Type] The other type to compare.
				# @returns [Boolean] True if the types are equal.
				def ==(other)
					Lib.equal_types(@type, other.type) != 0
				end
				
				# Get a string representation of this type.
				# @returns [String] A string describing this type.
				def to_s
					"#{self.class.name} <#{self.kind}: #{self.spelling}>"
				end
			end
		end
	end
end
