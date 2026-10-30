# frozen_string_literal: true

ENV["HANAMI_ENV"] ||= "test"

# Silence expected test noise before any requires so gem-load warnings
# are suppressed too:
#   $VERBOSE      — stub redefinitions and gem internals
#   OmniAuth      — auth-failure tests log ERROR by design
#   Console       — structured logs (info/warn/error) are test fixtures
$VERBOSE = false
Warning[:experimental] = false
require "hanami/prepare"
require "minitest/autorun"
require "omniauth"
require "console"
require "async"
require_relative "factories"

OmniAuth.config.logger = Logger.new(File::NULL)
Console.logger.level = :fatal

# minitest 6 dropped minitest/mock. This stub shim allows swapping a named
# singleton method for a value or callable within a block, then restoring it.
# Mirrors the Rails test_helper implementation used in the oracle test suite.
class Object
  def stub(name, val_or_callable)
    original = method(name)
    define_singleton_method(name) do |*args, **kwargs, &block|
      if val_or_callable.respond_to?(:call)
        val_or_callable.call(*args, **kwargs, &block)
      else
        val_or_callable
      end
    end
    yield
  ensure
    define_singleton_method(name, original)
  end
end
