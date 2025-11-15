# typed: strict
# frozen_string_literal: true

require "cask_dependent"
require "dependents_message"
require "utils/output"

module Cask
  class Uninstall
    extend ::Utils::Output::Mixin

    sig { params(casks: ::Cask::Cask, binaries: T::Boolean, force: T::Boolean, verbose: T::Boolean).void }
    def self.uninstall_casks(*casks, binaries: false, force: false, verbose: false)
      require "cask/installer"

      casks.each do |cask|
        odebug "Uninstalling Cask #{cask}"

        raise CaskNotInstalledError, cask if !cask.installed? && !force

        Installer.new(cask, binaries:, force:, verbose:).uninstall
      end
    end

    sig { params(casks: ::Cask::Cask, named_args: T::Array[String]).void }
    def self.check_dependent_casks(*casks, named_args: [])
      dependents = []
      requireds = casks.map(&:token)
      caskroom = ::Cask::Caskroom.casks

      caskroom.each do |dependent|
        d = CaskDependent.new(dependent)
        dependencies = d.recursive_requirements.filter_map { |r| r.cask if r.is_a?(CaskDependent::Requirement) }
        next unless dependencies.intersect?(requireds)

        dependents << dependent.token
      end

      return if dependents.empty?

      DependentsMessage.new(requireds, dependents, named_args:).output
    end
  end
end
