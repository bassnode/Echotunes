class ItunesWrapper

  def redis
    RedisWrapper.instance
  end

  def find_track(id)
    if cached = redis.get(redis.track_id(id))
      ITunes::Track.new({}, Marshal.load(cached))
    end
  end

  def find_tracks(ids)
    ids.map do |id|
      find_track(id)
    end
  end

  def all_tracks
    redis.keys('TRACK:*').map do |key|
      find_track(key.split(':').last)
    end
  end

  def create_playlist(name, song_ids)
    tracks = find_tracks(song_ids)
    %x{osascript -e 'tell application "iTunes" to make new user playlist with properties {name:"#{name}"}'}

    tracks.each do |track|
      %x{osascript -e 'tell application "iTunes" to duplicate (every track where ID is "#{track.id}") to playlist "#{name}"'}
    end
    # PLAY DAT SHIT!
    %x{osascript -e 'tell application "iTunes" to play playlist "#{name}"'}
  end


end
