# frozen_string_literal: true

require 'test_helper'

class Redis::TestPromise < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Redis::Promise::VERSION
  end
end
