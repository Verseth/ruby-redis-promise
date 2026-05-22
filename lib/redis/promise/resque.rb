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
        #: -> Redis
        def promise_redis = ::Resque.redis

        #: (*top) -> Promise
        def enqueue(*args)
          promise = Promise.new(promise_redis)
          T.unsafe(::Resque).enqueue(self, promise.key, *args) # rubocop:disable Sorbet/ForbidTUnsafe

          promise
        end

        #: (String, *untyped) -> void
        def perform(promise_key, *args); end

        #: { (untyped) -> void } -> void
        def run(&block)
          define_singleton_method :perform do |promise_key, *args|
            promise = Promise::Resolver.new(promise_redis, key: promise_key)

            begin
              result = block.call(*args)
              promise.resolve(result)
            rescue StandardError => e
              promise.reject("[#{e.class}]: #{e.message}")
            end
          end
        end

      end
      mixes_in_class_methods(ClassMethods)

    end
  end
end
