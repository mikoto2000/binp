$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require 'simplecov'
require "test/unit"

SimpleCov.start do
  enable_coverage :branch
  add_filter 'test'
end

require "binp"

