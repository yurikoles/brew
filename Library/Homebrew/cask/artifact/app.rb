# typed: true # rubocop:todo Sorbet/StrictSigil
# frozen_string_literal: true

require "cask/artifact/moved"

module Cask
  module Artifact
    # Artifact corresponding to the `app` stanza.
    class App < Moved
      def install_phase(command: nil, **options)
        super

        return if target.ascend.none? { OS::Mac.system_dir?(_1) }

        odebug "Fixing up '#{target}' permissions for installation to '#{target.parent}'"
        # Ensure that globally installed applications can be accessed by all users.
        target.find do |child|
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
