# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2014, by Masahiro Sano.
# Copyright, 2014-2025, by Samuel Williams.
# Copyright, 2020, by Zete Lui.
# Copyright, 2026, by Charlie Savage.

describe CompilationDatabase do
	let(:dirpath) {fixture_path("")}
	let(:cdb) {CompilationDatabase.new(dirpath)}
	let(:file) {"/home/xxxxx/src/llvm-trunk/lib/Support/APFloat.cpp"}
	
	it "can be created" do
		expect(cdb).to be_kind_of(CompilationDatabase)
	end
	
	it "raises DatabaseLoadError if cannot be created" do
		expect{CompilationDatabase.new("/not/exist/directory")}.to raise_error FFI::Clang::CompilationDatabase::DatabaseLoadError
	end
	
	it "calls compilation_database_dispose on GC" do
		cdb.autorelease = false
		# expect(Lib).to receive(:compilation_database_dispose).with(cdb).once
		expect{cdb.free}.not_to raise_error
	end
	
	describe "#compile_commands" do
		let(:not_found_file) {"/home/xxxxx/not_found_file_path"}
		
		it "returns compile commands used for a file", skip: (FFI::Clang.platform == :mingw || FFI::Clang.platform == :mswin) do
			expect(cdb.compile_commands(file)).to be_kind_of(CompilationDatabase::CompileCommands)
			expect(cdb.compile_commands(file).size).to eq(1)
		end
		
		it "returns compile commands if the specified file is not found", skip: (FFI::Clang.platform == :mingw || FFI::Clang.platform == :mswin) do
			expect(cdb.compile_commands(not_found_file)).to be_kind_of(CompilationDatabase::CompileCommands)
			if FFI::Clang.clang_version_string[/\d+/].to_i >= 10
				expect(cdb.compile_commands(not_found_file).size).to eq(1)
			else
				expect(cdb.compile_commands(not_found_file).size).to eq(0)
			end
		end
	end
	
	describe "#all_compile_commands" do
		it "returns all compile commands in the database" do
			expect(cdb.all_compile_commands).to be_kind_of(CompilationDatabase::CompileCommands)
			expect(cdb.all_compile_commands.size).to eq(3)
		end
	end
	
	describe CompilationDatabase::CompileCommands do
		let(:commands) {cdb.all_compile_commands}
		
		it "calls compile_commands_dispose on GC" do
			commands.autorelease = false
			# expect(Lib).to receive(:compile_commands_dispose).with(commands).once
			expect{commands.free}.not_to raise_error
		end
		
		describe "#size" do
			it "returns the number of CompileCommand" do
				expect(commands.size).to be_kind_of(Integer)
				expect(commands.size).to eq(3)
			end
		end
		
		describe "#command" do
			it "returns the I'th CompileCommand" do
				expect(commands.command(0)).to be_kind_of(CompilationDatabase::CompileCommand)
			end
		end
		
		describe "#commands" do
			it "returns all CompileCommand as Array" do
				expect(commands.commands).to be_kind_of(Array)
				expect(commands.commands.first).to be_kind_of(CompilationDatabase::CompileCommand)
				expect(commands.commands.size).to eq(commands.size)
			end
		end
		
		describe "#each" do
			let(:spy) {double(stub: nil)}
			it "calls block once for each CompileCommand" do
				expect(spy).to receive(:stub).exactly(commands.size).times
				commands.each{spy.stub}
			end
			
			it "returns an Enumerator if no block is given" do
				enumerator = commands.each
				expect(enumerator).to be_kind_of(Enumerator)
				expect(enumerator.to_a.map(&:filename)).to eq(commands.commands.map(&:filename))
			end
		end
	end
	
	describe CompilationDatabase::CompileCommand do
		let(:cmd) {cdb.all_compile_commands.command(0)}
		
		describe "#directory" do
			it "returns the working directory" do
				expect(cmd.directory).to be_kind_of(String)
				expect(cmd.directory).to eq("/home/xxxxx/src/build-trunk/lib/Support")
			end
		end
		
		describe "#filename" do
			it "returns the filename" do
				expect(cmd.filename).to be_kind_of(String)
				expect(cmd.filename).to eq("/home/xxxxx/src/llvm-trunk/lib/Support/APFloat.cpp")
			end
		end
		
		describe "#num_args" do
			it "returns the number of CompileCommand" do
				expect(cmd.num_args).to be_kind_of(Integer)
				expect(cmd.num_args).to be >= 31 # clang may insert additional args
			end
		end
		
		describe "#arg" do
			it "returns the I'th argument value" do
				expect(cmd.arg(0)).to be_kind_of(String)
				expect(cmd.arg(0)).to eq("/opt/llvm/3.4/bin/clang++")
			end
		end
		
		describe "#args" do
			it "returns all argument values as Array" do
				expect(cmd.args).to be_kind_of(Array)
				expect(cmd.args.first).to be_kind_of(String)
				expect(cmd.args.size).to eq(cmd.num_args)
			end
		end
		
		describe "#filename" do
			it "returns the filename" do
				expect(cmd.filename).to be_kind_of(String)
				expect(cmd.filename).to eq("/home/xxxxx/src/llvm-trunk/lib/Support/APFloat.cpp")
			end
		end
		
		describe "#num_mapped_sources" do
			it "returns the number of source mappings" do
				expect(cmd.num_mapped_sources).to be_kind_of(Integer)
				expect(cmd.num_mapped_sources).to eq(0)
			end
		end
		
		describe "#mapped_source_path" do
			it "returns nil if the index exceeds element size" do
				expect(cmd.mapped_source_path(1000)).to be_nil
			end
		end
		
		describe "#mapped_source_content" do
			it "returns nil if the index exceeds element size" do
				expect(cmd.mapped_source_content(1000)).to be_nil
			end
		end
		
		describe "#mapped_sources" do
			it "returns all mapped sources as Array" do
				expect(cmd.mapped_sources).to be_kind_of(Array)
				expect(cmd.mapped_sources.size).to eq(cmd.num_mapped_sources)
			end
		end
	end
end
