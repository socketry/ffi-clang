# frozen_string_literal: true

require "spec_helper"

RSpec.describe FFI::Clang::Args do
	describe "#llvm_library_dir" do
		it "runs llvm-config from PATH" do
			original_llvm_config = ENV["LLVM_CONFIG"]
			original_llvm_version = ENV["LLVM_VERSION"]

			ENV.delete("LLVM_CONFIG")
			ENV.delete("LLVM_VERSION")

			args = described_class.new
			status = double(success?: true)

			expect(Open3).to receive(:capture3)
				.with("llvm-config", "--libdir")
				.and_return(["/opt/llvm/lib\n", "", status])

			expect(args.send(:llvm_library_dir)).to eq("/opt/llvm/lib")
		ensure
			ENV["LLVM_CONFIG"] = original_llvm_config

			if original_llvm_version
				ENV["LLVM_VERSION"] = original_llvm_version
			else
				ENV.delete("LLVM_VERSION")
			end
		end
	end
end
