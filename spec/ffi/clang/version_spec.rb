# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.

describe FFI::Clang.clang_version_string do
	it "returns a version string for showing to user" do
		expect(subject).to be_kind_of(String)
		expect(subject).to match(/Apple LLVM version \d+\.\d+\.\d+|clang version \d+\.\d+/)
	end
end

describe FFI::Clang do
	it "defines VERSION from the main entrypoint" do
		expect(described_class::VERSION).to be_kind_of(String)
	end
end
