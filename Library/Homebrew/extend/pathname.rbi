# typed: strict
# frozen_string_literal: true

module BinaryPathname
  sig { params(except: Symbol, resolve_variable_references: T::Boolean).returns(T::Array[String]) }
  def dynamically_linked_libraries(except: :none, resolve_variable_references: true); end
end
