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
      #: (top) -> void
      def resolve(value)
        serialized = { value: value }.to_json
        push(serialized)
      end

      # Reject the promise with the given value.
      # The value gets serialized to JSON using `to_json`.
      #
      #: (top) -> void
      def reject(err)
        serialized = { err: err }.to_json
        push(serialized)
      end

      private

      #: (String) -> void
      def push(serialized)
        @redis.rpush(@key, serialized)
      end
    end
  end
end
