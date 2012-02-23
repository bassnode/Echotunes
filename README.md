EchoTunes
=========
Use Echonest to index your iTunes collection and create highly customizable playlists.

MusicHackDay 2012 Project
-------------------------
So it's a bit rough...


Requirements
============
* iTunes library file here: ~/Music/iTunes/iTunes Music Library.xml
* iTunes playlist named Echotunes with the songs in it
* Ruby, Bundler gem and Redis installed


Running it
==========
### clone the repo and bundle
    bundle install
### Start redis
    redis-server
### Start the Sinatra server
    bundle exec shotgun -p 3333
### Create and open the app
    rake

On first load, it will catalog your library (actually just the Echotunes playlist for now).
This process involves parsing the iTunes library XML and looking up the tracks with the Echonest API...
so it might take little while.


Todo
====
1.
