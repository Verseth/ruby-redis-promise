# Redis::Promise

This Ruby gem adds promises built on Redis.
It enables you to resolve or reject a redis promise based on a key and
await the result in another thread or on another machine/service.

It can be used in tandem with job frameworks like `resque` or `sidekiq` in order
to get back a result from an asynchronous task.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add redis-promise
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install redis-promise
```

## Usage

This library adds two basic types `Redis::Promise` and `Redis::Promise::Resolver`.
The Promise object can be used to await a resolved (success) value or a rejected (error) value.
The Resolver object can be used to resolve or reject a promise. These two objects are tied together by a common redis key where the result gets stored.

The basic idea is that you use a `Redis::Promise::Resolver` to resolve/reject the promise in one context eg. a thread or a different service. You then use `Redis::Promise` in another context to get (await) the value.

### Threads

Using the `Redis::Promise::create` helper to create a promise
and its resolver at the same time.

```rb
require 'redis/promise'

redis = Redis.new
promise, resolver = Redis::Promise.create(redis)

threads = []
threads << Thread.new do
  sleep(3)
  resolver.resolve("OK!")
end

threads << Thread.new do
  result = promise.await #=> "OK!"
end

threads.each(&:join)
# should print "OK!" after 3 seconds
```

Creating a separate promise and resolver.
Notice that the promise and resolver have to get their own
Redis connection instances, that's because the `promise.await`
blocks the entire redis connection making it impossible to resolve
the promise using the same connection.

```rb
require 'redis/promise'

redis = Redis.new
threads = []

promise = Redis::Promise.new(redis)
threads << Thread.new do
  puts promise.await #=> "OK!"
end

resolver = Redis::Promise::Resolver.new(redis, key: promise.key)
threads << Thread.new do
  sleep(3)
  resolver.resolve("OK!")
end

threads.each(&:join)
```

### Resque

You could use it in resque or any other job system to get the result from an asynchronous task.

```rb
# ========
# job definition

class SomeJob
  @queue = :example

  def self.perform(promise_key)
    resolver = Redis::Promise::Resolver.new(
      Resque.redis,
      key: promise_key,
    )
    resolver.resolve(42)
  end
end

# ========
# some other place in the app

promise = Redis::Promise.new(Resque.redis)
Resque.enqueue(SomeJob, promise.key)

promise.await #=> 42
# you got a value back from a resque job!
```

#### Plugin

There is an additional resque plugin you can load
to make it more convenient.

```rb
require 'redis/promise/resque'

class SomeJob
  include Redis::Promise::Resque

  @queue = :example

  run do |n|
    raise ArgumentError, "number must be positive: #{n}" if n < 0

    n * 69
  end
end

# enqueueing returns a promise
promise = SomeJob.enqueue(42)
promise.await #=> 2898

# errors thrown in the job get caught and rethrown on await
promise = SomeJob.enqueue(-2)
promise.await
#! Redis::Promise::RejectedError(value: "[ArgumentError]: number must be positive: -2")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Verseth/ruby-redis-promise.
