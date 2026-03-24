# frozen_string_literal: true

require_relative "lib/ffi/clang/version"

Gem::Specification.new do |spec|
	spec.name = "ffi-clang"
	spec.version = FFI::Clang::VERSION
	
	spec.summary = "Ruby FFI bindings for libclang C interface."
	spec.authors = ["Samuel Williams", "Charlie Savage", "Masahiro Sano", "Carlos Martín Nieto", "Jari Bakken", "Takeshi Watanabe", "Garry Marshall", "George Pimm", "Zete Lui", "Greg Hazel", "Michael Metivier", "Dave Wilkinson", "Hayden Purdy", "Mike Dalessio", "Motonori Iwamuro", "Niklas Therning", "Cameron Dutro", "Dominic Sisnero", "Hal Brodigan", "msepga"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/ioquatix/ffi-clang"
	
	spec.metadata = {
		"documentation_uri" => "https://ioquatix.github.io/ffi-clang/",
		"funding_uri" => "https://github.com/sponsors/ioquatix/",
		"source_code_uri" => "https://github.com/ioquatix/ffi-clang.git",
	}
	
	spec.files = Dir.glob(["{ext,lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.2"
	
	spec.add_dependency "ffi"
end
