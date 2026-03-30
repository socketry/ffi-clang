# frozen_string_literal: true

require "spec_helper"

RSpec.describe FFI::Clang::LinuxArgs do
	subject(:args) {described_class.new}
	
	describe "#find_libclang_paths" do
		it "tries versioned sonames before the generic fallback" do
			allow(args).to receive(:llvm_library_dir).and_return("/opt/llvm/lib")
			allow(args).to receive(:versions).and_return(22.downto(21))
			
			expect(args.send(:find_libclang_paths)).to eq([
				"/opt/llvm/lib/libclang.so.22.5",
				"/opt/llvm/lib/libclang.so.22.4",
				"/opt/llvm/lib/libclang.so.22.3",
				"/opt/llvm/lib/libclang.so.22.2",
				"/opt/llvm/lib/libclang.so.22.1",
				"/opt/llvm/lib/libclang.so.22.0",
				"/opt/llvm/lib/libclang.so.21.5",
				"/opt/llvm/lib/libclang.so.21.4",
				"/opt/llvm/lib/libclang.so.21.3",
				"/opt/llvm/lib/libclang.so.21.2",
				"/opt/llvm/lib/libclang.so.21.1",
				"/opt/llvm/lib/libclang.so.21.0",
				"/opt/llvm/lib/libclang.so.22",
				"/opt/llvm/lib/libclang.so.21",
				"/opt/llvm/lib/libclang.so"
			])
		end
	end
end
