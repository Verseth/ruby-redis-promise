# typed: true
# frozen_string_literal: true

require 'test_helper'

class Redis::TestPromise < Minitest::Test
  #: Redis
  attr_reader :redis

  def setup
    host = ENV['REDIS_HOST'] || 'localhost'
    port = ENV['REDIS_PORT'] || '6379'
    @redis = Redis.new(host: host, port: port, db: 14)
  end

  should 'have a version number' do
    refute_nil ::Redis::Promise::VERSION
  end

  context 'await' do
    should 'throw a timeout error when timeout is exceeded' do
      promise = Redis::Promise.new(@redis)
      assert_raises Redis::Promise::TimeoutError do
        promise.await(timeout: 0.1)
      end
    end

    should 'return a resolved value' do
      promise, resolver = Redis::Promise.create(@redis)
      resolver.resolve('ok!')

      assert_equal 'ok!', promise.await
    end

    should 'throw a rejected value' do
      promise, resolver = Redis::Promise.create(@redis)
      resolver.reject('err!')

      assert_raises Redis::Promise::RejectedError do
        promise.await
      end
    end

  end

end
