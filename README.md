# Docker container with Mapproxy and Mapnik on apache2

This container runs Apache 2 with Mapproxy and Mod_tile configured to working together. It requires a PostgreSQL database
setup with openstreetmap data, the username "gis" and in a database named "gis". Tiles are rendered in gray tones, so
they are suitable for usage as background maps.

This container has the following parameters:

* Host "database", where the PostgreSQL database resides.
* Port "80", where Apache 2 listens on.
* Volume "/var/lib/mod_tile", where Mod_tile stores its cache.
* Volume "/usr/local/mapproxy/cache_data", where Mapproxy stores its cache.

The following URLs are available:

* Tiles http://container-ip/osm_tiles/{z}/{x}/{y}.png
* Mapproxy interface http://container-ip/mapproxy/
* WMS service URL: http://container-ip/mapproxy/service

# Starting the container

```sh
docker run --add-host=database:192.168.0.1 -p 80:80 alleveenstra/mapproxy-mapnik
```

# Setting up a database

This guide shows you how to setup a PostgreSQL database for usage with this container.

The first set is to install the required packages.

```sh
sudo apt-get install postgresql postgresql-contrib postgis wget docker.io osm2pgsql
```

```sh
sudo yum install epel-release
sudo yum install postgresql postgresql-server postgis docker boost -y
```

For CentOS fetch a osm2pgsql from https://www.rpmfind.net/linux/rpm2html/search.php?query=postgis and install it with:

```sh
rpm -i filename.rpm
```

Add the following to line to "/etc/postgresql/9.3/main/pg_hba.conf" on Ubuntu or "/var/lib/pgsql/data/pg_hba.conf" on CentOS.
The IP range (172.17.0.1/24) should reflect your docker adapter range.
You should look this up using: "ifconfig docker0".

```sh
host gis gis 172.17.0.1/24 trust
host gis gis 127.0.0.1/24 trust
```

Add the following to "/etc/postgresql/9.3/main/postgresql.conf" or "/var/lib/pgsql/data/postgresql.conf" on CentOS.
Restart PostgreSQL using "service postgresql restart".

```sh
listen_addresses = '*'
```

Create a superuser called gis.

```sh
sudo -u postgres createuser gis -s
```

Create a database called gis.

```sh
sudo -u postgres createdb gis
```

Add the postgis extensions to database gis.

```sh
echo "create extension postgis" | psql --host 127.0.0.1 gis gis
echo "create extension postgis_topology" | psql --host 127.0.0.1 gis gis
```

Download the openstreetmap data.

```sh
wget http://download.geofabrik.de/europe/netherlands-latest.osm.pbf
```

Import the openstreetmap data into the database.
Note that osm2pgsql has options to speed up an import.

```sh
osm2pgsql --slim --database gis --user gis --host 127.0.0.1 netherlands-latest.osm.pbf
```

Create local directories for the caches.

```sh
sudo mkdir -p /data/cache_data /data/mod_tile
sudo chown 33:33 /data/cache_data /data/mod_tile
```

Pull the container.

```sh
docker pull alleveenstra/mapproxy-mapnik
```

And run it.

```sh
docker run --add-host=database:172.17.42.1 \
           -v /data/mod_tile:/var/lib/mod_tile \
           -v /data/cache_data:/usr/local/mapproxy/cache_data \
           -p 80:80 -d alleveenstra/mapproxy-mapnik
```

When you experience error with the mount points, you might want to disabled selinux:

```sh
su -c "setenforce 0"
```