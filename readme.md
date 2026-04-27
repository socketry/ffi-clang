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
