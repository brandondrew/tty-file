# encoding: utf-8

RSpec.describe TTY::File, '#create_file' do
  before do
    ::FileUtils.rm_rf(tmp_path)
  end

  it "creates file" do
    expect {
      TTY::File.create_file(File.join(tmp_path, 'doc/README.md'))
    }.to output(/create/).to_stdout_from_any_process

    expect(File.exist?(File.join(tmp_path, 'doc/README.md'))).to eq(true)
  end

  it "creates file with content" do
    file = File.join(tmp_path, 'doc/README.md')
    TTY::File.create_file(file, '# Title', verbose: false)

    expect(File.read(file)).to eq('# Title')
  end

  it "creates file with content in a block" do
    file = File.join(tmp_path, 'doc/README.md')
    TTY::File.create_file(file, verbose: false) do
      "# Title"
    end

    expect(File.read(file)).to eq('# Title')
  end

  it "doesn't create file if :noop is true" do
    file = File.join(tmp_path, 'doc/README.md')
    TTY::File.create_file(file, '# Title', noop: true, verbose: false)

    expect(File.exist?(file)).to eq(false)
  end

  context 'when file exists' do
    context 'and is identical' do
      it "logs identical status" do
        file = File.join(tmp_path, 'README.md')
        TTY::File.create_file(file, '# Title', verbose: false)
        expect {
          TTY::File.create_file(file, '# Title', verbose: true)
        }.to output(/identical/).to_stdout_from_any_process
      end
    end

    context 'and is not identical' do
      it "logs forced status if force is true" do
        file = File.join(tmp_path, 'README.md')
        TTY::File.create_file(file, '# Title', verbose: false)
        expect {
          TTY::File.create_file(file, '# Header', verbose: true, force: true)
        }.to output(/force/).to_stdout_from_any_process
      end

      it "displays collision menu and overwrites" do
        test_prompt = TTY::TestPrompt.new
        test_prompt.input << "\n"
        test_prompt.input.rewind
        allow(TTY::Prompt).to receive(:new).and_return(test_prompt)

        file = File.join(tmp_path, 'README.md')
        TTY::File.create_file(file, '# Title', verbose: false)

        expect {
          TTY::File.create_file(file, '# Header', verbose: true)
        }.to output(/collision/).to_stdout_from_any_process

        expect(File.read(file)).to eq('# Header')
      end

      it "displays collision menu and doesn't overwrite" do
        test_prompt = TTY::TestPrompt.new
        test_prompt.input << "n\n"
        test_prompt.input.rewind
        allow(TTY::Prompt).to receive(:new).and_return(test_prompt)

        file = File.join(tmp_path, 'README.md')
        TTY::File.create_file(file, '# Title', verbose: false)

        expect {
          TTY::File.create_file(file, '# Header', verbose: true)
        }.to output(/collision/).to_stdout_from_any_process

        expect(File.read(file)).to eq('# Title')
      end

      it "displays collision menu and aborts" do
        test_prompt = TTY::TestPrompt.new
        test_prompt.input << "q\n"
        test_prompt.input.rewind
        allow(TTY::Prompt).to receive(:new).and_return(test_prompt)

        file = File.join(tmp_path, 'README.md')
        TTY::File.create_file(file, '# Title', verbose: false)

        expect {
          TTY::File.create_file(file, '# Header', verbose: false)
        }.to raise_error(SystemExit)

        expect(File.read(file)).to eq('# Title')
      end
    end
  end
end