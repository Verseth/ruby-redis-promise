# typed: true

module Resque
  extend self

  #: -> Redis
  def redis; end
  def enqueue(klass, *args); end
end
