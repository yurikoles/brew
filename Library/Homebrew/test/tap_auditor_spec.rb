# frozen_string_literal: true

require "tap_auditor"

RSpec.describe Homebrew::TapAuditor do
  let(:tap) { Tap.fetch("homebrew", "foo") }
  let(:tap_path) { tap.path }
  let(:auditor) { described_class.new(tap, strict: false) }

  def write_cask(token, path = tap_path/"Casks"/"#{token}.rb")
    path.dirname.mkpath
    path.write <<~RUBY
      cask "#{token}" do
        version "1.0"
        url "https://brew.sh/#{token}-1.0.dmg"
        name "#{token.capitalize} Cask"
        homepage "https://brew.sh"
      end
    RUBY
  end

  def write_formula(name, path = tap_path/"Formula"/"#{name}.rb")
    path.dirname.mkpath
    path.write <<~RUBY
      class #{name.capitalize} < Formula
        url "https://brew.sh/#{name}-1.0.tar.gz"
        version "1.0"
      end
    RUBY
  end

  before do
    tap_path.mkpath
    tap.clear_cache
  end

  describe "#audit" do
    subject(:problems) do
      auditor.audit
      auditor.problems
    end

    context "with cask_renames.json" do
      let(:cask_renames_path) { tap_path/"cask_renames.json" }
      let(:renames_data) { {} }

      before do
        write_cask("newcask")
        cask_renames_path.write JSON.pretty_generate(renames_data)
      end

      context "when .rb extension in old cask name (key)" do
        let(:renames_data) { { "oldcask.rb" => "newcask" } }

        it "detects the invalid format" do
          expect(problems).not_to be_empty
          expect(problems.first[:message]).to match(
            %r{cask_renames\.json contains entries with '\.rb' file extensions\.
               Rename entries should use formula/cask names only, without '\.rb' extensions\.
               Invalid entries: "oldcask\.rb": "newcask"}x,
          )
        end
      end

      context "when .rb extension in new cask name (value)" do
        let(:renames_data) { { "oldcask" => "newcask.rb" } }

        it "detects the invalid format" do
          expect(problems).not_to be_empty
          expect(problems.first[:message]).to match(
            /cask_renames\.json contains entries with '\.rb' file extensions\.\n.*\n.*"oldcask": "newcask\.rb"/m,
          )
        end
      end

      context "when missing target cask" do
        let(:renames_data) { { "oldcask" => "nonexistent" } }

        it "detects the missing target" do
          expect(problems).not_to be_empty
          expect(problems.first[:message]).to match(
            /cask_renames\.json contains renames to casks that do not exist .* tap\.\nInvalid targets: nonexistent/m,
          )
        end
      end

      context "with chained renames" do
        let(:renames_data) do
          {
            "oldcask" => "newcask",
            "newcask" => "finalcask",
          }
        end

        before do
          write_cask("finalcask")
        end

        it "detects the chained renames" do
          expect(problems).not_to be_empty
          problem_message = problems.find { |p| p[:message].include?("chained renames") }
          expect(problem_message).not_to be_nil
          expect(problem_message[:message]).to match(
            /cask_renames\.json contains chained renames that should be collapsed\.\n.*\n.*"oldcask": "finalcask"/m,
          )
        end
      end

      context "with multi-level chained renames" do
        let(:renames_data) do
          {
            "oldcask"          => "newcask",
            "newcask"          => "intermediatecask",
            "intermediatecask" => "finalcask",
          }
        end

        before do
          write_cask("intermediatecask")
          write_cask("finalcask")
        end

        it "suggests final target" do
          expect(problems).not_to be_empty
          problem_message = problems.find { |p| p[:message].include?("chained renames") }
          expect(problem_message).not_to be_nil
          expect(problem_message[:message]).to match(
            /cask_renames\.json contains chained renames that should be collapsed\.\n.*\n.*"oldcask": "finalcask"/m,
          )
          expect(problem_message[:message]).not_to include("intermediatecask")
        end
      end

      context "with chained renames where intermediates don't exist" do
        let(:renames_data) do
          {
            "veryoldcask"      => "intermediatecask",
            "intermediatecask" => "finalcask",
          }
        end

        before do
          write_cask("finalcask")
        end

        it "reports chained rename error, not invalid target error" do
          expect(problems.count).to eq(1)
          expect(problems.first[:message]).to match(
            /\Acask_renames\.json contains chained renames that should be collapsed\.
             Chained renames don't work automatically; each old name should point directly to the final target:
              {2}"veryoldcask": "finalcask" \(instead of chained rename\)\n\z/x,
          )
        end
      end

      context "when old name conflicts with existing cask" do
        let(:renames_data) { { "newcask" => "anothercask" } }

        before do
          write_cask("anothercask")
        end

        it "detects the conflict" do
          expect(problems).not_to be_empty
          problem_message = problems.find { |p| p[:message].include?("conflict") }
          expect(problem_message).not_to be_nil
          expect(problem_message[:message]).to match(
            /cask_renames\.json contains old names that conflict .* tap\.\n.*Conflicting names: newcask/m,
          )
        end
      end

      context "with correct rename entries" do
        let(:renames_data) { { "oldcask" => "newcask" } }

        it "passes validation" do
          rename_problems = problems.select { |p| p[:message].include?("cask_renames") }
          expect(rename_problems).to be_empty
        end
      end
    end

    context "with formula_renames.json" do
      let(:formula_renames_path) { tap_path/"formula_renames.json" }
      let(:renames_data) { {} }

      before do
        write_formula("newformula")
        formula_renames_path.write JSON.pretty_generate(renames_data)
      end

      context "when .rb extension in formula rename keys" do
        let(:renames_data) { { "oldformula.rb" => "newformula" } }

        it "detects the invalid format" do
          expect(problems).not_to be_empty
          expect(problems.first[:message]).to match(
            /formula_renames\.json contains entries with '\.rb' file extensions\.\n.*"oldformula\.rb"/m,
          )
        end
      end

      context "with chained formula renames" do
        let(:renames_data) do
          {
            "oldformula" => "newformula",
            "newformula" => "finalformula",
          }
        end

        before do
          write_formula("finalformula")
        end

        it "detects the chained renames" do
          expect(problems).not_to be_empty
          problem_message = problems.find { |p| p[:message].include?("chained renames") }
          expect(problem_message).not_to be_nil
          expect(problem_message[:message]).to match(
            /formula_renames\.json contains chained renames.*"oldformula": "finalformula"/m,
          )
        end
      end

      context "with correct formula rename entries" do
        let(:renames_data) { { "oldformula" => "newformula" } }

        it "passes validation" do
          rename_problems = problems.select { |p| p[:message].include?("formula_renames") }
          expect(rename_problems).to be_empty
        end
      end
    end
  end
end
