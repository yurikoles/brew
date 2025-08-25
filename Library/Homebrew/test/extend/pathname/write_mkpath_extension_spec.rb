# frozen_string_literal: true

require "extend/pathname/write_mkpath_extension"

RSpec.describe WriteMkpathExtension do
  let(:file_content) { "sample contents" }

  before do
    Pathname.prepend described_class
  end

  it "creates parent directories if they do not exist" do
    mktmpdir do |tmpdir|
      file = tmpdir/"foo/bar/baz.txt"
      expect(file.dirname).not_to exist
      file.write(file_content)
      expect(file).to exist
      expect(file.read).to eq(file_content)
    end
  end

  it "raises if file exists and not in append mode or with offset" do
    mktmpdir do |tmpdir|
      file = tmpdir/"file.txt"
      file.write(file_content)
      expect { file.write("new content") }.to raise_error(RuntimeError, /Will not overwrite/)
    end
  end

  it "allows overwrite if offset is provided" do
    mktmpdir do |tmpdir|
      file = tmpdir/"file.txt"
      file.write(file_content)
      expect do
        file.write("change", 0)
      end.not_to raise_error
      expect(file.read).to eq("change contents")
    end
  end

  it "allows append mode ('a')" do
    mktmpdir do |tmpdir|
      file = tmpdir/"file.txt"
      file.write(file_content)
      expect do
        file.write(" appended", mode: "a")
      end.not_to raise_error
      expect(file.read).to eq("#{file_content} appended")
    end
  end

  it "allows append mode ('a+')" do
    mktmpdir do |tmpdir|
      file = tmpdir/"file.txt"
      file.write(file_content)
      expect do
        file.write(" again", mode: "a+")
      end.not_to raise_error
      expect(file.read).to include("again")
    end
  end
end
