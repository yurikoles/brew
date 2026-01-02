# frozen_string_literal: true

require "bundle"
require "bundle/commands/install"
require "bundle/cask_dumper"
require "bundle/skipper"

RSpec.describe Homebrew::Bundle::Commands::Install do
  before do
    allow_any_instance_of(IO).to receive(:puts)
  end

  context "when a Brewfile is not found" do
    it "raises an error" do
      allow_any_instance_of(Pathname).to receive(:read).and_raise(Errno::ENOENT)
      expect { described_class.run }.to raise_error(RuntimeError)
    end
  end

  context "when a Brewfile is found", :no_api do
    before do
      Homebrew::Bundle::CaskDumper.reset!
      allow(Homebrew::Bundle).to receive(:brew).and_return(true)
      allow(Homebrew::Bundle::FormulaInstaller).to receive(:formula_installed_and_up_to_date?).and_return(false)
      allow(Homebrew::Bundle::CaskInstaller).to receive(:installable_or_upgradable?).and_return(true)
      allow(Homebrew::Bundle::TapInstaller).to receive(:installed_taps).and_return([])
    end

    let(:brewfile_contents) do
      <<~EOS
        tap 'phinze/cask'
        brew 'mysql', conflicts_with: ['mysql56']
        cask 'phinze/cask/google-chrome', greedy: true
        mas '1Password', id: 443987910
        vscode 'GitHub.codespaces'
        flatpak 'org.gnome.Calculator'
      EOS
    end

    it "does not raise an error" do
      allow(Homebrew::Bundle::TapInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::VscodeExtensionInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::FlatpakInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::FormulaInstaller).to receive_messages(preinstall!: true, install!: true)
      allow(Homebrew::Bundle::CaskInstaller).to receive_messages(preinstall!: true, install!: true)
      allow(Homebrew::Bundle::MacAppStoreInstaller).to receive_messages(preinstall!: true, install!: true)
      allow_any_instance_of(Pathname).to receive(:read).and_return(brewfile_contents)
      expect { described_class.run }.not_to raise_error
    end

    it "#dsl returns a valid DSL" do
      allow(Homebrew::Bundle::TapInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::VscodeExtensionInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::FlatpakInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::FormulaInstaller).to receive_messages(preinstall!: true, install!: true)
      allow(Homebrew::Bundle::CaskInstaller).to receive_messages(preinstall!: true, install!: true)
      allow(Homebrew::Bundle::MacAppStoreInstaller).to receive_messages(preinstall!: true, install!: true)
      allow_any_instance_of(Pathname).to receive(:read).and_return(brewfile_contents)
      described_class.run
      expect(described_class.dsl.entries.first.name).to eql("phinze/cask")
    end

    it "does not raise an error when skippable" do
      expect(Homebrew::Bundle::FormulaInstaller).not_to receive(:install!)

      allow(Homebrew::Bundle::Skipper).to receive(:skip?).and_return(true)
      allow_any_instance_of(Pathname).to receive(:read)
        .and_return("brew 'mysql'")
      expect { described_class.run }.not_to raise_error
    end

    it "exits on failures" do
      allow(Homebrew::Bundle::FormulaInstaller).to receive_messages(preinstall!: true, install!: false)
      allow(Homebrew::Bundle::CaskInstaller).to receive_messages(preinstall!: true, install!: false)
      allow(Homebrew::Bundle::MacAppStoreInstaller).to receive_messages(preinstall!: true, install!: false)
      allow(Homebrew::Bundle::TapInstaller).to receive_messages(preinstall!: true, install!: false)
      allow(Homebrew::Bundle::VscodeExtensionInstaller).to receive_messages(preinstall!: true, install!: false)
      allow(Homebrew::Bundle::FlatpakInstaller).to receive_messages(preinstall!: true, install!: false)
      allow_any_instance_of(Pathname).to receive(:read).and_return(brewfile_contents)

      expect { described_class.run }.to raise_error(SystemExit)
    end

    it "skips installs from failed taps" do
      allow(Homebrew::Bundle::CaskInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::TapInstaller).to receive_messages(preinstall!: true, install!: false)
      allow(Homebrew::Bundle::FormulaInstaller).to receive_messages(preinstall!: true, install!: true)
      allow(Homebrew::Bundle::MacAppStoreInstaller).to receive_messages(preinstall!: true, install!: true)
      allow(Homebrew::Bundle::VscodeExtensionInstaller).to receive_messages(preinstall!: true, install!: true)
      allow(Homebrew::Bundle::FlatpakInstaller).to receive_messages(preinstall!: true, install!: true)
      allow_any_instance_of(Pathname).to receive(:read).and_return(brewfile_contents)

      expect { described_class.run }.to raise_error(SystemExit)
    end

    it "marks Brewfile formulae as installed_on_request after installing" do
      allow(Homebrew::Bundle::TapInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::VscodeExtensionInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::FlatpakInstaller).to receive(:preinstall!).and_return(false)
      allow(Homebrew::Bundle::FormulaInstaller).to receive_messages(preinstall!: true, install!: true)
      allow(Homebrew::Bundle::CaskInstaller).to receive_messages(preinstall!: true, install!: true)
      allow(Homebrew::Bundle::MacAppStoreInstaller).to receive_messages(preinstall!: true, install!: true)
      allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'test_formula'")

      expect(described_class).to receive(:mark_formulae_as_installed_on_request)
      described_class.run
    end
  end

  describe ".mark_formulae_as_installed_on_request", :no_api do
    before do
      allow(DevelopmentTools).to receive_messages(needs_libc_formula?: false, needs_compiler_formula?: false)
    end

    it "sets installed_on_request=true for installed Brewfile formulae" do
      allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'myformula'")
      # Trigger DSL parsing by calling run with mocked installers
      allow(Homebrew::Bundle::FormulaInstaller).to receive_messages(preinstall!: false, install!: true)
      allow(Homebrew::Bundle).to receive(:brew).and_return(true)

      myformula = formula("myformula") { url "myformula-1.0" }
      stub_formula_loader myformula, "myformula"
      allow(myformula).to receive(:any_version_installed?).and_return(true)

      tabfile = Pathname.new("/fake/INSTALL_RECEIPT.json")
      tab = instance_double(Tab, installed_on_request: false, tabfile:)
      allow(Tab).to receive(:for_formula).with(myformula).and_return(tab)
      allow(tabfile).to receive_messages(blank?: false, exist?: true)

      expect(tab).to receive(:installed_on_request=).with(true)
      expect(tab).to receive(:write)

      described_class.run
    end

    it "skips formulae that are not installed" do
      allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'notinstalled'")
      allow(Homebrew::Bundle::FormulaInstaller).to receive_messages(preinstall!: false, install!: true)
      allow(Homebrew::Bundle).to receive(:brew).and_return(true)

      myformula = formula("notinstalled") { url "notinstalled-1.0" }
      stub_formula_loader myformula, "notinstalled"
      allow(myformula).to receive(:any_version_installed?).and_return(false)

      expect(Tab).not_to receive(:for_formula)

      described_class.run
    end

    it "skips formulae already marked as installed_on_request" do
      allow_any_instance_of(Pathname).to receive(:read).and_return("brew 'alreadymarked'")
      allow(Homebrew::Bundle::FormulaInstaller).to receive_messages(preinstall!: false, install!: true)
      allow(Homebrew::Bundle).to receive(:brew).and_return(true)

      myformula = formula("alreadymarked") { url "alreadymarked-1.0" }
      stub_formula_loader myformula, "alreadymarked"
      allow(myformula).to receive(:any_version_installed?).and_return(true)

      tabfile = Pathname.new("/fake/INSTALL_RECEIPT.json")
      tab = instance_double(Tab, installed_on_request: true, tabfile:)
      allow(Tab).to receive(:for_formula).with(myformula).and_return(tab)
      allow(tabfile).to receive_messages(blank?: false, exist?: true)

      expect(tab).not_to receive(:installed_on_request=)
      expect(tab).not_to receive(:write)

      described_class.run
    end
  end
end
