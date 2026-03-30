# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2010, by Jari Bakken.
# Copyright, 2012, by Hal Brodigan.
# Copyright, 2013-2025, by Samuel Williams.
# Copyright, 2013, by Carlos Martín Nieto.
# Copyright, 2013, by Takeshi Watanabe.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2024-2026, by Charlie Savage.

if ENV["COVERAGE"]
	require "simplecov"
	SimpleCov.start do
		add_filter "/spec/"
		add_filter "/vendor/"
	end
end

require "fileutils"
require_relative "../lib/ffi/clang"

include FFI::Clang

TMP_DIR = File.expand_path("tmp", __dir__)

module ClangSpecHelper
	def fixture_path(path)
		File.join File.expand_path("ffi/clang/fixtures", __dir__), path
	end
	
	def find_all_by_kind(cursor, kind)
		cursor.find_by_kind(true, kind).to_a
	end
	
	def find_by_kind(cursor, kind)
		cursor.find_by_kind(true, kind).first
	end
	
	def find_matching(cursor, &term)
		child, _ = cursor.find(&term)
		child
	end
end

RSpec.configure do |config|
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"
	
	config.include ClangSpecHelper
end
