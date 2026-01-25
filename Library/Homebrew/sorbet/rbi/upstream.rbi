# typed: strict

# This file contains temporary definitions for fixes that have
# been submitted upstream to https://github.com/sorbet/sorbet.

class IO
  sig { params(timeout: T.any(Float, Integer)).returns(IO) }
  def wait_readable(timeout = T.unsafe(nil)); end
end
