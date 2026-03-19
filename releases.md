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

### New APIs

  - **Cursor**: `evaluate`, `invalid_declaration?`, `has_attrs?`, `visibility`, `storage_class`, `tls_kind`, `function_inlined?`, `macro_function_like?`, `macro_builtin?`, `has_global_storage?`, `has_external_storage?`, `inline_namespace?`, `mangling`, `offset_of_field`, `brief_comment_text`, `spelling_name_range`, `binary_operator_kind` (clang 17+), `unary_operator_kind` (clang 17+).
  - **Cursor class methods**: `binary_operator_kind_spelling` (clang 17+), `unary_operator_kind_spelling` (clang 17+).
  - **Type**: `unqualified_type` (clang 16+), `address_space`, `typedef_name`, `transparent_tag_typedef?`, `nullability`, `modified_type`, `value_type`, `visit_fields`, `pretty_printed` (clang 21+), `fully_qualified_name` (clang 21+).
  - **TranslationUnit**: `target_triple`, `target_pointer_width`, `suspend`.
  - **Index**: `create_with_options` (clang 17+) with `CXChoice` enum and `CXIndexOptions` struct.
  - **File**: `real_path_name`, `==`.
  - **EvalResult**: New class for compile-time constant evaluation — `kind`, `as_int`, `as_long_long`, `unsigned_int?`, `as_unsigned`, `as_double`, `as_str`.

## v0.14.0

  - Helper method that returns a cursor's {ruby FFI::Clang::Cursor\#qualified\_display\_name}.
