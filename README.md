# Docker container with mapproxy and mod_tile on apache2

# Building

```sh
docker build .
```

# Running

```sh
docker run --add-host=database:192.168.0.1 -p 80:80 *container-id*
```