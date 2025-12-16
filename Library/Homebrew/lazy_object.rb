# typed: strict
# frozen_string_literal: true

require "delegate"

# An object which lazily evaluates its inner block only once a method is called on it.
class LazyObject < Delegator
  UNSET = T.let(Object.new.freeze, Object)

  sig { params(callable: T.nilable(Proc)).void }
  def initialize(&callable)
    @__callable__ = T.let(nil, T.untyped)
    @__getobj__ = T.let(UNSET, T.untyped)
    super(callable)
  end

  sig { returns(T.untyped) }
  def __getobj__
    return @__getobj__ unless @__getobj__.equal?(UNSET)

    @__getobj__ = @__callable__.call
    @__getobj__
  end

  sig { params(callable: T.untyped).void }
  def __setobj__(callable)
    @__callable__ = callable
    @__getobj__ = UNSET
  end

  # Forward to the inner object to make lazy objects type-checkable.
  #
  # @!visibility private
  sig { params(klass: T.any(T::Module[T.anything], T::Class[T.anything])).returns(T::Boolean) }
  def is_a?(klass)
    # see https://sorbet.org/docs/faq#how-can-i-fix-type-errors-that-arise-from-super
    T.bind(self, T.untyped)

    __getobj__.is_a?(klass) || super
  end

  sig { returns(T::Class[T.anything]) }
  def class = __getobj__.class

  sig { returns(String) }
  def to_s = __getobj__.to_s
end
