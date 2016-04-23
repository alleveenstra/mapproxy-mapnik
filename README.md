# Docker container with Mapproxy and Mapnik on apache2



# Building

```sh
docker build .
```

# Installation

```sh
sudo apt-get install postgresql postgresql-contrib postgis wget docker.io osm2pgsql
*edit /etc/postgresql/9.3/main/pg_hba.conf, add: host gis gis 172.17.0.1/24 trust*
*edit /etc/postgresql/9.3/main/postgresql.conf, add: listen_addresses = '*', restart postgresql*
sudo -u postgres createuser gis -s
sudo -u postgres createdb gis
echo "create extension postgis" | psql -u gis -h 127.0.0.1
echo "create extension postgis_topography" | psql -u gis -h 127.0.0.1
wget http://download.geofabrik.de/europe/netherlands-latest.osm.pbf
osm2pgsql --slim --database gis --user gis netherlands-latest.osm.pbf
sudo mkdir -p /data/cache_data /data/mod_tile
sudo chown 33:33 /data/cache_data /data/mod_tile
docker pull alleveenstra/mapproxy-mapnik
docker run --add-host=database:172.17.42.1 \
           -v /data/mod_tile:/var/lib/mod_tile \
           -v /data/cache_data:/usr/local/mapproxy/cache_data \
           -p 80:80 -d alleveenstra/mapproxy-mapnik
```