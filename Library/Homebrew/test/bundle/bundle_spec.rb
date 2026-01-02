# frozen_string_literal: true

require "bundle"
require "bundle/dsl"

RSpec.describe Homebrew::Bundle do
  context "when the system call succeeds" do
    it "omits all stdout output if verbose is false" do
      expect { described_class.system "echo", "foo", verbose: false }.not_to output.to_stdout_from_any_process
    end

    it "emits all stdout output if verbose is true" do
      expect { described_class.system "echo", "foo", verbose: true }.to output("foo\n").to_stdout_from_any_process
    end
  end

  context "when the system call fails" do
    it "emits all stdout output even if verbose is false" do
      expect do
        described_class.system "/bin/bash", "-c", "echo foo && false",
                               verbose: false
      end.to output("foo\n").to_stdout_from_any_process
    end

    it "emits all stdout output only once if verbose is true" do
      expect do
        described_class.system "/bin/bash", "-c", "echo foo && true",
                               verbose: true
      end.to output("foo\n").to_stdout_from_any_process
    end
  end

  context "when checking for homebrew/cask", :needs_macos do
    it "finds it when present" do
      allow(File).to receive(:directory?).with("#{HOMEBREW_PREFIX}/Caskroom").and_return(true)
      allow(File).to receive(:directory?)
        .with("#{HOMEBREW_LIBRARY}/Taps/homebrew/homebrew-cask")
        .and_return(true)
      expect(described_class.cask_installed?).to be(true)
    end
  end

  context "when checking for mas", :needs_macos do
    it "finds it when present" do
      stub_formula_loader formula("mas") { url "mas-1.0" }
      allow(described_class).to receive(:which).and_return(true)
      expect(described_class.mas_installed?).to be(true)
    end
  end

  describe ".mark_as_installed_on_request!", :no_api do
    before do
      allow(DevelopmentTools).to receive_messages(needs_libc_formula?: false, needs_compiler_formula?: false)
    end

    it "sets installed_on_request=true for installed Brewfile formulae" do
      allow(Formula).to receive(:installed_formula_names).and_return(["myformula"])

      tabfile = Pathname.new("/fake/INSTALL_RECEIPT.json")
      tab = instance_double(Tab, installed_on_request: false, tabfile:)
      allow(Tab).to receive(:for_name).with("myformula").and_return(tab)
      allow(tabfile).to receive_messages(blank?: false, exist?: true)

      expect(tab).to receive(:installed_on_request=).with(true)
      expect(tab).to receive(:write)

      allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'myformula'")
      dsl = Homebrew::Bundle::Dsl.new(Pathname.new("/fake/Brewfile"))
      described_class.mark_as_installed_on_request!(dsl.entries)
    end

    it "skips formulae that are not installed" do
      allow(Formula).to receive(:installed_formula_names).and_return([])

      expect(Tab).not_to receive(:for_name)

      allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'notinstalled'")
      dsl = Homebrew::Bundle::Dsl.new(Pathname.new("/fake/Brewfile"))
      described_class.mark_as_installed_on_request!(dsl.entries)
    end

    it "skips formulae already marked as installed_on_request" do
      allow(Formula).to receive(:installed_formula_names).and_return(["alreadymarked"])

      tabfile = Pathname.new("/fake/INSTALL_RECEIPT.json")
      tab = instance_double(Tab, installed_on_request: true, tabfile:)
      allow(Tab).to receive(:for_name).with("alreadymarked").and_return(tab)
      allow(tabfile).to receive_messages(blank?: false, exist?: true)

      expect(tab).not_to receive(:installed_on_request=)
      expect(tab).not_to receive(:write)

      allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'alreadymarked'")
      dsl = Homebrew::Bundle::Dsl.new(Pathname.new("/fake/Brewfile"))
      described_class.mark_as_installed_on_request!(dsl.entries)
    end
  end
end
