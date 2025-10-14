# typed: strict
# frozen_string_literal: true

require "monitor"

# Module for querying the current execution context.
module Context
  extend MonitorMixin

  # Struct describing the current execution context.
  class ContextStruct
    sig { params(debug: T.nilable(T::Boolean), quiet: T.nilable(T::Boolean), verbose: T.nilable(T::Boolean)).void }
    def initialize(debug: nil, quiet: nil, verbose: nil)
      @debug = T.let(debug, T.nilable(T::Boolean))
      @quiet = T.let(quiet, T.nilable(T::Boolean))
      @verbose = T.let(verbose, T.nilable(T::Boolean))
    end

    sig { returns(T::Boolean) }
    def debug?
      @debug == true
    end

    sig { returns(T::Boolean) }
    def quiet?
      @quiet == true
    end

    sig { returns(T::Boolean) }
    def verbose?
      @verbose == true
    end
  end

  @current = T.let(nil, T.nilable(ContextStruct))

  sig { params(context: ContextStruct).void }
  def self.current=(context)
    synchronize do
      @current = context
    end
  end

  sig { returns(ContextStruct) }
  def self.current
    current_context = T.cast(Thread.current[:context], T.nilable(ContextStruct))
    return current_context if current_context

    synchronize do
      current = T.let(@current, T.nilable(ContextStruct))
      current ||= ContextStruct.new
      @current = current
      current
    end
  end

  sig { returns(T::Boolean) }
  def debug?
    Context.current.debug?
  end

  sig { returns(T::Boolean) }
  def quiet?
    Context.current.quiet?
  end

  sig { returns(T::Boolean) }
  def verbose?
    Context.current.verbose?
  end
  sig { params(options: T::Hash[Symbol, T.untyped], _block: T.proc.void).void }
  def with_context(**options, &_block)
    old_context = Context.current

    debug_option = options.key?(:debug) ? options[:debug] : old_context.debug?
    quiet_option = options.key?(:quiet) ? options[:quiet] : old_context.quiet?
    verbose_option = options.key?(:verbose) ? options[:verbose] : old_context.verbose?

    debug = T.cast(debug_option, T.nilable(T::Boolean))
    quiet = T.cast(quiet_option, T.nilable(T::Boolean))
    verbose = T.cast(verbose_option, T.nilable(T::Boolean))

    new_context = ContextStruct.new(
      debug:,
      quiet:,
      verbose:,
    )

    Thread.current[:context] = new_context

    begin
      yield
    ensure
      Thread.current[:context] = old_context
    end
  end
end
