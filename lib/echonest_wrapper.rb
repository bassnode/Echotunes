class EchonestWrapper

  MIN_MAX_OPTIONS = {:loudness => true, :tempo => false, :energy => true, :danceability => true, :duration => false, :hotttnesss => true, :adventurousness => true, :variety => true}
  SORT = %w[tempo-asc duration-asc loudness-asc artist_familiarity-asc artist_hotttnesss-asc artist_start_year-asc artist_start_year-desc artist_end_year-asc artist_end_year-desc]

  class CatalogError < StandardError; end

  attr_accessor :en

  def initialize(key_file=nil)
    key_file ||= "~/.mreko/echonest_api.key"
    key = File.read(File.expand_path(key_file))

    self.en = Echonest(key)
  end

  def catalogs
    en.catalog.list['catalogs']
  end

  def create_catalog(name)
    en.catalog.create(name, 'song')
  end

  def catalog_profile(id)
    en.catalog.profile(:id => id)['catalog']
  end

  def ticket_status(ticket)
    ret = en.catalog.status(:ticket => ticket)
    Hashie::Mash.new( {:code => ret.ticket_status, :failed => ret.update_info, :updated => ret.items_updated } )
  end

  # @param [String] id of catalog
  # @param [Array<Hash>]
  # @return [Hashie::Mash] the status
  def add_songs_to_catalog(catalog_id, songs)
    res = en.catalog.update(catalog_id, item_batches(songs))
    ticket, status = res.ticket, nil

    # TODO: Make this async
    loop do
      status = ticket_status(ticket)
      break if %w[complete error].include? status.code
      puts status.code
      sleep 1
    end

    raise CatalogError if status.code == 'error'

    ticket
  end

  def fetch_playlist(options={})
    prepare_options! options

    pl = en.playlist.static(options)
    pl.songs
  end

  def itunes_ids_from_songs(songs)
    songs.map do |song|
      id = song.foreign_ids.first.foreign_id
      id.split(':').last
    end
  end

  def prepare_options!(options)
    # Sinatra junk
    options.delete('splat')
    options.delete('captures')

    # Requires for catalog usage
    options[:type] = 'catalog'
    options[:seed_catalog] = options.delete('catalog_id')
    options[:bucket] = ['audio_summary', 'tracks', "id:#{options[:seed_catalog]}"]
    options[:dmca] = false
    options[:limit] = false

    MIN_MAX_OPTIONS.each do |opt, decimal|
      pair = options.delete(opt.to_s)
      # Don't send if the defaults weren't changed
      next if pair.values.all? &:empty?

      multiplier = opt == :duration ? 60 : 1 # Since we take in minutes
      options["min_#{opt}".to_sym] = cast(pair[:lo], decimal, multiplier)
      options["max_#{opt}".to_sym] = cast(pair[:hi], decimal, multiplier)
    end

    # Dump empty options so EN doesn't poop
    options.each do |key, val|
      options.delete(key) if val.blank?
    end
  end

  def cast(int, decimal=false, multiplier=1.0)
    (decimal ? int.to_f / 100 : int.to_f) * multiplier
  end

  def analyze_and_add(catalog_id, songs)
    found = []
    songs.each do |song|
      begin
        song_path = fix_filepath(song['Location'])
        eko_song = MrEko::Song.catalog_via_enmfp song_path
        if eko_song
          puts "Found #{eko_song.artist} ENID: #{eko_song.echonest_id} PERSIST ID: #{song.persistent_id}"
          found << itunes_from_mr_eko(eko_song, song.persistent_id)
        else
          puts "Couldn't find shit for #{song.inspect}"
        end
      rescue StandardError => e
        puts "Sadness from MrEko: #{e}"
        e.backtrace[0..5].each do |b|
          puts b
        end
      end
    end

    if found.empty?
      puts "nothing new found!"
    else
      add_songs_to_catalog(catalog_id, found)
    end
  end


  private

  # EN only allows 100k ... but that seems a bit superflous now
  # @return [Array<Hash>] to pass to update catalog
  def item_batches(itunes_tracks, action=:update)
    songs = itunes_tracks.inject([]) do |songs, track|
      track_hash = {}
      track_hash[:item_id] = track.persistent_id

      if !track[:echonest_id].blank?
        # FIXME: EN Doesn't always successfully use this id - why?
        # Might have to do with Track vs. Song thing...can't sort it now.
        track_hash[:song_id] = track.echonest_id
        track_hash[:play_count] = 69
      else
        track_hash[:artist_name] = track.artist
        track_hash[:song_name] = track.name
        track_hash[:play_count] = track.play_count || 0
        track_hash[:release] = track.album if track.album
      end

      songs << track_hash
    end

    songs.map{ |song| {:item => song, :action => action} }
  end

  def itunes_from_mr_eko(eko_song, original_id)
    details = {
      :artist => eko_song.artist,
      :name => eko_song.title,
      :album => eko_song.album,
      :persistent_id => original_id,
      :code => eko_song.code,
      :echonest_id => eko_song.echonest_id
    }

    Hashie::Mash.new(details)
  end

  # handle crazy filepaths from itunes
  def fix_filepath(filepath)
    song_path = URI.unescape(filepath)
    fix_filepath(song_path) if song_path['%']

    song_path.gsub('file://localhost', '')
  end

end
