FROM phusion/baseimage:0.9.16
MAINTAINER Alle Veenstra <alle.veenstra@gmail.com>

# Set the locale
ENV LANG C.UTF-8
RUN update-locale LANG=C.UTF-8

RUN apt-get update -y && \
    apt-get install -y libapache2-mod-wsgi python-pip imagemagick supervisor wget software-properties-common python-software-properties git-core tar unzip bzip2 build-essential autoconf libtool libxml2-dev libgeos-dev libpq-dev libbz2-dev munin-node munin apache2 apache2-dev ttf-unifont autoconf mapnik-utils python-mapnik libmapnik-dev python-imaging python-yaml build-essential python-dev libjpeg-dev zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip install Shapely Pillow MapProxy uwsgi webcolors

# Install mod_tile and renderd
RUN cd /tmp && git clone https://github.com/openstreetmap/mod_tile.git && \
    cd /tmp/mod_tile && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install && \
    make install-mod_tile && \
    ldconfig && \
    rm -rf /tmp/mod_tile

# Install the Mapnik stylesheet
RUN cd /usr/local/src && git clone https://github.com/openstreetmap/mapnik-stylesheets mapnik-style

# Install the coastline data
RUN cd /usr/local/src/mapnik-style && ./get-coastlines.sh /usr/local/share && \
    rm -rf /usr/local/share/*.zip /usr/local/share/*.bz2 /usr/local/share/*.tgz && \
    rm -rf /usr/local/src/mapnik-style/*.zip /usr/local/src/mapnik-style/*.bz2 /usr/local/src/mapnik-style/*.tgz

# Configure mapnik style-sheets
RUN cd /usr/local/src/mapnik-style/inc && cp fontset-settings.xml.inc.template fontset-settings.xml.inc
ADD settings.sed /tmp/
RUN cd /usr/local/src/mapnik-style/inc && sed --file /tmp/settings.sed settings.xml.inc.template > settings.xml.inc
ADD datasource-settings.xml.inc /usr/local/src/mapnik-style/inc/datasource-settings.xml.inc

# Configure renderd
ADD renderd.conf.sed /tmp/
RUN cd /usr/local/etc && sed --file /tmp/renderd.conf.sed --in-place renderd.conf
RUN mapnik-config --input-plugins

# Create the files required for the mod_tile system to run
RUN mkdir /var/run/renderd && chown www-data /var/run/renderd
RUN mkdir /var/lib/mod_tile && chown www-data /var/lib/mod_tile

# Configure mod_tile
ADD mod_tile.load /etc/apache2/mods-available/
ADD mod_tile.conf /etc/apache2/mods-available/
RUN a2enmod mod_tile

# Define the application logging logic
ADD syslog-ng.conf /etc/syslog-ng/conf.d/local.conf

# Make the map grayscale
ADD togray.py /tmp/
RUN cd /tmp/ && find /usr/local/src/mapnik-style/ -iname "*.xml" -exec python togray.py {} \;
RUN cd /tmp/ && find /usr/local/src/mapnik-style/ -iname "*.inc" -exec python togray.py {} \;
RUN cd /tmp/ && find /usr/local/src/mapnik-style/ -iname "*.png" -exec mogrify -colorspace Gray {} \;
ADD layers.xml.inc /usr/local/src/mapnik-style/inc/layers.xml.inc

# Create a `mapproxy` service
RUN mkdir /usr/local/mapproxy
RUN mkdir /usr/local/mapproxy/cache_data
RUN chmod a+rwx /usr/local/mapproxy/cache_data
ADD mapproxy-mapnik.yaml /usr/local/mapproxy/mapproxy-mapnik.yaml
ADD config.py /usr/local/mapproxy/config.py
RUN a2enmod wsgi
RUN a2enmod rewrite
RUN a2dissite 000*
ADD tileserver.conf /etc/apache2/sites-available/tileserver.conf
RUN a2ensite tileserver.conf

# Install shapefiles files
RUN cd /usr/local/share/world_boundaries && \
    wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_boundary_lines_land.zip && \
    unzip ne_10m_admin_0_boundary_lines_land.zip && \
    rm ne_10m_admin_0_boundary_lines_land.zip

RUN cd /usr/local/share/world_boundaries && \
    wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_sovereignty.zip && \
    unzip ne_10m_admin_0_sovereignty.zip && \
    rm ne_10m_admin_0_sovereignty.zip

RUN cd /usr/local/share/world_boundaries && \
    wget http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_urban_areas.zip && \
    unzip ne_10m_urban_areas.zip && \
    rm ne_10m_urban_areas.zip

# Install custom shapefiles into mapnik
COPY layer-shapefiles.xml.inc /usr/local/src/mapnik-style/inc/layer-shapefiles.xml.inc

# Configure supervisord
RUN mkdir -p /var/lock/apache2 /var/run/apache2 /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

VOLUME /var/lib/mod_tile
VOLUME /usr/local/mapproxy/cache_data

# Expose the webserver
EXPOSE 80

# Start supervisord
CMD ["/usr/bin/supervisord"]
