FROM ubuntu:focal

LABEL maintainer="infantryman77 <fred_d26@hotmail.com>"

# Version of Nginx and rtmp-module

ENV NGINX_VERSION nginx-1.18.0

# Create Directories

RUN mkdir -p /opt/data && mkdir /www && mkdir -p /data/hls && mkdir -p /data/dash

# Install Dependencies

RUN	apt update && apt install	\
binutils \
binutils-libs \
build-base \
ca-certificates \
gcc \
libc-dev \
libgcc \
make \
musl-dev \
openssl \
openssl-dev \
pcre \
pcre-dev \
pkgconf \
pkgconfig \
zlib-dev -y

# Download and Decompress Nginx

RUN cd /tmp && \
wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
tar zxf nginx-${NGINX_VERSION}.tar.gz && \
rm nginx-${NGINX_VERSION}.tar.gz

# Download and Decompress RTMP module

RUN mkdir -p /tmp && \
    cd /tmp && \
    git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git

# Build and Install Nginx

RUN cd /tmp/nginx/${NGINX_VERSION} && \
    ./configure \
        --prefix=/opt/nginx \
        --conf-path=/opt/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx/nginx.lock \
        --http-log-path=/var/log/nginx/access.log \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --add-module=/tmp/nginx-rtmp-module && \
    make -j $(getconf _NPROCESSORS_ONLN) && \
    make install && \
    mkdir /var/lock/nginx

# Forward Logs to Docker

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Set up NGINX config file

COPY nginx.conf /etc/nginx/nginx.conf

# RTMP & HLS Ports

EXPOSE 1935 8080

CMD ["nginx", "-g", "daemon off;"]
