# typed: strict
# frozen_string_literal: true

require "bundle/brewfile"
require "bundle/installer"

module Homebrew
  module Bundle
    module Commands
      module Install
        sig {
          params(
            global:     T::Boolean,
            file:       T.nilable(String),
            no_lock:    T::Boolean,
            no_upgrade: T::Boolean,
            verbose:    T::Boolean,
            force:      T::Boolean,
            quiet:      T::Boolean,
          ).void
        }
        def self.run(global: false, file: nil, no_lock: false, no_upgrade: false, verbose: false, force: false,
                     quiet: false)
          @dsl = Brewfile.read(global:, file:)
          result = Homebrew::Bundle::Installer.install!(
            @dsl.entries,
            global:, file:, no_lock:, no_upgrade:, verbose:, force:, quiet:,
          )

          # Mark Brewfile formulae as installed_on_request to prevent autoremove
          # from removing them when their dependents are uninstalled
          mark_formulae_as_installed_on_request

          result || exit(1)
        end

        sig { returns(T.nilable(Dsl)) }
        def self.dsl
          @dsl ||= T.let(nil, T.nilable(Dsl))
          @dsl
        end

        sig { void }
        private_class_method def self.mark_formulae_as_installed_on_request
          require "tab"

          return if @dsl.nil?

          brewfile_formulae = @dsl.entries.select { |e| e.type == :brew }.map(&:name)

          brewfile_formulae.each do |name|
            formula = Formulary.factory(name)
            next unless formula.any_version_installed?

            tab = Tab.for_formula(formula)
            next if tab.tabfile.blank? || !tab.tabfile.exist?
            next if tab.installed_on_request

            tab.installed_on_request = true
            tab.write
          rescue FormulaUnavailableError
            # Formula not found, skip it
            nil
          end
        end
      end
    end
  end
end
