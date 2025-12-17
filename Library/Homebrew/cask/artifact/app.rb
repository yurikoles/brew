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
        target.find do |child|
          # Don't try to chmod symlinks outside the app bundle.
          next if child.realpath.ascend.none? { _1 == target.realpath }

          permissions = (child.executable? || child.directory?) ? "a+rx" : "a+r"
          if child.writable?
            FileUtils.chmod(permissions, child)
          else
            command.run!("chmod", args: [permissions, child], sudo: true)
          end
        end
      end
    end
  end
end
