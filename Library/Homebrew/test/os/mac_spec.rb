# frozen_string_literal: true

require "locale"
require "os/mac"

RSpec.describe OS::Mac do
  describe "::languages" do
    it "returns a list of all languages" do
      expect(described_class.languages).not_to be_empty
    end
  end

  describe "::language" do
    it "returns the first item from #languages" do
      expect(described_class.language).to eq(described_class.languages.first)
    end
  end

  describe "::sdk_path_if_needed" do
    it "calls sdk_path on Xcode-only systems" do
      allow(OS::Mac::Xcode).to receive(:installed?).and_return(true)
      allow(OS::Mac::CLT).to receive(:installed?).and_return(false)
      expect(described_class).to receive(:sdk_path)
      described_class.sdk_path_if_needed
    end

    it "calls sdk_path on CLT-only systems" do
      allow(OS::Mac::Xcode).to receive(:installed?).and_return(false)
      allow(OS::Mac::CLT).to receive_messages(installed?: true)
      expect(described_class).to receive(:sdk_path)
      described_class.sdk_path_if_needed
    end
  end
end
