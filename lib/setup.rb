require 'lib/redis_wrapper'
def redis
  RedisWrapper.instance
end

# CASH THEM SHITS
def cache!(path)
  puts "Cash money!"
  redis.flushall
  it = ITunes::Library.load path
  it.find_playlist('Echotunes').tracks.each do |track|
    redis.set redis.track_id(track.persistent_id), Marshal.dump(track.to_hash)
  end

  redis.set 'cached', Time.now
end

def already_cached?
  redis.exists 'cached'
end

if ENV['FORCE'] || !already_cached?
  cache! File.expand_path("~/Music/iTunes/iTunes Music Library.xml")
else
  puts "Don't need to cache!"
end
