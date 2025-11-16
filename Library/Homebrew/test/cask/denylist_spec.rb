# frozen_string_literal: true

require "cask/denylist"

RSpec.describe Cask::Denylist, :cask do
  describe "::reason" do
    matcher :disallow do |name|
      match do |expected|
        expected.reason(name)
      end
    end

    specify(:aggregate_failures) do
      expect(subject).not_to disallow("adobe-air")
      expect(subject).to disallow("adobe-after-effects")
      expect(subject).to disallow("adobe-illustrator")
      expect(subject).to disallow("adobe-indesign")
      expect(subject).to disallow("adobe-photoshop")
      expect(subject).to disallow("adobe-premiere")
      expect(subject).to disallow("pharo")
      expect(subject).not_to disallow("allowed-cask")
    end
  end
end
