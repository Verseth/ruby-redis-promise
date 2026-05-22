# typed: true
# frozen_string_literal: true

require 'test_helper'
require 'redis/promise/resque'

class Redis::Promise::TestResque < Minitest::Test
  #: Redis
  attr_reader :redis

  class MultiplierJob
    include Redis::Promise::Resque

    @queue = :example

    class << self
      def promise_redis
        host = ENV['REDIS_HOST'] || 'localhost'
        port = ENV['REDIS_PORT'] || '6379'
        Redis.new(host: host, port: port, db: 14)
      end
    end

    run do |n|
      raise ArgumentError, "number must be positive: #{n}" if n < 0

      n * 69
    end
  end

  def setup
    host = ENV['REDIS_HOST'] || 'localhost'
    port = ENV['REDIS_PORT'] || '6379'
    @redis = Redis.new(host: host, port: port, db: 14)
  end

  context 'perform' do
    should 'resolve a promise' do
      promise = Redis::Promise.new(redis)
      MultiplierJob.perform(promise.key, 420)

      assert_equal 28980, promise.await
    end

    should 'reject a promise' do
      promise = Redis::Promise.new(redis)
      MultiplierJob.perform(promise.key, -22)

      assert_raises Redis::Promise::RejectedError do
        promise.await
      end
    end

  end

end
