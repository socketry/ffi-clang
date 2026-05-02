# FFI::Clang

A light-weight wrapper for Ruby exposing [libclang](http://llvm.org/devmtg/2010-11/Gregor-libclang.pdf). This project is currently tested with Clang/libclang 18 and higher.

[![Development Status](https://github.com/socketry/ffi-clang/workflows/Test/badge.svg)](https://github.com/socketry/ffi-clang/actions?workflow=Test)

## Installation

Add this line to your application's Gemfile:

    gem 'ffi-clang'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ffi-clang

## Usage

Please see the [project documentation](https://socketry.github.io/ffi-clang/) for more details.

### Configuration

The following environment variables can be used to configure how ffi-clang finds libclang and its resources:

| Variable | Description |
| --- | --- |
| `LLVM_CONFIG` | Path to the `llvm-config` binary. Used to locate the libclang shared library and clang binary. |
| `LLVM_VERSION` | Target LLVM version (e.g., `17`). When set, disables auto-detection of `llvm-config`. |
| `LIBCLANG` | Direct path to the libclang shared library (e.g., `/usr/lib/libclang.so`). Overrides `llvm-config` based library discovery. |
| `LIBCLANG_RESOURCE_DIR` | Path to the clang resource directory containing compiler-intrinsic headers (`stddef.h`, `stdarg.h`, etc.). Use this if libclang cannot find its own headers. |

For example, to use a specific LLVM installation:

    LLVM_CONFIG=llvm-config-17 bundle exec bake test

## Releases

Please see the [project releases](https://socketry.github.io/ffi-clang/releases/index) for all releases.

### v0.16.0

  - Add <code class="language-ruby">FFI::Clang::Types::Type\#intrinsic\_type</code>, which strips references and follows pointer indirection until reaching a non-pointer type and then drops cv-qualifiers.
  - Add <code class="language-ruby">FFI::Clang::Types::Type\#reference?</code>, a one-liner predicate over `:type_lvalue_ref` and `:type_rvalue_ref`.
  - Add <code class="language-ruby">FFI::Clang::Cursor\#copyable?</code> and <code class="language-ruby">FFI::Clang::Types::Type\#copyable?</code>, predicates that return true when a class/struct has an accessible copy constructor (none deleted, private, or protected) and every base class is copyable.
  - Add <code class="language-ruby">FFI::Clang::Cursor\#copy\_assignable?</code> and <code class="language-ruby">FFI::Clang::Types::Type\#copy\_assignable?</code>, predicates that return true when a class/struct has an accessible copy assignment operator (none deleted, private, or protected) and every base class is copy-assignable.
  - <code class="language-ruby">FFI::Clang::Types::Type\#fully\_qualified\_name</code> now works on libclang versions earlier than 21 via a Ruby shim that composes existing libclang APIs (declaration, qualified\_name, template arguments, pointer/array/reference unwrapping).
  - Guard <code class="language-ruby">FFI::Clang::Types::Type\#unqualified\_type</code> against `:type_invalid` input.
  - Guard <code class="language-ruby">FFI::Clang::Types::Type\#non\_reference\_type</code> against `:type_invalid` input.

### v0.15.1

  - Use `-isystem` instead of `-I` for auto-discovered MSVC system include paths so that `in_system_header?` correctly identifies system headers.

### v0.15.0

  - [Platform Support](https://socketry.github.io/ffi-clang/releases/index#platform-support)
  - [Breaking Changes](https://socketry.github.io/ffi-clang/releases/index#breaking-changes)
  - [Bug Fixes](https://socketry.github.io/ffi-clang/releases/index#bug-fixes)
  - [New APIs](https://socketry.github.io/ffi-clang/releases/index#new-apis)

### v0.14.0

  - Helper method that returns a cursor's <code class="language-ruby">FFI::Clang::Cursor\#qualified\_display\_name</code>.
  - Add release notes and documentation tooling.
  - Modernize code and achieve 100% documentation coverage.
  - Update minimum Ruby version to 3.2.

### v0.13.0

  - Add support for `clang_Type_getNamedType`. (\#90)
  - Try clang v18 + add Ruby v3.4 to test matrix. (\#91)

### v0.12.0

  - Prefer `LIBCLANG` and `LLVM_CONFIG` overrides over Xcode. (\#88)

### v0.11.0

  - Restore `visit_children` method. Fixes \#82. (\#84)
  - Expose Clang's exception specification API. (\#87)
  - Support iterating over `Type::Function` args and expose `Lib.get_non_reference_type`. (\#85)
  - Fix qualified name. (\#83)
  - Update clang version. (\#86)

### v0.10.0

  - Expose libclang's anonymous methods. (\#79)
  - Use Enumerable. (\#80)
  - Split `FFI::Clang::Type` into a number of more cohesive subclasses inheriting from `FFI::Clang::Types::Type`. (\#81)

### v0.9.0

  - Remove duplicate mapping of `clang_getEnumDeclIntegerType`. (\#67)
  - Update bitmask options based on enums to always be an array of symbols. (\#69)
  - Add support for `parse_translation_unit2` API. (\#70)
  - Cursor improvements, Type improvements, Printing support. (\#72)
  - Fix finalizer exception in `FFI::Clang::CodeCompletion::Results`. (\#74)
  - Fix Clang 16 compatibility. (\#76)
  - Cursor location methods. (\#78)

### v0.8.0

  - Modernize gem. (\#58)
  - Test on clang 5.0+. (\#59)
  - Fix `CXCursor_TranslationUnit` enum value to 350. (\#61)
  - Add `Cursor#hash` and `Cursor#eql?`. (\#62)
  - Set `cursor_translation_unit` enum value based on the Clang version. (\#64)
  - Add various C++ introspection methods. (\#66)

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Running Tests

To run the test suite:

``` shell
bundle exec sus
```

### Making Releases

To make a new release:

``` shell
bundle exec bake gem:release:patch # or minor or major
```

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
