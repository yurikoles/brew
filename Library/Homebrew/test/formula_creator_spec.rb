# frozen_string_literal: true

require "formula_creator"

RSpec.describe Homebrew::FormulaCreator do
  describe ".new" do
    tests = {
      "generic tarball URL": {
        url:     "http://digit-labs.org/files/tools/synscan/releases/synscan-5.02.tar.gz",
        name:    "synscan",
        version: "5.02",
      },
      "gitweb URL":          {
        url:  "http://www.codesrc.com/gitweb/index.cgi?p=libzipper.git;a=summary",
        name: "libzipper",
      },
      "GitHub repo URL":     {
        url:  "https://github.com/abitrolly/lapce.git",
        name: "lapce",
        head: true,
      },
      "GitHub archive URL":  {
        url:     "https://github.com/abitrolly/lapce/archive/v0.3.0.tar.gz",
        name:    "lapce",
        version: "0.3.0",
      },
      "GitHub download URL": {
        url:     "https://github.com/stella-emu/stella/releases/download/6.7/stella-6.7-src.tar.xz",
        name:    "stella",
        version: "6.7",
      },
    }

    tests.each do |description, test|
      it "parses #{description}" do
        formula_creator = described_class.new(url: test.fetch(:url))
        expect(formula_creator.name).to eq(test.fetch(:name))
        if (version = test[:version])
          expect(formula_creator.version).to eq(version)
        else
          expect(formula_creator.version).to be_null
        end
        expect(formula_creator.head).to eq(test.fetch(:head, false))
      end
    end
  end
end
