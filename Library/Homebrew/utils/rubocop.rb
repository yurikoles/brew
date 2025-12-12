#!/usr/bin/env ruby
# typed: strict
# frozen_string_literal: true

require_relative "../standalone"
require_relative "../warnings"

Warnings.ignore :parser_syntax do
  require "rubocop"
end

# TestProf is not able to detect what version of RuboCop we're using, so we need to manually import its cops.
# For more details, see https://github.com/test-prof/test-prof/blob/v1.5.0/lib/test_prof/rubocop.rb
Warnings.ignore(/TestProf cops require RuboCop >= 0.51.0 to run/) do
  # All this file does is check the RuboCop version and require the files below.
  # If we don't require this now while the warning is ignored, we'll see the warning again later
  # when RuboCop requires the file.
  require "test_prof/rubocop"

  # This is copied from test-prof/rubocop.rb, and is necessary because that file returns early if the RuboCop version
  # check isn't met.
  require "test_prof/cops/plugin"
  require "test_prof/cops/rspec/aggregate_examples"
end

exit RuboCop::CLI.new.run
