# typed: strict
# frozen_string_literal: true

require "tap"

module Homebrew
  module DevCmd
    class Lgtm < AbstractCommand
      include SystemCommand::Mixin

      cmd_args do
        description <<~EOS
          Run `brew typecheck`, `brew style --changed` and `brew tests --changed` in one go.
        EOS
        named_args :none
      end

      sig { override.void }
      def run
        Homebrew.install_bundler_gems!(groups: Homebrew.valid_gem_groups - ["sorbet"])

        tap = Tap.from_path(Dir.pwd)

        typecheck_args = ["typecheck", tap&.name].compact
        ohai "brew #{typecheck_args.join(" ")}"
        safe_system HOMEBREW_BREW_FILE, *typecheck_args
        puts

        ohai "brew style --changed --fix"
        safe_system HOMEBREW_BREW_FILE, "style", "--changed", "--fix"
        puts

        if tap
          ohai "brew audit --changed --skip-style"
          safe_system HOMEBREW_BREW_FILE, "audit", "--changed", "--skip-style"
        else
          ohai "brew tests --changed"
          safe_system HOMEBREW_BREW_FILE, "tests", "--changed"
        end
      end
    end
  end
end
