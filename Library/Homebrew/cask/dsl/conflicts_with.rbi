# typed: strict
# frozen_string_literal: true

module Cask
  class DSL
    class ConflictsWith < SimpleDelegator
      include Kernel
    end
  end
end
