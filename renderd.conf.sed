# Perform sed substitutions for `renderd.conf`
s/;socketname=/socketname=/
s/;MAXZOOM=18/MAXZOOM=20/
s/plugins_dir=\/usr\/lib\/mapnik\/input/plugins_dir=\/usr\/lib\/mapnik\/2.2\/input/
s/\(font_dir=\/usr\/share\/fonts\/truetype\)/\1\/ttf-dejavu/
s/XML=.*/XML=\/usr\/local\/src\/mapnik-style\/osm.xml/
s/HOST=tile.openstreetmap.org/HOST=localhost/
