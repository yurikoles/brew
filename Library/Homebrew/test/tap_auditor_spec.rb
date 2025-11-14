# frozen_string_literal: true

require "tap_auditor"

RSpec.describe Homebrew::TapAuditor do
  subject(:auditor) { described_class.new(tap, strict: false) }

  let(:tap) { Tap.fetch("homebrew", "foo") }
  let(:tap_path) { tap.path }

  before do
    tap_path.mkpath
    tap.clear_cache
  end

  describe "#audit" do
    context "with cask_renames.json" do
      let(:cask_renames_path) { tap_path/"cask_renames.json" }
      let(:cask_path) { tap_path/"Casks"/"newcask.rb" }

      before do
        cask_path.dirname.mkpath
        cask_path.write <<~RUBY
          cask "newcask" do
            version "1.0"
            url "https://brew.sh/newcask-1.0.dmg"
            name "New Cask"
            homepage "https://brew.sh"
          end
        RUBY
      end

      it "detects .rb extension in old cask name (key)" do
        cask_renames_path.write JSON.pretty_generate({
          "oldcask.rb" => "newcask",
        })

        auditor.audit
        expect(auditor.problems).not_to be_empty
        expect(auditor.problems.first[:message]).to match(
          /cask_renames\.json contains entries with '\.rb' file extensions\.\n.*\n.*"oldcask\.rb": "newcask"/m,
        )
      end

      it "detects .rb extension in new cask name (value)" do
        cask_renames_path.write JSON.pretty_generate({
          "oldcask" => "newcask.rb",
        })

        auditor.audit
        expect(auditor.problems).not_to be_empty
        expect(auditor.problems.first[:message]).to match(
          /cask_renames\.json contains entries with '\.rb' file extensions\.\n.*\n.*"oldcask": "newcask\.rb"/m,
        )
      end

      it "detects missing target cask" do
        cask_renames_path.write JSON.pretty_generate({
          "oldcask" => "nonexistent",
        })

        auditor.audit
        expect(auditor.problems).not_to be_empty
        expect(auditor.problems.first[:message]).to match(
          /cask_renames\.json contains renames to casks that do not exist .* tap\.\nInvalid targets: nonexistent/m,
        )
      end

      it "detects chained renames" do
        another_cask_path = tap_path/"Casks"/"finalcask.rb"
        another_cask_path.write <<~RUBY
          cask "finalcask" do
            version "1.0"
            url "https://brew.sh/finalcask-1.0.dmg"
            name "Final Cask"
            homepage "https://brew.sh"
          end
        RUBY

        cask_renames_path.write JSON.pretty_generate({
          "oldcask" => "newcask",
          "newcask" => "finalcask",
        })

        auditor.audit
        expect(auditor.problems).not_to be_empty
        problem_message = auditor.problems.find { |p| p[:message].include?("chained renames") }
        expect(problem_message).not_to be_nil
        expect(problem_message[:message]).to match(
          /cask_renames\.json contains chained renames that should be collapsed\.\n.*\n.*"oldcask": "finalcask"/m,
        )
      end

      it "detects multi-level chained renames and suggests final target" do
        cask_path2 = tap_path/"Casks"/"intermediatecask.rb"
        cask_path2.write <<~RUBY
          cask "intermediatecask" do
            version "1.0"
            url "https://brew.sh/intermediatecask-1.0.dmg"
            name "Intermediate Cask"
            homepage "https://brew.sh"
          end
        RUBY

        cask_path3 = tap_path/"Casks"/"finalcask.rb"
        cask_path3.write <<~RUBY
          cask "finalcask" do
            version "1.0"
            url "https://brew.sh/finalcask-1.0.dmg"
            name "Final Cask"
            homepage "https://brew.sh"
          end
        RUBY

        cask_renames_path.write JSON.pretty_generate({
          "oldcask"          => "newcask",
          "newcask"          => "intermediatecask",
          "intermediatecask" => "finalcask",
        })

        auditor.audit
        expect(auditor.problems).not_to be_empty
        problem_message = auditor.problems.find { |p| p[:message].include?("chained renames") }
        expect(problem_message).not_to be_nil
        expect(problem_message[:message]).to match(
          /cask_renames\.json contains chained renames that should be collapsed\.\n.*\n.*"oldcask": "finalcask"/m,
        )
        expect(problem_message[:message]).not_to include("intermediatecask")
      end

      it "detects old name conflicts with existing cask" do
        cask_renames_path.write JSON.pretty_generate({
          "newcask" => "anothercask",
        })

        another_cask_path = tap_path/"Casks"/"anothercask.rb"
        another_cask_path.write <<~RUBY
          cask "anothercask" do
            version "1.0"
            url "https://brew.sh/anothercask-1.0.dmg"
            name "Another Cask"
            homepage "https://brew.sh"
          end
        RUBY

        auditor.audit
        expect(auditor.problems).not_to be_empty
        problem_message = auditor.problems.find { |p| p[:message].include?("conflict") }
        expect(problem_message).not_to be_nil
        expect(problem_message[:message]).to match(
          /cask_renames\.json contains old names that conflict .* tap\.\n.*Conflicting names: newcask/m,
        )
      end

      it "passes validation for correct rename entries" do
        cask_renames_path.write JSON.pretty_generate({
          "oldcask" => "newcask",
        })

        auditor.audit
        rename_problems = auditor.problems.select { |p| p[:message].include?("cask_renames") }
        expect(rename_problems).to be_empty
      end
    end

    context "with formula_renames.json" do
      let(:formula_renames_path) { tap_path/"formula_renames.json" }
      let(:formula_path) { tap_path/"Formula"/"newformula.rb" }

      before do
        formula_path.dirname.mkpath
        formula_path.write <<~RUBY
          class Newformula < Formula
            url "https://brew.sh/newformula-1.0.tar.gz"
            version "1.0"
          end
        RUBY
      end

      it "detects .rb extension in formula rename keys" do
        formula_renames_path.write JSON.pretty_generate({
          "oldformula.rb" => "newformula",
        })

        auditor.audit
        expect(auditor.problems).not_to be_empty
        expect(auditor.problems.first[:message]).to match(
          /formula_renames\.json contains entries with '\.rb' file extensions\.\n.*"oldformula\.rb"/m,
        )
      end

      it "detects chained formula renames" do
        another_formula_path = tap_path/"Formula"/"finalformula.rb"
        another_formula_path.write <<~RUBY
          class Finalformula < Formula
            url "https://brew.sh/finalformula-1.0.tar.gz"
            version "1.0"
          end
        RUBY

        formula_renames_path.write JSON.pretty_generate({
          "oldformula" => "newformula",
          "newformula" => "finalformula",
        })

        auditor.audit
        expect(auditor.problems).not_to be_empty
        problem_message = auditor.problems.find { |p| p[:message].include?("chained renames") }
        expect(problem_message).not_to be_nil
        expect(problem_message[:message]).to match(
          /formula_renames\.json contains chained renames.*"oldformula": "finalformula"/m,
        )
      end

      it "passes validation for correct formula rename entries" do
        formula_renames_path.write JSON.pretty_generate({
          "oldformula" => "newformula",
        })

        auditor.audit
        rename_problems = auditor.problems.select { |p| p[:message].include?("formula_renames") }
        expect(rename_problems).to be_empty
      end
    end
  end
end
