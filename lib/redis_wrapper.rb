require 'redis'
require 'singleton'

class RedisWrapper
  include Singleton

  def initialize
    @redis = Redis.new
  end

  def track_id(id)
    "TRACK:#{id}"
  end

  def method_missing(method, *args, &block)
    @redis.send(method, *args, &block)
  end
end
