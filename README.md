# NGINX RTMP HLS

![N|Solid](https://lh3.googleusercontent.com/a-/AOh14GiG6wakatEtel6HqEGa-ajIqQ-o1W5vBKM_d6Wb5A=s88-c-k-c0x00ffffff-no-rj-mo)


NGINX RTMP HLS is a high performance streaming web server. 

  - Uses port 1935 for RTMP
  - Uses port 8080 for HLS

### Technologies

NGINX RTMP HLS uses a number of open source projects to work properly:

* [Nginx](https://www.nginx.com/) - High Performance Web Server
* [Nginx RTMP Module](https://github.com/sergey-dryabzhinsky/nginx-rtmp-module) - RTMP Module maintained by Sergey Dryabzhinsky

And of course NGINX RTMP HLS itself is open source with a [public repository](https://github.com/infantryman77/nginx-rtmp-hls/) on GitHub.

### Example

Here is an example of the nginx.conf file provided with the image.

```sh
worker_processes  auto;
events {
    worker_connections  1024;
}

# RTMP configuration
rtmp {
    server {
        listen 1935; # Listen on standard RTMP port
        chunk_size 4000;

        application show {
            live on;
            # Turn on HLS
            hls on;
            hls_path /mnt/hls/;
            hls_fragment 3;
            hls_playlist_length 60;
            # disable consuming the stream from nginx as rtmp
            deny play all;
        }
    }
}

http {
    sendfile off;
    tcp_nopush on;
    aio on;
    directio 512;
    default_type application/octet-stream;

    server {
        listen 8080;

        location / {
            # Disable cache
            add_header 'Cache-Control' 'no-cache';

            # CORS setup
            add_header 'Access-Control-Allow-Origin' '*' always;
            add_header 'Access-Control-Expose-Headers' 'Content-Length';

            # allow CORS preflight requests
            if ($request_method = 'OPTIONS') {
                add_header 'Access-Control-Allow-Origin' '*';
                add_header 'Access-Control-Max-Age' 1728000;
                add_header 'Content-Type' 'text/plain charset=UTF-8';
                add_header 'Content-Length' 0;
                return 204;
            }

            types {
                application/dash+xml mpd;
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }

            root /mnt/;
        }
    }
}
```

### Docker
NGINX RTMP HLS is very easy to install and deploy in a Docker container.

By default, the Docker will expose port 1935 & 8080. When ready, simply pull the image.

```sh
docker pull infantryman77/nginx-rtmp-hls
```
This will pull in the NGINX RTMP HLS image.

Once done, run the Docker image and map the port to whatever you wish on your host. In this example, we simply map port 1935 of the host to port 1935 of the Docker:

```sh
docker run -p 1935:1935 -p 8080:8080 infantryman77/nginx-rtmp-hls
```

Verify the deployment by using any streaming encoder that support RTMP and point it to your RTMP server address.

```sh
rtmp://example.com/show/stream_name or rtmp://192.168.0.10/show/stream_name
```
Then use VLC to play the stream.

```sh
http://example.com:8080/hls/stream_name.m3u8 or http://192.168.0.10:8080/hls/stream_name.m3u8
```


### Todos

 - Add RTMPS push using stunnel
 - Add MPEG-DASH

License
----

MIT
