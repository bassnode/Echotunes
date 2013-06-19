EchoTunes
=========
Use Echonest to index your iTunes collection and create highly customizable playlists.
It was born at a [MusicHackDay](http://sf.musichackday.org/2012/), so it's a bit rough...but it works.

Requirements
============
* iTunes library file here: ~/Music/iTunes/iTunes Music Library.xml
* iTunes playlist named Echotunes with the songs in it
* Ruby, [Bundler](http://gembundler.com/) gem and [Redis](http://redis.io/) installed


Running it
==========
### clone the repo and bundle
    bundle install
### Start redis
    redis-server
### Open the app
    rake

On first load, it will catalog your library (actually just the Echotunes playlist for now).
This process involves parsing the iTunes library XML and looking up the tracks with the Echonest API...
so it might take little while.


Todo
====
1. Fix the background processing to upload the unidentifiable songs to Echonest.
2. Rearchitect the initial scanner to handle real libraries (i.e. 1000s of songs).
3. Make the local Redis caching smarter.
