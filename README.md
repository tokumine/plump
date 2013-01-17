PLUMP. 
==  
Takes an .mbtile file with non-existent tile gaps and fills with blank tiles.

This keeps google maps happy by preventing 404's being served from mapbox/tilelive. 

To save space, this script uses 1 actual blank tile and links all missing tiles to this.

Install
--

```bash
> git clone git://github.com/tokumine/plump.git
> brew install sqlite3
> bundle install 
```


Use
--

```bash
> ruby plump.rb [MBTILES-FILE]
```

Notes
--
* written on ruby 1.9.3. 
* takes a while on large .mbtiles