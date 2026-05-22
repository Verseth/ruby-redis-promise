# typed: strict
# frozen_string_literal: true

require 'redis'
require 'json'
require 'securerandom'
require 'sorbet-runtime'
require_relative 'promise/version'
require_relative 'promise/resolver'

class Redis
  # An object used to wait for a value or an error
  # from redis.
  class Promise
    # Base error for `Redis::Promise`
    class Error < StandardError; end
    # Thrown when the timeout has been exceeded while
    # awaiting a `Redis::Promise`
    class TimeoutError < Error; end

    # Thrown when an awaited promise has been rejected.
    class RejectedError < Error
      #: untyped
      attr_reader :value

      #: (untyped) -> void
      def initialize(value)
        @value = value
        super("rejected redis promise: #{value.inspect}")
      end
    end

    class << self
      # Create a pair of Promise and Resolver objects for the same key.
      # The resolver can be used to either resolve or reject the promise.
      # The promise can be used to wait for the result.
      #
      #: (Redis, ?id: String, ?namespace: String) -> [Promise, Resolver]
      def create(redis, id: SecureRandom.uuid_v4, namespace: 'global')
        key = "promise:#{namespace}:#{id}"

        promise = Promise.new(redis, key: key)
        resolver = Resolver.new(redis, key: key)

        [promise, resolver]
      end
    end

    #: Redis
    attr_reader :redis

    #: String
    attr_reader :key

    #: (Redis, ?id: String, ?namespace: String, ?key: String) -> void
    def initialize(redis, id: SecureRandom.uuid_v4, namespace: 'global', key: "promise:#{namespace}:#{id}")
      @redis = redis.dup #: Redis
      @key = key
    end

    # Blocks the current thread until the resolved or rejected value
    # is available. By default it blocks indefinitely.
    # If the promise has been successfully resolved its value gets returned.
    # If the promise has been rejected a `Redis::Promise::RejectedError` gets thrown.
    #
    # You can provide an optional `timeout:` argument that is a float
    # of number of seconds the client should wait for the value.
    # If the timeout is exceeded a `Redis::Promise::TimeoutError` is thrown.
    #
    #: (?timeout: Float | Integer) -> untyped
    def await(timeout: 0)
      result = @redis.blpop(@key, timeout: timeout)
      raise TimeoutError unless result

      parsed = JSON.parse(result[1], symbolize_names: true)

      err = parsed[:err]
      raise RejectedError.new(err) if err # rubocop:disable Style/RaiseArgs

      parsed[:value]
    end
  end
end
