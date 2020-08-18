FROM ubuntu:focal

LABEL maintainer="infantryman77 <fred_d26@hotmail.com>"

# Version of Nginx and rtmp-module

ENV NGINX_VERSION nginx-1.18.0

# Install dependencies

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install software-properties-common -y && \
    apt install build-essential git tree -y && \
    apt install wget -y && \
    rm -rf /var/lib/apt/lists/*

# Download and decompress Nginx

RUN mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxf ${NGINX_VERSION}.tar.gz

# Dowload and decompress NGINX dependencies

RUN apt-get install build-essential libpcre3 libpcre3-dev libssl-dev

# Download and decompress RTMP module

RUN mkdir -p /tmp/build && \
    cd /tmp/build && \
    git clone https://github.com/sergey-dryabzhinsky/nginx-rtmp-module.git

# Build and install Nginx

RUN cd /tmp/build/nginx/${NGINX_VERSION} && \
    ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx/nginx.lock \
        --http-log-path=/var/log/nginx/access.log \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --with-pcre=/usr/local \
        --with-zlib=/usr/local \
        --with-openssl=/usr/local \
        --add-module=/tmp/build/nginx-rtmp-module && \
    make -j $(getconf _NPROCESSORS_ONLN) && \
    make install && \
    mkdir /var/lock/nginx && \
    rm -rf /tmp/build

# Forward logs to Docker

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Set up NGINX config file

COPY nginx.conf /etc/nginx/nginx.conf

# RTMP & HLS Ports

EXPOSE 1935 8080

CMD ["nginx", "-g", "daemon off;"]
