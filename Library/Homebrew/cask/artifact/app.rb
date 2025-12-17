# typed: strict
# frozen_string_literal: true

require "cask/artifact/moved"

module Cask
  module Artifact
    # Artifact corresponding to the `app` stanza.
    class App < Moved
      sig {
        params(
          adopt:        T::Boolean,
          auto_updates: T::Boolean,
          force:        T::Boolean,
          verbose:      T::Boolean,
          predecessor:  T.nilable(Cask),
          successor:    T.nilable(Cask),
          reinstall:    T::Boolean,
          command:      T.class_of(SystemCommand),
        ).void
      }
      def install_phase(
        adopt: false,
        auto_updates: false,
        force: false,
        verbose: false,
        predecessor: nil,
        successor: nil,
        reinstall: false,
        command: SystemCommand
      )
        super

        return if target.ascend.none? { OS::Mac.system_dir?(_1) }

        odebug "Fixing up '#{target}' permissions for installation to '#{target.parent}'"
        # Ensure that globally installed applications can be accessed by all users.
        if target.writable?
          FileUtils.chmod_R("a+rX", target)
        else
          command.run!("chmod", args: ["-R", "a+rX", target], sudo: true)
        end

        executables = []
        target.find do |child|
          next if child.symlink?
          next if !child.executable?
          next if child.directory?

          executables << child
        end

        if executables.all?(&:writable?)
          FileUtils.chmod("a+x", executables)
        else
          command.run!("chmod", args: ["a+rX", *executables], sudo: true)
        end
      end
    end
  end
end
