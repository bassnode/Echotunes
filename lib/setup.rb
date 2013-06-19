require_relative 'redis_wrapper'

def redis
  RedisWrapper.instance
end

# Parsing this XML file is hella slow.  Store it in redis for quicker access.
def cache!(path)
  puts "Caching library"
  redis.flushall
  it = ITunes::Library.load path
  playlist = it.find_playlist('Echotunes')
  raise 'Create a "Echotunes" playlist in iTunes' unless playlist

  playlist.tracks.each do |track|
    redis.set redis.track_id(track.persistent_id), Marshal.dump(track.to_hash)
  end

  # TODO Don't leave this binary...recache every so often
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
