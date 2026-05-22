# typed: strict
# frozen_string_literal: true

class Redis
  class Promise
    # An object used to resolve or reject
    # a redis promise.
    class Resolver
      #: Redis
      attr_reader :redis

      #: String
      attr_reader :key

      #: (Redis, ?id: String, ?namespace: String, ?key: String) -> void
      def initialize(redis, id: SecureRandom.uuid_v4, namespace: 'global', key: "promise:#{namespace}:#{id}")
        @redis = redis.dup #: Redis
        @key = key
      end

      # Resolve the promise with the given value.
      # The value gets serialized to JSON using `to_json`.
      #
      # There is an optional argument `expire:` that determines
      # the amount of seconds after which the key-value will get automatically deleted from redis.
      #
      #: (top, ?expire: Integer?) -> void
      def resolve(value, expire: nil)
        serialized = { value: value }.to_json
        push(serialized, expire)
      end

      # Reject the promise with the given value.
      # The value gets serialized to JSON using `to_json`.
      #
      # There is an optional argument `expire:` that determines
      # the amount of seconds after which the key-value will get automatically deleted from redis.
      #
      #: (top, ?expire: Integer?) -> void
      def reject(err, expire: nil)
        serialized = { err: err }.to_json
        push(serialized, expire)
      end

      private

      #: (String, Integer?) -> void
      def push(serialized, expire)
        @redis.rpush(@key, serialized)
        @redis.expire(@key, expire) if expire
      end
    end
  end
end
