# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "dev-cmd/generate-formula-api"

RSpec.describe Homebrew::DevCmd::GenerateFormulaApi do
  it_behaves_like "parseable arguments"

  describe "#newest_bottle_sha256" do
    subject(:generate_formula_api) { described_class.new [] }

    def make_json(bottles)
      json = {
        "bottle" => {
          "stable" => {
            "files" => {},
          },
        },
      }
      bottles.each do |tag, sha256|
        json["bottle"]["stable"]["files"][tag] = { "sha256" => sha256 }
      end
      json
    end

    expected_sha256s = {
      arm64_sequoia:  "abc123",
      arm64_sonoma:   "abc123",
      arm64_ventura:  "ghi789",
      arm64_monterey: nil,
      sequoia:        "jkl012",
      sonoma:         "jkl012",
      ventura:        "mno345",
      monterey:       "mno345",
      x86_64_linux:   "pqr678",
      arm64_linux:    nil,
    }.transform_keys do |tag|
      Utils::Bottles::Tag.from_symbol(tag)
    end

    let(:all_json) { make_json all: "abc123" }
    let(:standard_json) do
      make_json arm64_sonoma:  "abc123",
                arm64_ventura: "ghi789",
                sonoma:        "jkl012",
                big_sur:       "mno345",
                x86_64_linux:  "pqr678"
    end

    it "returns the sha256 for the :all tag on all systems" do
      expected_sha256s.each_key do |tag|
        expect(generate_formula_api.newest_bottle_sha256(all_json, tag)).to eq("abc123")
      end
    end

    expected_sha256s.each_key do |tag|
      it "returns the corrent sha256 for #{tag}" do
        expect(generate_formula_api.newest_bottle_sha256(standard_json, tag)).to eq(expected_sha256s[tag])
      end
    end
  end
end
