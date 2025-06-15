# frozen_string_literal: true

require "formula_creator"

RSpec.describe Homebrew::FormulaCreator do
  describe ".new" do
    tests = {
      "generic tarball URL": {
        url:      "http://digit-labs.org/files/tools/synscan/releases/synscan-5.02.tar.gz",
        expected: {
          name:    "synscan",
          version: "5.02",
        },
      },
      "gitweb URL":          {
        url:      "http://www.codesrc.com/gitweb/index.cgi?p=libzipper.git;a=summary",
        expected: {
          name: "libzipper",
        },
      },
      "GitHub repo URL":     {
        url:      "https://github.com/abitrolly/lapce.git",
        expected: {
          name: "lapce",
          head: true,
        },
      },
      "GitHub archive URL":  {
        url:      "https://github.com/abitrolly/lapce/archive/v0.3.0.tar.gz",
        expected: {
          name:    "lapce",
          version: "0.3.0",
        },
      },
      "GitHub download URL": {
        url:      "https://github.com/stella-emu/stella/releases/download/6.7/stella-6.7-src.tar.xz",
        expected: {
          name:    "stella",
          version: "6.7",
        },
      },
    }

    tests.each do |description, test|
      it "parses #{description}" do
        fc = described_class.new(url: test.fetch(:url))
        ex = test.fetch(:expected)
        expect(fc.name).to eq(ex[:name]) if ex.key?(:name)
        expect(fc.version).to eq(ex[:version]) if ex.key?(:version)
        expect(fc.head).to eq(ex[:head]) if ex.key?(:head)
      end
    end
  end
end
