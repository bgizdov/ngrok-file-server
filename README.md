[ [ GitHub ] ](https://github.com/bgizdov/ngrok-file-server)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
[ [ DockerHub ]](https://hub.docker.com/r/bgizdov/ngrok-file-server)

Forked from and credits: https://github.com/peterberweiler/fileserver

# 📁 HTTP File Server with Folder Indices (Docker Container)

<p align="center"> 
  <a href="https://nginx.org"><img alt="nginx" src="https://nginx.org/nginx.png" height="35"></a>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://nodejs.org"><img alt="nodejs" src="https://nodejs.org/static/images/logo.svg" height="55"></a>
</p>


A docker container that provides a http download server for files, a simple
folder ui and indices for downloading (via [aria2](http://aria2.github.io) or
other download managers).

The container extends the official
[nginx docker container](https://hub.docker.com/_/nginx). Requests to folders
are forwarded to the [nodejs](https://nodejs.org) indexserver. The container
processes are managed with
[s6-overlay](https://github.com/just-containers/s6-overlay).


## Features:

- An easy UI to navigate the folders
- Easy download with [aria2](http://aria2.github.io), just add `?aria2` to any
  folder url to get download instructions for aria2 ([example](#aria2-usage))
- To get a list of absolute urls for all nested files within a folder, just add
  `?raw` to any folder url
- Basic Auth support

# Setup

## Via docker cli

```bash
docker run \
  --rm -v $PWD:/public 
  -e NGROK_AUTH_TOKEN=YOUR_TOKEN \
  bgizdov/ngrok-file-server
```

You will see the public address in the log:
```
[cont-init.d] 01-ngrok-tunel.sh: executing...
#############################################
#                                           #
#                 INFO                      #
#        starting ngrok tunnel              #
#                                           #
#############################################
Authtoken saved to configuration file: /root/.config/ngrok/ngrok.yml
[cont-init.d] 01-ngrok-tunel.sh: exited 0.
[cont-init.d] nginx-setup.sh: executing...
[cont-init.d] nginx-setup.sh: exited 0.
[cont-init.d] done.
[services.d] starting services
t=2023-05-21T22:03:35+0000 lvl=info msg="no configuration paths supplied"
t=2023-05-21T22:03:35+0000 lvl=info msg="using configuration at default config path" path=/root/.config/ngrok/ngrok.yml
t=2023-05-21T22:03:35+0000 lvl=info msg="open config file" path=/root/.config/ngrok/ngrok.yml err=nil
t=2023-05-21T22:03:35+0000 lvl=info msg="starting web service" obj=web addr=127.0.0.1:4040 allow_hosts=[]
t=2023-05-21T22:03:35+0000 lvl=info msg="client session established" obj=tunnels.session obj=csess id=e14d4f8799de
t=2023-05-21T22:03:35+0000 lvl=info msg="tunnel session started" obj=tunnels.session
t=2023-05-21T22:03:35+0000 lvl=info msg="started tunnel" obj=tunnels name=command_line addr=http://localhost:80 url=https://21f7-130-204-139-211.ngrok-free.app
```

## Via docker compose

```yaml
version: "3"
services:
  fileserver:
    image: bgizdov/ngrok-file-server
    container_name: ngrok-file-server
    environment:
        # all of these are optional
      - BASEPATH=/
      - BASIC_AUTH_ENABLED=false 
      - BASIC_AUTH_REALM=admin 
      - BASIC_AUTH_USER=admin 
      - BASIC_AUTH_PASSWORD=fileserver 
      - NGROK_AUTH_TOKEN=YOUR_TOKEN
    volumes:
      - /path/to/files:/public
    ports:
      - "80:80"
    restart: unless-stopped
```

# Environment Variables

| Variable              |   Default    | Function                                                                                                                            |
| --------------------- | :----------: | ----------------------------------------------------------------------------------------------------------------------------------- |
| `BASEPATH`            |     `/`      | if your file server is behind another reverse proxy you need to set this to the path where it is reachable (for example `/myfiles`) |
| `BASIC_AUTH_ENABLED`  |   `false`    | enables basic auth, for the indices and files (Reminder: when using http your username, password and traffic will not be encrypted) |
| `BASIC_AUTH_USER`     |   `admin`    | basic auth username                                                                                                                 |
| `BASIC_AUTH_PASSWORD` | `fileserver` | basic auth password                                                                                                                 |
| `BASIC_AUTH_REALM`    |   `admin`    | basic auth realm, only needed if you have another basic auth server on the same url                                                 |

# Url Parameters

| Parameter  | Function                                                                                      |
| :--------: | --------------------------------------------------------------------------------------------- |
|   `?raw`   | returns a list of absolute urls for all files in the current directory and all children       |
|  `?aria2`  | returns download instructions for aria2c                                                      |
| `?depth=5` | limits how many levels of sub folders should be included (can be combined with aria2 and raw) |

# Url Examples

| Query                         | Function                                                                                      |
| ----------------------------- | --------------------------------------------------------------------------------------------- |
| `/movies?aria2`               | returns download instructions for the complete `movies` directory                             |
| `/documents/text?raw&depth=1` | returns a list of absolute paths for all files in `/documents/text` and their direct children |

# aria2 Usage

You can use it with aria2 like so:

```sh
curl http://localhost/media/?aria2 | aria2c -c -i -
```

This would download the complete `media` folder into the current directory. For
more infos, check out the
[aria2 documentation](https://aria2.github.io/manual/en/html/aria2c.html#)

# Server Response Examples

In these examples the following `/` folder is bound to `/public`

```
/ 
└─ media/
   ├─ movies/
   |  └─ cool-movie.mkv
   |
   └─ tv/
      └─ cool-series/
         ├─ s01e01.mp4
         └─ s01e02.mp4
```

### `http://localhost/media?raw`

```
http://localhost/media/movies/cool-movie.mkv
http://localhost/media/tv/cool-series/s01e01.mp4
http://localhost/media/tv/cool-series/s01e02.mp4
```

### `http://localhost/media?raw&depth=1`

```
http://localhost/media/movies/cool-movie.mkv
```

### `http://localhost/media?aria2`

```
http://localhost/media/movies/cool-movie.mkv
  dir=movies
  out=cool-movie.mkv
http://localhost/media/tv/cool-series/s01e01.mp4
  dir=tv/cool-series
  out=s01e01.mp4
http://localhost/media/tv/cool-series/s01e02.mp4
  dir=tv/cool-series
  out=s01e02.mp4
```
