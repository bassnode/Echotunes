require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, :test)

require 'lib/setup'
require 'lib/redis_wrapper'
require "lib/echonest_wrapper"
require "lib/itunes_wrapper"
require "lib/html_helpers"


module Echotunes
  class App < Sinatra::Base
    helpers Sinatra::OutputBuffer::Helpers
    helpers Echotunes::HtmlHelpers

    def en
      @en ||= EchonestWrapper.new
    end

    def itunes
      @itunes ||= ItunesWrapper.new
    end

    def lookup_itunes_tracks(tracks)
      track_ids = tracks.map &:item_id
      itunes.find_tracks(track_ids)
    end

    get '/' do
      @catalogs = en.catalogs.select{ |c| c.type == 'song' }
      erb :index
    end

    post "/catalog" do
      catalog_id = params[:catalog]

      # create catalog
      if catalog_id.to_s == '0'
        catalog_id = en.create_catalog('Echotunes ' + rand(1_000).to_s).id
      end

      # TEMP: Just a few songs now
      itunes_songs = itunes.all_tracks
      ticket = en.add_songs_to_catalog(catalog_id, itunes_songs)

      redirect to("catalog/#{catalog_id}?ticket=#{ticket}")
    end

    get '/catalog/:catalog_id' do
      @catalog = en.catalog_profile(params[:catalog_id])
      @status = en.ticket_status(params[:ticket])

      unless @status.failed.empty?
        # Stick this in zeroMQ/Resque
        # en.analyze_and_add(params[:catalog_id], lookup_itunes_tracks(@status.failed))
      end

      erb :catalog
    end

    post '/playlist/:catalog_id' do
      name = params.delete('name')
      @songs = en.fetch_playlist(params)
      itunes_ids = en.itunes_ids_from_songs(@songs)
      itunes.create_playlist(name, itunes_ids)

      erb :playlist
    end
  end
end
