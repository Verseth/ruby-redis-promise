# typed: true
# frozen_string_literal: true

class Redis
  class Promise
    # An additional mixin for Resque jobs.
    module Resque
      extend T::Helpers

      # Thrown when an invalid resque job class
      # was used to enqueue a promise
      class InvalidJobError < Error; end

      # @requires_ancestor: Kernel
      module ClassMethods
        # Returns a custom redis connection that will be used in promises
        # and resolvers.
        #
        # By default it uses `Resque.redis`
        #
        #: -> Redis
        def promise_redis = ::Resque.redis

        # The amount of time after which the resolved/rejected value will
        # get deleted from redis.
        #
        # By default `nil` which means it will never be deleted.
        #
        #: -> Integer?
        def expire = nil

        #: (*top) -> Promise
        def enqueue(*args)
          promise = Promise.new(promise_redis)
          T.unsafe(::Resque).enqueue(self, promise.key, *args) # rubocop:disable Sorbet/ForbidTUnsafe

          promise
        end

        #: (String, *untyped) -> void
        def perform(promise_key, *args); end

        # Defines the body of the job.
        #
        # Returned value will be used to resolve the promise.
        # Any thrown errors are caught and used to reject the promise.
        #
        #: { (untyped) -> void } -> void
        def run(&block)
          define_singleton_method :perform do |promise_key, *args|
            promise = Promise::Resolver.new(promise_redis, key: promise_key)

            begin
              result = block.call(*args)
              promise.resolve(result, expire: expire)
            rescue StandardError => e
              promise.reject("[#{e.class}]: #{e.message}", expire: expire)
            end
          end
        end

      end
      mixes_in_class_methods(ClassMethods)

    end
  end
end
