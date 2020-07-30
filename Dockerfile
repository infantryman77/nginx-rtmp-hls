FROM ubuntu:focal

LABEL maintainer="infantryman77 <fred_d26@hotmail.com>"

# Version of Nginx and rtmp-module

ENV NGINX_VERSION nginx-1.18.0
ENV NGINX_RTMP_MODULE_VERSION 1.2.1

# Install dependencies

RUN apt update && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt install build-essential -y && \
    apt install wget -y && \
    apt install -y ca-certificates openssl libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Download and decompress PCRE

RUN cd usr/local/ && \
    wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz && \
    tar xzvf pcre-8.44.tar.gz
    
# Download and decompress zlib

RUN cd usr/local/ && \
    wget https://www.zlib.net/zlib-1.2.11.tar.gz && \
    tar xzvf zlib-1.2.11.tar.gz

# Download and decompress Nginx

RUN mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxf ${NGINX_VERSION}.tar.gz

# Download and decompress RTMP module

RUN mkdir -p /tmp/build/nginx-rtmp-module && \
    cd /tmp/build/nginx-rtmp-module && \
    wget -O nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    tar -zxf nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    cd nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}

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
        --with-pcre=/usr/local/ \
        --with-zlib=/usr/local/ \
        --add-module=/tmp/build/nginx-rtmp-module/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} && \
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
