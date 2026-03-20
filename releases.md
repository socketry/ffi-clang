# Releases

## v0.15.0

### Platform Support

  - Add macOS support using Xcode's built-in clang/libclang.
  - Add Windows MSVC (mswin) support using Visual Studio's bundled LLVM/Clang, including system include path discovery via `vcvarsall.bat` and `clang-cl`.
  - Improve Windows MinGW support.
  - Work around LLVM bug [#154361](https://github.com/llvm/llvm-project/pull/171465) where `FreeLibrary` on `libclang.dll` crashes during process exit due to dangling Fiber Local Storage callbacks (fixed in LLVM 22.1.0).

### Bug Fixes

  - Fix {ruby FFI::Clang::TranslationUnit\#default\_reparse\_options} calling wrong libclang function.
  - Fix `CXIndexOptions` struct layout to match libclang's bitfield packing (24 bytes on Linux/macOS, 32 bytes on Windows).
  - Fix {ruby FFI::Clang::TranslationUnit\#save} to use libclang default save options instead of hardcoded zero. Accept optional save option flags.
  - `Enumerable#each` methods on {ruby FFI::Clang::Tokens}, {ruby FFI::Clang::Comment}, {ruby FFI::Clang::CodeCompletion::Results}, and {ruby FFI::Clang::CompilationDatabase::CompileCommands} now return an `Enumerator` when called without a block.
  - Fix the `clang_getNullRange` binding to return `CXSourceRange` instead of `CXSourceLocation`.
  - Ensure `require "ffi/clang"` loads `FFI::Clang::VERSION` without requiring `ffi/clang/version` separately.
  - Update `CXCursorKind` to match current clang headers, including newer C++ expression kinds, OpenMP/OpenACC statement kinds, and `ConceptDecl`.
  - Update `CXTypeKind` to match current clang headers, including newer builtin and HLSL type kinds.
  - Update `CXCallingConv` to match current clang headers, correcting `X86RegCall` and adding `RISCVVLSCall_*` calling conventions.
  - Update `CXCodeComplete_Flags`, `CXCompletionContext`, `CXCommentInlineCommandRenderKind`, `CXEvalResultKind`, `CXAvailabilityKind`, and `CXPrintingPolicyProperty` to match current clang headers, including newer completion flags and contexts and corrected enum symbol names.
  - Fix the signedness of libclang predicate bindings for dynamic-call, variable-storage, include-guard, and source-location equality checks to match current headers.
  - Fix {ruby FFI::Clang::Cursor\#overriddens} use-after-free: extract `OverriddenCursors` class that owns the buffer via AutoPointer and disposes it on GC instead of immediately after iteration.
  - Fix {ruby FFI::Clang::Diagnostic\#children} double-free on repeated calls: extract `DiagnosticSet` class that caches child diagnostics so each is disposed exactly once.
  - Fix {ruby FFI::Clang::Cursor\#ancestors\_by\_kind} to walk the full semantic parent chain instead of only checking the immediate parent.
  - Remove bogus `offset` attr\_reader from {ruby FFI::Clang::PresumedLocation} — `clang_getPresumedLocation` does not return an offset.

### New APIs

  - **Cursor**: `binary_operator_kind` (clang 17+), `brief_comment_text`, `evaluate`, `function_inlined?`, `has_attrs?`, `has_external_storage?`, `has_global_storage?`, `inline_namespace?`, `invalid_declaration?`, `macro_builtin?`, `macro_function_like?`, `mangling`, `num_template_arguments`, `offset_of_field`, `spelling_name_range`, `storage_class`, `template_argument_kind`, `template_argument_type`, `template_argument_unsigned_value`, `template_argument_value`, `tls_kind`, `unary_operator_kind` (clang 17+), `visibility`.
  - **Cursor class methods**: `binary_operator_kind_spelling` (clang 17+), `unary_operator_kind_spelling` (clang 17+).
  - **CursorSet**: New class with `include?` and `insert` for fast cursor membership checks.
  - **Diagnostic**: `category`, `category_id`, `children`, `disable_option`, `enable_option`.
  - **Diagnostic class methods**: `default_display_opts`.
  - **DiagnosticSet**: New enumerable class returned by `Diagnostic#children`.
  - **EvalResult**: New class for compile-time constant evaluation — `as_double`, `as_int`, `as_long_long`, `as_str`, `as_unsigned`, `kind`, `unsigned_int?`.
  - **File**: `==`, `contents`, `find_includes`, `real_path_name`.
  - **Index**: `create_translation_unit2`, `create_translation_unit_from_source_file`, `create_with_options` (clang 17+) with `CXChoice` enum and `CXIndexOptions` struct, `parse_translation_unit_with_invocation`.
  - **Token**: `from_location`.
  - **TranslationUnit**: `suspend`, `target_pointer_width`, `target_triple`.
  - **Type**: `address_space`, `fully_qualified_name` (clang 21+), `modified_type`, `nullability`, `pretty_printed` (clang 21+), `transparent_tag_typedef?`, `typedef_name`, `unqualified_type` (clang 16+), `value_type`, `visit_fields`.

## v0.14.0 (2025-10-24)

  - Helper method that returns a cursor's {ruby FFI::Clang::Cursor\#qualified\_display\_name}.
  - Add release notes and documentation tooling.
  - Modernize code and achieve 100% documentation coverage.
  - Update minimum Ruby version to 3.2.

## v0.13.0 (2025-02-16)

  - Add support for `clang_Type_getNamedType`. (#90)
  - Try clang v18 + add Ruby v3.4 to test matrix. (#91)

## v0.12.0 (2024-11-27)

  - Prefer `LIBCLANG` and `LLVM_CONFIG` overrides over Xcode. (#88)

## v0.11.0 (2024-11-13)

  - Restore `visit_children` method. Fixes #82. (#84)
  - Expose Clang's exception specification API. (#87)
  - Support iterating over `Type::Function` args and expose `Lib.get_non_reference_type`. (#85)
  - Fix qualified name. (#83)
  - Update clang version. (#86)

## v0.10.0 (2024-06-14)

  - Expose libclang's anonymous methods. (#79)
  - Use Enumerable. (#80)
  - Split `FFI::Clang::Type` into a number of more cohesive subclasses inheriting from `FFI::Clang::Types::Type`. (#81)

## v0.9.0 (2024-04-07)

  - Remove duplicate mapping of `clang_getEnumDeclIntegerType`. (#67)
  - Update bitmask options based on enums to always be an array of symbols. (#69)
  - Add support for `parse_translation_unit2` API. (#70)
  - Cursor improvements, Type improvements, Printing support. (#72)
  - Fix finalizer exception in `FFI::Clang::CodeCompletion::Results`. (#74)
  - Fix Clang 16 compatibility. (#76)
  - Cursor location methods. (#78)

## v0.8.0 (2023-05-01)

  - Modernize gem. (#58)
  - Test on clang 5.0+. (#59)
  - Fix `CXCursor_TranslationUnit` enum value to 350. (#61)
  - Add `Cursor#hash` and `Cursor#eql?`. (#62)
  - Set `cursor_translation_unit` enum value based on the Clang version. (#64)
  - Add various C++ introspection methods. (#66)

## v0.7.0 (2022-11-15)

  - Fix incorrect return type of `clang_getTranslationUnitSpelling`.
  - Fix `compilation_database_spec`.
  - Fix libclang lookup for Xcode.
  - Fix warning on class re-definition.
  - Update cursor kinds.
  - Find `libclang.dll` under Windows.
  - Allow retrieval of list of references from a Cursor.
  - Implement libclang `findReferencesInFile` functionality.
  - Allow `TranslationUnit#file` to return the main file.

## v0.6.0 (2019-03-24)

  - Add missing translation unit parse flags.

## v0.5.0 (2017-03-15)

  - Modernize code base, Clang v3.4+ only.
  - Get text from `SourceRange`.
  - Integrate `find_*` into `Cursor`.
  - Test case for method calls inside classes. (#36)

## v0.3.0 (2016-02-05)

  - Find and use `llvm-config`. (#38)
  - Recognize Xcode 7.
  - Add functions needed by RoboVM's bro-gen script.

## v0.2.1 (2014-06-23)

  - Add inclusions support. (#32)
  - Update unit tests for RSpec 3.
  - Add `CompilationDatabase`. (#27)
  - Only use `.dylib` on Darwin. (#29)

## v0.2.0 (2014-02-03)

  - Add clang version string APIs.
  - Add cursor functions (except Objective-C). (#9)
  - Add type kind and cursor kind enums. (#8)
  - Add `TranslationUnit` reference to `Cursor` and `Type`. (#11)
  - Multi-version libclang testing via Travis. (#10)

## v0.1.3 (2013-08-08)

  - Add `CXType` support. (#5)
  - Correct camelCase `displayName` to `display_name`.

## v0.1.2 (2013-07-30)

  - Initial support for source comments. (#4)
  - Use different classes for comment types.

## v0.1.1 (2013-07-28)

  - Support unsaved files. (#3)
  - Add `Cursor` visitor function taking a block.
  - Add null cursor and `clang_is*` functions.
  - Add `SourceLocation` from diagnostic.

## v0.1.0 (2013-06-13)

  - Initial release.
  - FFI bindings for libclang Index, TranslationUnit, Diagnostic, SourceLocation.
