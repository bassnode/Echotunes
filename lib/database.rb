class Database
  def self.setup(conf={})
    new
  end

  def initialize
    @db = Sequel.sqlite('echotunes.db')
    @db.create_table(:tracks) do
      primary_key :id
      column :data, :string, :limit => 2000
    end
  end

  def save_track(track)
    track_id = track.persistent_id
    marsh = Marshal.dump(track.to_hash)
    @db[:tracks].insert(:id => track_id, :data => marsh)
  end

  def load_track(id)
    track = @db.filter(:id => id).first
    Marshal.load(track[:data])
  end


end
